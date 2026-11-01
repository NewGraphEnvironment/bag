# Progress — Rename spacehakr to bag (#31)

## Session 2026-10-31

- Plan-mode exploration: three concurrent Explore sweeps (this package's internals,
  every `spacehakr`/`ngr_spk_*` caller across the org's checkouts, and the eleven donor
  functions), plus direct reads of the umbrella and counterpart issues
- One Plan-agent review of the draft breakdown, folded in before the gate. Its load-bearing
  findings were reproduced before being acted on: the ten-package `Imports:` target, the
  `poly.gpkg`/`points.gpkg` split, the two surviving `globalVariables()`, the
  `mockery::stub()` string targets, the consumer-install hazard, and the Pages URL. Its
  donor test count (nine untested) was wrong in the same direction as the plan's — the
  measured number is seven of eleven
- Gate decisions recorded in `task_plan.md`: full scope including the intake; repository
  renamed first; Zenodo DOI kept; version `0.5.0`; the single declaring consumer pinned
  before merge
- Created branch `31-rename-spacehakr-to-bag-fetch-public-dat` off `origin/main` at
  `3efbc37`
- Scaffolded the PWF baseline from issue #31 with the approved phases
- Phases 2 and 3 landed together: the four keepers renamed (files, functions and the four
  dotted internals), the ten uncalled helpers deleted with both STAC articles and three
  fixtures, `Imports:` 14 -> 10, `Suggests:` 12 -> 2, `globalVariables()` 5 -> 2. One
  `document()` run covers both, which is why they are one commit
- `devtools::test()`: FAIL 0 | WARN 0 | SKIP 2 | PASS 88. The two skips are the live-WFS
  integration blocks. Export count, `man/*.Rd` count and the intended four all agree
- Verified rather than assumed: both renamed `mockery::stub()` targets resolve in the
  namespace, so neither falls through to the real function. (The same probe reports the two
  `bcdata::` stub targets as missing — it cannot evaluate a `pkg::fn` string. Probe limit,
  not a miss.) No `spk_` string survives in `R/` or `tests/`
- Next: Phase 1 is with the user (repository rename); Phase 4 waits on it, since every
  identity edit names a URL containing the repo name
