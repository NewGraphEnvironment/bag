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
- Phase 4 split into 4a (the name) and 4b (the URLs), because the two halves are blocked by
  different things. 4a landed: `Package: bag`, a new Title/Description, `bag.Rproj` with its
  `.Rbuildignore` line, the dead `^vignettes/articles$` line dropped, the test harness and
  every `system.file(package = )`, the hexsticker script, `dev/vm_packages.md` and
  `planning/README.md`. Tests still FAIL 0 | PASS 88
- Added a `reference:` section to `_pkgdown.yml`. The review was right that
  `check_pkgdown()` was vacuous without one: it now runs, and aborts on the pre-existing
  disagreement between `_pkgdown.yml`'s `url:` and `DESCRIPTION`'s — which is 4b's work and
  cannot be fixed before the rename
- The `Version:` bump moved from Phase 4 to Phase 7. `r-packages.md` wants it as the final
  commit of the branch; the plan had it in Phase 4 by mistake
- Checked for the rename-helper machinery the user pointed at in ngr. It is real, not junk:
  `ngr_str_replace_in_files()` and `ngr_str_replace_filenames()` do bulk reviewed
  find-and-replace over files and filenames. Two things measured before relying on it, both
  filed as ngr#46: `paste0()` strips `stringr::fixed()`'s class, so `text_current` is
  matched as a **regex** despite the `fixed()` call; and `ask = TRUE` with a `readline()`
  prompt means that under `Rscript` both functions skip every replacement and report
  "Operation canceled". Used the same approach inline instead, so each step is visible
- Next: Phase 1 is with the user; 4b waits on it. Working Phases 5 and 6 (the intake), which
  depend on neither
