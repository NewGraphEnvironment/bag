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
- Phase 5, first three of seven: the catalogue family ported, reprefixed per the gate's
  "keep the donor stems" answer. Pipes converted to `|>` (the repo's convention; the donors
  mixed `%>%` and `|>`), every import declared, and the four catalogue functions grouped
  under a new `metadata` family with `_pkgdown.yml` extended to match
- Three defects fixed on the way in, each with a mutation test proving the guard fires:
  the catalogue reader's undeclared `cli::` (predicted by the donor issue); the
  column-comments companion comparing the caller's `column` as given against a lower-cased
  `col_name`, so an upper-case argument silently matched nothing; and its calling
  `bcdc_describe_feature()` twice per invocation, once inside a `tryCatch` whose value was
  discarded
- **A fourth defect neither issue predicted**, found by a fixture rather than by reading:
  `bag_meta_bcd_xref()` joined on `package_name`, which is not a key. A package publishing
  N WMS resources gave N^2 rows, and N^2-N paired one resource's object name with another's
  dataset id. 6 rows where 4 are correct. Reported to the internal package; it still ships it
- Mutation-checked in a `tar`-ed copy rather than by editing and restoring the live tree:
  restoring the one-key join turns 5 tests red, dropping the column lower-casing turns 2
  red, re-adding the second service call turns 1 red
- `devtools::test()`: FAIL 0 | WARN 0 | SKIP 2 | PASS 148, up from 88
- `pkgdown::check_pkgdown()` verified clean in a copy with the two URLs made consistent, so
  the reference index covers every topic and 4b's URL fix is all that stands between the
  branch and a clean check
- Also filed ngr#46 for the `stringr::fixed()` defect in the rename machinery
- Phase 5 complete: the GPX reader, the GeoJSON converter, the layer remover and the
  field-file backup ported, with tests for all three that had none
- Four more defects found while porting these, none predicted by either issue. The GPX
  reader passed `pattern` and `full.names` to `fs::dir_ls()`, which takes neither, so they
  were absorbed silently and **every file** in the track directories was read as GPX
  (measured: four files in a directory, four read). Its waypoint listing used an unanchored
  `".gpx"` regex that also matched `weird_gpx.csv`. It compared a POSIXct column against
  bare date strings, so the filter boundary sat 8 hours apart on a Pacific machine and a
  UTC one. And the layer remover read `system2(stdout = TRUE)`, which only **warns** on a
  non-zero exit, then overwrote the original GeoPackage regardless — a failed layer copy
  silently produced a file missing layers nobody asked to remove
- The GPX reader's personal defaults are gone: a `~/Library/CloudStorage/OneDrive-Personal`
  path, `layer_output_name = "2024_ai"` and `gpkg_name = "gps_2024"`. Checked first that
  removing them breaks nobody — all three consumer call sites pass every argument by name.
  A personal directory layout also has no place in a public package's defaults
- Two bugs of my own, both caught by the tests rather than by reading: a cli pluralisation
  marker placed before its quantity, which fails with "Multiple quantities for
  pluralization" and **replaces the whole message**, hiding which layers were missing; and
  `st_layers()` on a temp file a stub never created, which aborts with GDAL's "Open failed"
  before reaching the completeness check
- Five mutation checks, all red: the timezone fix (4 tests), the two file filters (1 each),
  the temp-file guard (1), the ogr2ogr status check (1). The first run of two of these came
  back **green** — the `perl` escaping never matched the file, so nothing was mutated. Only
  asserting the substitution applied before running caught it. Re-run with python: both red
- One test was also rewritten because it could not reach its failure: the timezone fixture
  sat months from the boundary, where an 8-hour shift is invisible. It now sits at 04:00 UTC
  on the boundary day, inside the offset, and runs under `TZ=America/Vancouver`
- `devtools::test()`: FAIL 0 | WARN 0 | SKIP 2 | PASS 218, up from 148. Eleven exports
- Phase 6 complete: fpr's four ported. 15 exports now -- the 4 keepers, 7 from the internal
  package, 4 from fpr
- The inverted geometry guard, mechanism established rather than assumed. In R `!` binds
  *looser* than `!=`, so `!x != y` is `!(x != y)`, i.e. `x == y` -- not `(!x) != y`, which
  would have errored on a character. The guard read "abort when the class IS `sfc_point`"
  and sf sets `sfc_POINT`, so it was false for every input and **never fired, on a point
  layer or a polygon one**. Removing the `!` would have aborted on every valid point layer:
  the opposite failure. Settled by probing `!x != y` with `x = y = "a"`, which returns TRUE
  rather than erroring, and by `?Syntax`. Factored into one `bag_chk_sf_point()`
- A second dependency consequence, which the plan had not predicted:
  `fpr_sp_gpkg_backup()` calls `fpr_tidy_assign_site_id()` when `update_site_id = TRUE`,
  live at two call sites. That function is about site identity, pulls in another fpr
  function, and five reporting repos call it directly, so it belongs in fpr. Taken to the
  user as a boundary decision; answer was to inject it as `fn_site_id`, so neither package
  imports the other and all ~20 call sites keep working
- `magrittr` added deliberately, confined to the four ported functions: their pipelines use
  the `.` placeholder inside `mutate()`, which `|>` has no equivalent for, and their row
  order and CRS round trip are what ~20 callers write back to disk. The gate asked for a
  minimal-change port, so the import is the lower-risk choice over a rewrite
- Four mutation checks red: the guard (5 tests), the RData directory creation (2), the
  callback result check (1). A fifth stayed **green with the substitution verified** -- a
  missing-column guard I had added duplicated tibble's own reporting, which already names
  every missing column. No mutation could distinguish them, so the guard was removed rather
  than left as untestable defensive code
- `devtools::test()`: FAIL 0 | WARN 0 | SKIP 2 | PASS 308, up from 218
- Phase 7's unblocked half done. `R CMD check(vignettes = FALSE)`: **0 errors, 0 warnings,
  0 notes**, after fixing two it found — `.lintr` and `.claude` were shipping in the tarball,
  and `.` and `:=` were undefined globals from the magrittr pipelines
- Added the `.lintr` config the repo never had; without one lintr ran 80-char defaults and
  buried the real lints in noise. Took `r-packages.md`'s recommended config, which needed
  two corrections: its `"renv" = list(linters = "all")` form is rejected outright by lintr
  3.3.0.1, and the magrittr files are excluded per-linter rather than disabling
  `pipe_consistency_linter` package-wide. `lintr::lint_package()` is now 0 lints
- The stale-install trap bit exactly as the convention describes: lintr reported `no visible
  binding` for names already in `globalVariables()`, because it resolves against the
  installed package — which was `spacehakr 0.4.0`, and `bag` not at all. Reinstalling
  cleared them without a code change
- Tarball verified: 66 entries, no `.Rproj`, `planning/` or `CLAUDE.md`. The first attempt at
  that check **passed while doing nothing** — `ls` is colourised here, so the captured path
  carried ANSI codes, `tar` failed, and the `||` arm printed "none leaked". A guard failing
  toward pass, caught only by asserting the entry count was non-zero
- One more of my own caught by the suite: shortening a cli warning for line length dropped
  the literal argument name a test matched on. The message now names both the argument and
  its value, and the assertion checks both, so neither can drift out silently
- `devtools::test()`: FAIL 0 | WARN 0 | SKIP 2 | PASS 310. `lintr`: 0. `check`: 0/0/0
- Next: everything remaining is blocked on Phase 1, which is with the user. 4b needs the new
  URL; 7's release needs 4b; 8 needs the merge

## Session 2026-11-01 (UTC) — naming locked, the layer remover dropped, donor defects reported

- The owner read the intake's names side by side and pushed back on two things I had
  decided myself. Both pushbacks were right and both changed the branch
- **magrittr comes out.** Measured across 88 repos: no newer package of ours declares it
  or uses `%>%` in `R/` at all — 0 of 68 R files in one, 0 of 46, 0 of 49, 0 of 18, 0 of
  17, 0 of 11. Five older packages declare it, and they are the donors this code came
  from, so adding it here would have made this the only new-generation package carrying
  it. First filed as a separate issue, then folded into this branch on the owner's call,
  because Phase 9's rename opens the same four files
- The port is smaller than I had judged when I took the dependency: only **two** of the
  four donated files use the `.` placeholder, and both call `sf::st_coordinates()` twice
  on the same geometry. One of the other two uses a purrr `.x`, not magrittr's `.`, and
  the fourth is a plain chain. What made me reverse the call is that the tests now exist:
  when I chose magrittr they did not, so "a rewrite is where a regression comes from" was
  true then and is not now
- **Names finalised (Phase 9).** Three forks went to the owner, all three took the
  recommendation. The principle: drop prefixes that are organisational (`sp_`, `u_`,
  `fs_`, `meta_`), keep words that are contractual (`assign`, `import`, `to_geojson`,
  `refresh`). Twice I shortened a name and lost contract information — `bag_utm` beside
  `bag_utm_to_sf` reads as either direction, and `bag_geojson` dropped a conversion that
  is real — and reverted both
- Measured why the coordinate pair must not be named as a direction pair: they are not
  inverses. `assign_utm` takes sf and returns the input CRS; `sf_from_utm` takes a plain
  data frame and returns `crs_return`, default 3005, renaming the geometry column to
  `geom`. 4326 in, 4326 out of the first, 3005 out of the second
- **The layer remover is gone (Phase 10).** Badged `superseded` by its donor in favour of
  `gdalraster::ogr_layer_delete()`, with **zero live callers** org-wide: 11 code-search
  hits, the only one in consumer code a commented-out line. `gdalraster` is already live
  in three of our GIS scripts and installed at 2.6.1. 15 exports to 14, `lifecycle` out of
  Suggests, tests 310 to 292
- **The donor defects are reported.** Nine were found while porting and only one had been
  filed; the rest sat here in `progress.md` and the owed list never asked for them. Each
  was verified still present in the donor's current tree before filing, which corrected
  one of my own claims: the never-firing geometry guard is in **three** of the
  fish-passage helpers, not four — the fourth takes a plain data frame and correctly has
  none. Three issues with the internal package, two with `fpr`
- **Closed a test gap found on the way.** Every column assertion on the three coordinate
  functions was `%in% names()` — set membership, blind to a reordering, on functions whose
  columns callers write to disk, and which the magrittr rewrite touches. Measured the
  order first and found the three are **inconsistent with each other**: two place their
  columns before the geometry column because they end on `dplyr::select()` calls, the
  third places its after because it has none. Pinned as they are, not reconciled
- A mutation check on those assertions came back **green** and was not trusted: swapping
  `mutate()` for `[[<-` changes nothing, because the trailing `select()` normalises
  geometry to last either way. A semantic no-op, not a weak test. Two `relocate()` edits
  took 4 tests red
- Removed a private-repo issue reference I had written into this file. This repo is public
  and `planning/` is committed, so it pointed nowhere for an outside reader
- Commits: `5415bba` (names, drop and magrittr decisions), `533bd4b` (the drop),
  `7cadb5f` (column order). `devtools::test()`: FAIL 0 | WARN 0 | SKIP 2 | PASS 298.
  `lintr`: 0
- Next: Phase 9's rename with the magrittr removal folded in, then `/code-check branch`.
  Phase 1 — the repository rename — is still with the owner, and 4b, 7 and 8 remain
  blocked on it
