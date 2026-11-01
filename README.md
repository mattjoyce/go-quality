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

Exit code 0 means merge-grade. Anything else means not done. The summary gives each
step's time.

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

## When the gate is slow

Measure before buying cores. `go test ./...` already runs packages in parallel, one per
core, but a package's own tests run one after another unless they call `t.Parallel()`.
So the gate's floor is its slowest package, not its total.

```bash
~/Projects/go-quality/slow-tests.sh [module-dir] [packages...]
```

prints each package's wall time beside the sum of its tests' times, then the slowest
tests. A package whose sum is near its wall time is running serially. What fixed
anam's gate (anam card 262: 478 s to 58 s on 16 cores, about 600 s to 194 s on a laptop):

- **Tests call `t.Parallel()`** unless they change process state: the default `slog`
  logger, the environment, the working directory. Say why on one that doesn't. Go runs a
  package's serial tests before any parallel one resumes, so a serial test that swaps the
  logger logs alone. Each test needs its own temp directory, files and `:0` listener.
- **Build immutable fixtures once per process.** anam's tests re-parsed an embedded
  catalog and recompiled its JSON schemas in every test, two thirds of each test's time.
  A value that cannot change while the process runs can be built once (`sync.OnceValues`)
  and shared, as long as nothing modifies what it returns.
- **Time each tool, not just the tests.** Standalone gosec v2.24.0 spent four minutes of
  a five-minute gate on one rule (G120) in one package; v2.30.0 runs the same repo in two
  seconds. The gosec bundled in golangci-lint 2.10.1 (v2.23.0) is not affected.

## Toolchain traps

- A Go newer than the lint tools can read fails them with export-data errors (Go 1.27
  against golangci-lint 2.10.1). Pin the toolchain the tools were built for, e.g.
  `GOTOOLCHAIN=go1.26.0`, and rebuild the tools under it.
- `go 1.26` in a `go.mod` names a language version, not a release. With
  `GOTOOLCHAIN=auto` and an older local Go, it asks for a toolchain called `go1.26`, which
  does not exist. Write `go 1.26.0`. The fixtures here do.
- For a build host reached over ssh, put PATH and `GOTOOLCHAIN` above `~/.bashrc`'s
  interactive-return guard, since `ssh host cmd` never reads `~/.profile`.

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
prefer real components over mocks, define interfaces at the point of use, call
`t.Parallel()` unless a test changes process state.
