#!/usr/bin/env bash
# go-quality gate — the checks an agent must pass before declaring Go work done.
#
# Usage: check.sh [module-dir]            (default: current directory)
# Env:   GOQUALITY_CONFIG=<path>          override the bundled .golangci.yml
#        BUMBLEBEE_CATALOG=<path>         enable the supply-chain exposure step
#        SKIP_VULNCHECK=1                 skip govulncheck (offline runs)
#
# Runs every step, reports all failures, exits non-zero if any step failed.

set -u

MOD="$(cd "${1:-.}" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${GOQUALITY_CONFIG:-$SCRIPT_DIR/.golangci.yml}"
PATH="$PATH:$(go env GOPATH)/bin"

declare -a RESULTS=()
FAILED=0

# Each step's time goes in the summary, so a slow gate says which step to fix.
run_step() {
  local name="$1"; shift
  local start=$SECONDS
  echo ""
  echo "── ${name} ──────────────────────────────"
  if "$@"; then
    RESULTS+=("PASS  ${name} ($((SECONDS - start))s)")
  else
    RESULTS+=("FAIL  ${name} ($((SECONDS - start))s)")
    FAILED=1
  fi
}

step_fmt() {
  # goimports applies gofmt rules plus import hygiene in one tree walk;
  # fall back to gofmt where goimports isn't installed.
  # testdata/ inside the module is skipped, per Go tooling convention.
  local tool="gofmt" bad
  command -v goimports >/dev/null 2>&1 && tool="goimports"
  bad="$(cd "$MOD" && "$tool" -l . | grep -v '^\(\./\)\?testdata/' || true)"
  if [ -n "$bad" ]; then
    echo "$tool violations:"; echo "$bad"; return 1
  fi
  echo "formatting clean ($tool)"
}

step_vet() { (cd "$MOD" && go vet ./...); }

step_lint() { (cd "$MOD" && golangci-lint run --config "$CONFIG" ./...); }

step_vuln() {
  if [ "${SKIP_VULNCHECK:-0}" = "1" ]; then
    echo "skipped (SKIP_VULNCHECK=1)"; return 0
  fi
  if ! command -v govulncheck >/dev/null 2>&1; then
    echo "govulncheck not installed: go install golang.org/x/vuln/cmd/govulncheck@latest"
    return 1
  fi
  (cd "$MOD" && govulncheck ./...)
}

step_supplychain() {
  if ! command -v bumblebee >/dev/null 2>&1; then
    echo "skipped (bumblebee not on PATH)"; return 0
  fi
  if [ -z "${BUMBLEBEE_CATALOG:-}" ]; then
    echo "skipped (BUMBLEBEE_CATALOG not set)"; return 0
  fi
  local out findings
  out="$(bumblebee scan --profile project --root "$MOD" --ecosystem go \
    --exposure-catalog "$BUMBLEBEE_CATALOG" --findings-only 2>&1)" || {
    echo "$out"; return 1
  }
  findings="$(printf '%s\n' "$out" | grep -c '"record_type":"finding"' || true)"
  if [ "${findings:-0}" -gt 0 ]; then
    echo "$out" | grep '"record_type":"finding"'
    echo "supply-chain findings: $findings"
    return 1
  fi
  echo "no supply-chain findings"
}

step_test() { (cd "$MOD" && go test -race -count=1 -shuffle=on ./...); }

echo "go-quality gate: $MOD"
echo "config: $CONFIG"

run_step "format (gofmt/goimports)" step_fmt
run_step "go vet"                    step_vet
run_step "golangci-lint"             step_lint
run_step "govulncheck"               step_vuln
run_step "supply-chain (bumblebee)"  step_supplychain
run_step "go test -race -shuffle"    step_test

echo ""
echo "═══ gate summary ═══════════════════════"
printf '%s\n' "${RESULTS[@]}"
if [ "$FAILED" -ne 0 ]; then
  echo "RESULT: FAIL — do not merge / do not declare done"
  exit 1
fi
echo "RESULT: PASS"
