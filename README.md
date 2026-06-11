# go-quality

The Go quality gate coding agents must pass before declaring work done.
One canonical config, one runner, consumed locally and in CI — so the
gate can't drift between prose standards, scripts, and workflows.

The gate runs, in order (cheap → expensive, all steps reported):

1. `gofmt` / `goimports` — formatting diff check
2. `go vet` — type-aware correctness
3. `golangci-lint` — with the bundled [.golangci.yml](.golangci.yml)
   (errorlint, funlen 60, revive exported docs, forbidigo `log.Fatal`/`panic`/`fmt.Print*`,
   gosec, nolintlint, interfacebloat, gocritic)
4. `govulncheck` — known CVEs, reachability-aware (`SKIP_VULNCHECK=1` when offline)
5. `bumblebee` — supply-chain exposure scan (runs only when `BUMBLEBEE_CATALOG` is set)
6. `go test -race -count=1 -shuffle=on` — behaviour + data races

Exit code 0 means merge-grade. Anything else means not done.

## Local use (agents run this)

```bash
~/Projects/go-quality/check.sh           # gate the current directory
~/Projects/go-quality/check.sh path/to/module
```

## CI use (humans enforce this)

```yaml
jobs:
  quality:
    uses: mattjoyce/go-quality/.github/workflows/go-check.yml@v1
```

Mark the `gate` job as a required status check in branch protection;
the gate then becomes structural, not advisory.

## Fixtures

`testdata/dirty` is a module seeded with one violation per rule and must
FAIL the gate. `testdata/clean` must PASS. Together they regression-test
the gate itself:

```bash
./check.sh testdata/dirty   # expect RESULT: FAIL
./check.sh testdata/clean   # expect RESULT: PASS
```

## What stays prose

Rules no tool can check remain agent instructions, not gate steps:
don't log-and-return the same error, mutexes XOR channels per datum,
prefer real components over mocks, define interfaces at the point of use.
