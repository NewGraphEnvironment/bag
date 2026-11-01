# Task: Rename spacehakr to bag: fetch public data and field files, and drop the helpers nothing calls (#31)

## Problem

Of spacehakr's 14 exports, two have callers: `spk_source_url()` and `spk_source_bcdata()`,
which download a layer from a URL or the BC Data Catalogue into a GeoPackage. The rest are
drone-imagery and raster helpers (`spk_odm`, `spk_gdalwarp`, the `spk_rast_*` set,
`spk_res`, `spk_stac_calc`, `spk_join`, `spk_poly_to_points`, `spk_q_layer_info`) with no
direct callers. Seven related functions, also fetchers and spatial file helpers, sit in an
internal package, and published reporting pipelines call them.

**Outcome:** a public package with one subject — fetching public data and field files to
disk — imports that follow that subject, and published reports sourcing their inputs from
it instead of from an internal package.

The other members of the effort, and the rules behind it, are tracked under the
`track:package-boundaries` label.

## Decided at the gate

Both answered by the user, 2026-10-31:

- **Scope: everything, including the intake.** All six of the issue's items in this branch
  — rename, prune, *and* taking in the seven donor functions from the internal package and
  `fpr`'s four field-file/coordinate helpers. The forwarders those two repos keep are
  separate PRs in those repos (Phase 8); the counterpart issue in the internal package
  already tracks its half.
- **The repository is renamed early, by Claude, confirmed on the call.** It goes first,
  before any file naming a URL. Deciding: every published URL contains the repo name, so
  writing the new ones first would point `DESCRIPTION`, `CITATION.cff`, `_pkgdown.yml`,
  `CLAUDE.md` and two README badges at a 404, while renaming first costs nothing because
  GitHub redirects the old path.

Taken as conventional defaults, stated rather than asked:

- **Keep the Zenodo concept DOI** `10.5281/zenodo.23524742`. It resolves to a live record
  titled for spacehakr; Zenodo's GitHub integration keys on the repository rather than its
  name, so `bag 0.5.0` becomes a new version of the same record.
- **Canonical URL is `https://www.newgraphenvironment.com/bag/`**, in `_pkgdown.yml` and
  `DESCRIPTION` both. Measured: the Pages API reports that host as this repo's `html_url`
  with `cname: null` (an org-verified domain), and the `.github.io` form 302s to it. Either
  resolves; this one is what GitHub actually serves.
- **Version `0.5.0`.** The rename breaks every caller and is recorded in `NEWS.md` as
  breaking, but the package stays pre-1.0 while the boundaries effort is still moving
  functions; `1.0.0` would claim a stability it has not reached.
- **The one consumer that declares the dependency is pinned to `@v0.4.2` before this
  merges**, and unpinned when its switch PR lands (Phase 8). `CLAUDE.md`'s "pin everywhere
  or nowhere" rule permits it: it is now the *only* consumer with such an entry, so the
  two-consumers-at-two-tags failure it guards against cannot arise.

## Measured before planning

- **`v0.4.2` already is the pre-deletion tag.** `git diff v0.4.2..HEAD` over `R/`,
  `tests/`, `man/`, `NAMESPACE`, `DESCRIPTION` and `inst/` is empty — the only commits
  since are a `CITATION.cff` bot commit and a `CLAUDE.md` sync. Effort rule 4 ("a tag
  before deleting makes it easy to find") is satisfied by an existing tag, so **no new tag
  is cut**, and `NewGraphEnvironment/spacehakr@v0.4.2` stays installable through the
  GitHub redirect.
- `bag` is free: not in CRAN's 25,636-name index (controls `sf` and `terra` both found),
  and `gh api repos/NewGraphEnvironment/bag` is 404.
- **Three repositories call `spacehakr::` in live code** — one public
  (`restoration_wedzin_kwa_2024`, one call site) and two internal — and between them they
  call only the two functions the issue names. One declares the dependency.
- **The twelve helpers have no `spk_*` caller, but ten are live under their pre-extraction
  `ngr_spk_*` names.** `ngr` exports twelve *independent copies* and does **not** depend on
  spacehakr (`ngr/DESCRIPTION` has no such line, in `Imports` or `Remotes`), so deleting
  spacehakr's copies strands nobody. Three public repos call ngr's copies live:
  `restoration_wedzin_kwa_2024` (five functions), `stac_uav_bc` (`ngr_spk_odm`, three call
  sites) and `fish_passage_peace_2024_reporting` (`ngr_spk_join`).

  Two consequences. It **settles the umbrella issue's open conditional** — ODM moves to the
  drone catalogue's tooling "if it still runs drone jobs": it does. And it **justifies
  keeping `spk_geoserv_dlv()` and `spk_layer_info()`**, which look dead here and are in
  live use under their ngr names.
- **Two stale claims in this repo's own `CLAUDE.md`**, both measured false: it says
  unpinned `Remotes:` entries for this package exist in two named consumers, and one of
  them has no such entry at all; and `httr` is listed as a key dependency while being used
  nowhere.
- **Of the eleven donor functions, seven have no test file** — four of the internal
  package's seven, and three of `fpr`'s four. Verified by listing both
  `tests/testthat/` directories, not from the issues' counts.

## Phase 1 — Rename the repository

- [ ] `gh repo rename bag --repo NewGraphEnvironment/spacehakr` — confirm on the call first
- [ ] `git remote set-url origin`; push the branch and confirm the ref landed
- [ ] Confirm `https://www.newgraphenvironment.com/bag/` serves once pkgdown next deploys,
      and note that the **old Pages path goes dark** — GitHub redirects repository URLs but
      not Pages paths, and `NEWS.md`, `CITATION.cff` and an internal ecosystem registry all
      point into the old site

## Phase 2 — Rename the four keepers

| now | file now | becomes | file becomes |
|---|---|---|---|
| `spk_source_url()` | `R/spk_source_url.R` | `bag_url()` | `R/bag_url.R` |
| `spk_source_bcdata()` | `R/spk_source_bcdata.R` | `bag_bcdata()` | `R/bag_bcdata.R` |
| `spk_geoserv_dlv()` | `R/spk_geoserv_dlv.R` | `bag_wfs()` | `R/bag_wfs.R` |
| `spk_layer_info()` | `R/spk_layer_info.R` | `bag_layer_info()` | `R/bag_layer_info.R` |

Two of these are not substitutions — `source_url` → `url` drops a word and `geoserv_dlv` →
`wfs` is a new name — so the filenames are named above rather than derived.

- [x] `git mv` each `R/` file and its `tests/testthat/test-*.R` to match
- [x] Rename the internal helpers in `R/bag_url.R`: `.spk_ogr2ogr()`,
      `.spk_source_resolve()`, `.spk_reencode()`, `.spk_source_url_args()` → `.bag_*`.
      Leave `stderr_tail()` undotted — the comment there records that cli glue needs it so
- [x] **The `mockery::stub()` targets are character strings**, at
      `test-spk_source_url.R:395, 396, 422, 428, 457, 458, 498` and two more below. `stub()`
      does not check that the named binding exists, so a missed string is a silent no-op
      that falls through to the **real** function — and in the block at `:382` that means a
      live `httr2` request in a suite whose own comment says no test touches the network,
      plus a real `ogr2ogr` shell-out. After renaming, assert no `\.spk_` string survives
      in `tests/`, and that each stub target resolves in the namespace
- [x] Re-point `@family`, `@seealso` and cross-references between the four. Includes
      `R/spk_source_url.R:357`, an `@noRd` block referencing `[spk_gdalwarp()]` — invisible
      to `check` because `@noRd` generates no Rd, and a keeper→deleted reference
- [x] Decide the `@family` tags: after the prune only `download`, `vector` and `geoserver`
      survive, the last two as single-member families. Collapse to one `download` family,
      or re-cut them once the intake lands in Phases 5–6
- [x] `devtools::document()`; delete the orphaned `man/spk_*.Rd`

## Phase 3 — Delete the ten helpers, and the imports they carried

Safe because `ngr` holds independent copies and no consumer reaches these through this
package — verified above, not assumed.

- [x] Delete `R/`, `tests/testthat/` and `man/` for: `spk_odm`, `spk_gdalwarp`,
      `spk_rast_ext`, `spk_rast_not_empty`, `spk_rast_rm_empty`, `spk_res`,
      `spk_stac_calc`, `spk_join`, `spk_poly_to_points`, `spk_q_layer_info`
- [x] Delete both `vignettes/articles/*.Rmd` — **each documents only
      `spk_stac_calc()`**, the sole package function either mentions
- [x] Delete `inst/extdata/test1.tif`, `test2.tif` and `points.gpkg`. **Keep
      `poly.gpkg`** — read by a keeper's test at `test-spk_layer_info.R:5, 18, 99`;
      `points.gpkg` is read only by the deleted join test and by `README.Rmd:74`
- [x] `Imports:` 14 → **10**: `bcdata, chk, cli, dplyr, fs, glue, httr2, purrr, sf,
      stringr`. Dropping `terra`, `rlang` (only `@importFrom rlang .data` in the deleted
      join), `tibble` and `xml2` (both only in the deleted QGIS reader)
- [x] `Suggests:` keep only `mockery` and `testthat`. Drop `stars` (referenced nowhere in
      the repo), `rstac`, `leaflet`, `leafem`, `mapview`, `grDevices`, `kableExtra`
      (the STAC articles'), `processx` (the deleted tests'), and **`knitr` and `rmarkdown`**
      — reachable now only from `README.Rmd`, which is `.Rbuildignore`d, with no
      `VignetteBuilder` set
- [x] `R/utils.R`: keep `driver` and `name` in `globalVariables()` — used at
      `bag_layer_info.R:38` and `:53`. Drop `.data`, `layer_name`, `time_exported`, and the
      dead `@importFrom stats setNames` (its only users were two deleted files)
- [x] Leave `tools`, `utils` and `stats` as they are: they appear in `NAMESPACE`
      `importFrom()` without being in `DESCRIPTION Imports:` today, CI is green, and the
      prune does not change that

## Phase 4a — Package identity: the name

Split from 4b because the two halves are blocked by different things. Everything here is
independent of the repository rename; everything in 4b needs it.

- [x] `DESCRIPTION`: `Package: bag`, and a `Title`/`Description` about fetching public data
      and field files to disk, with the "Extracted from the ngr package" sentence gone
- [x] `git mv spacehakr.Rproj bag.Rproj` **with** `.Rbuildignore`'s `^spacehakr\.Rproj$` in
      the same commit — out of step, the `.Rproj` ships in the tarball. Also dropped
      `^vignettes/articles$`, dead since Phase 3 deleted the directory
- [x] `_pkgdown.yml`: **added a `reference:` section**. It had none, so the index was
      auto-generated and `pkgdown::check_pkgdown()` had nothing to check. It now runs —
      and immediately aborts on the URL mismatch, which is 4b's work
- [x] `tests/testthat.R` (`library()` and `test_check()`) and every
      `system.file(package = )` call in the keepers' tests
- [x] `data-raw/make_hexsticker.R` `package_name`; `dev/vm_packages.md`;
      `planning/README.md`
- [ ] Regenerate `man/figures/logo*.png` from the edited hexsticker script

**Moved to Phase 7:** the `Version:` bump. `r-packages.md` puts it as the *final* commit of
the branch, "after verification numbers/tests are final" — a mid-branch bump is churn, and
the plan had it here by mistake.

## Phase 4b — Package identity: the URLs (blocked on Phase 1)

Every item names a path containing the repository name, so none can be written until the
rename lands. Target: `https://www.newgraphenvironment.com/bag/`.

- [ ] `DESCRIPTION` `URL:` and `BugReports:`
- [ ] `_pkgdown.yml` `url:` — must agree with `DESCRIPTION`, or `check_pkgdown()` aborts
- [ ] `CITATION.cff` via `/citation-cff` — eight hits, and its workflow fires only on a
      push to `main` touching `DESCRIPTION`, so on this branch it stays stale
- [ ] `README.Rmd` → re-knit. Larger than a find-and-replace: the two functions the package
      exists for appear **nowhere** in it today, including in its function table, so this is
      writing their first examples with real output. Also the two CI badge URLs at `:20`,
      the logo `alt` text at `:16`, the install line and the `library()` calls
- [ ] `NEWS.md`: a `# bag <version>` heading recording the rename, the new names, the
      deletion with its `v0.4.2` tag, and the intake. Leave the `# spacehakr <v>` history.
      Written with the version, so it lands with Phase 7
- [ ] `CLAUDE.md` above the marker: Repository/URL lines, the migration table, the naming
      section, the `@family` list, the `Key Dependencies` list (drop `httr`), the file-name
      and `gh issue create` examples, and the stale `Remotes:` section. Name no internal repo

## Phase 5 — Take in the internal package's seven

Copied in, renamed to `bag_*`, documented and tested here. The deprecating forwarders stay
that package's job (Phase 8). Its unexported xref helper travels with the xref pair.

Reprefix only, per the gate: the donor stems are kept and only the prefix changes.

- [x] `bag_meta_bcd_xref()` — the catalogue cross-reference, with its internal
      `bag_meta_bcd_xref_pkg_schtab()` helper
- [x] `bag_meta_bcd_xref_col_comments()` — the column-comments companion
- [x] `bag_bcd_get_data()` — the catalogue reader
- [x] `bag_gpx_import()` — the GPX reader
- [x] `bag_gpkg_to_geojson()` — the GeoPackage-to-GeoJSON converter
- [x] `bag_u_rm_gpkg_layers()` — the GeoPackage layer remover
- [x] `bag_fs_backup()` — the field-file backup
- [x] Tests for the column-comments companion (the first of the four with none)
- [x] Tests for the GPX reader, the GeoJSON converter and the layer remover
- [x] Fixed in the catalogue reader: it called `cli::` with no `@importFrom cli`
- [x] Fix the GeoJSON converter's unused `@importFrom dplyr` and undeclared `chk::`
- [x] **A third defect, found by the new tests and not predicted by either issue:**
      `bag_meta_bcd_xref()` joined `bcdata_lookup_raw` to `object_names` on `package_name`
      alone, which is not a key — a package publishing N WMS resources gave N^2 rows, and
      N^2-N of them paired one resource's object name with another's dataset id and
      download URL. Measured 6 rows where 4 are correct. Now joined on the row index too.
      Reported to the donor, which still ships it
- [x] Decided: ported, badge kept, defects fixed. The gate chose the full intake, so
      retiring one of the seven unilaterally was not mine to do; and reading it turned up a
      **data-loss defect** that made porting it unchanged unacceptable — see below. A
      `gdalraster` rewrite is a separate issue, not this one
- [x] Imports stated, not inherited: `janitor`, `lubridate`, and `rlang` and `tibble`
      back after Phase 3 dropped them. `Suggests` gains `lifecycle` (the superseded badge)
      and `withr` (the timezone test)
- [x] **Four more defects found while porting, none predicted by either issue:**
      the GPX reader passed `pattern` and `full.names` to `fs::dir_ls()`, which takes
      neither, so they were absorbed silently and **every file** in the track directories
      was read as GPX; its waypoint listing used an unanchored `".gpx"` regex that also
      matched `weird_gpx.csv`; it compared a POSIXct time column against bare strings, so
      the filter boundary moved 8 hours between a Pacific machine and a UTC one; and the
      layer remover read `system2(stdout = TRUE)`, which only **warns** on a non-zero exit,
      then overwrote the original GeoPackage regardless — a failed layer copy silently
      produced a file missing layers nobody asked to remove

## Phase 6 — Take in `fpr`'s four

- [x] Ported `fpr_sp_gpkg_backup()` -> `bag_sp_gpkg_backup()` and the three coordinate
      helpers -> `bag_sp_assign_utm()`, `bag_sp_assign_sf_from_utm()`,
      `bag_sp_assign_latlong()`
- [x] Tests for the three that had none, plus a round-trip property test: build points,
      read their UTM columns, rebuild from those columns, land on the same ground. Either
      function alone could be self-consistently wrong; together they cannot
- [x] **The inverted guard, mechanism established rather than assumed.** In R `!` binds
      *looser* than `!=` (`?Syntax`), so `!x != y` is `!(x != y)` — i.e. `x == y` — not
      `(!x) != y`, which would have errored. The guard therefore read "abort when the class
      IS `sfc_point`", and sf sets `sfc_POINT`, so it was false for **every** input and
      never fired, on a point layer or a polygon one. Removing the `!` would have aborted on
      every valid point layer instead, the opposite failure. Replaced with `inherits()`,
      factored into one internal `bag_chk_sf_point()`, and restoring the donor's version
      turns 5 tests red
- [x] **The dependency consequence the plan predicted, plus one it did not.** Predicted:
      `fpr_make_geopackage()` stays in `fpr` and calls the UTM helper, so `fpr` takes `bag`
      as an Import. Unpredicted: `fpr_sp_gpkg_backup()` calls `fpr_tidy_assign_site_id()`
      when `update_site_id = TRUE`, which is live at two call sites — and that function is
      about site identity, pulls in `fpr_chk_dupes()`, and is called directly by five
      reporting repos, so it belongs in `fpr`. **Gate decision (user, 2026-10-31):** inject
      it. `bag_sp_gpkg_backup()` takes `fn_site_id = NULL`; `fpr`'s forwarder passes its own
      function, so all ~20 call sites keep working and neither package imports the other
- [x] `readr` added for the csv backup. `waldo` not needed — it appears only in the donor's
      commented-out example
- [x] **`magrittr` added, deliberately.** The donors' pipelines use the `.` placeholder
      inside `dplyr::mutate()`, which the native pipe has no equivalent for, and their row
      ordering and CRS round trip are relied on by files ~20 call sites write back. The gate
      asked for a minimal-change port; rewriting the pipelines is where a regression would
      come from. `magrittr` has no dependencies of its own. This is a stated deviation from
      the `|>` convention, confined to the four ported functions
- [x] **One guard of mine removed after a mutation test.** A missing-coordinate-column
      check in `bag_sp_assign_sf_from_utm()` turned out to duplicate tibble's own reporting,
      which already names every missing column; no mutation could distinguish them, so it
      went rather than stay as untestable defensive code

## Phase 7 — Verify and release

- [x] `devtools::test()` green and `lintr::lint_package()` clean — **after reinstalling**.
      The convention's trap landed exactly as written: lintr resolved against the installed
      package, which was `spacehakr 0.4.0` and then a `bag` without the newest
      `globalVariables()`, so it reported `no visible binding` for names that were already
      declared. Reinstall first, then read the lints
- [x] **Added the `.lintr` config this repo never had.** Without one lintr ran its 80-char
      defaults. The config is the one `r-packages.md` prescribes, with two changes: its
      `"renv" = list(linters = "all")` form is rejected by lintr 3.3.0.1 (`Named entries of
      setting exclusions should designate line numbers`) so it is `"renv" = Inf`, and the
      four magrittr-bearing files exclude `pipe_consistency_linter` by name rather than the
      linter being switched off package-wide
- [x] `devtools::check(vignettes = FALSE)`: **0 errors, 0 warnings, 0 notes.** Two notes
      were found and fixed on the way: `.lintr` and `.claude` were shipping in the tarball
      (now in `.Rbuildignore`), and `.` and `:=` were undefined globals from the magrittr
      pipelines (`.` declared, `:=` imported from rlang)
- [x] `R CMD build` and the tarball inspected: 66 entries, shipping only `DESCRIPTION`,
      `inst/`, `LICENSE`, `man/`, `NAMESPACE`, `NEWS.md`, `R/`, `README.md` and `tests/`.
      No `.Rproj`, no `planning/`, no `CLAUDE.md`. The first attempt at this check **passed
      while doing nothing** — `ls` is colourised here, so the captured path carried ANSI
      codes, `tar` failed, and the `||` arm reported "none leaked". Re-run with `find` and a
      non-zero entry count asserted first
- [x] Counts agree: 15 `export()` lines, 15 `man/*.Rd`, 16 test files (one per export plus
      the internal guard), 18 `R/*.R` (15 exports, two internal helpers, `utils.R`).
      Re-measured after Phase 10's drop and Phase 9's rename: **14** exports, 14
      `man/*.Rd`, 15 test files, 17 `R/*.R`
- [ ] `pkgdown::check_pkgdown()` — **blocked on 4b.** Verified clean in a copy of the tree
      with the two URLs made consistent, so the reference index covers every topic and the
      URL is the only thing outstanding. Re-verified the same way after Phase 9 renamed
      the `metadata` concept to `catalogue` and moved two functions between families:
      "No problems found", so all 14 exports are still reached by the four groups
- [ ] Release `bag 0.5.0` as the final commit of the branch, tag, GitHub release —
      **blocked on 4b**, which is blocked on Phase 1

## Phase 8 — Protect, then switch, the consumers (separate PRs)

- [ ] **Before this branch merges:** pin the one consumer that declares the dependency to
      `@v0.4.2`. Merging `Package: bag` to the default branch otherwise makes it
      uninstallable — its `Remotes:` follows the GitHub redirect and installs a package
      named `bag`, leaving `Imports: spacehakr` unsatisfiable, and nine reporting repos
      install it
- [ ] Switch the public caller: one `spacehakr::spk_source_url()` call site in a
      water-quality sourcing script
- [ ] Switch the repo that declares the dependency: `Imports:` and `Remotes:` to `bag`
      together, a live catalogue-driven fetch path, and three deprecating shims
- [ ] **Grep each repo for the bare package name, not just `::`.** Four things there break
      on the name and no `spacehakr::` grep finds them: a WFS canary asserting on
      `packageVersion()`, a test that greps its own function bodies and checks each target
      against `getNamespaceExports()` — which after the rename **skips silently** rather
      than failing, because it is gated on the package being installed — three
      `mockery::stub()` targets, and a runnable vignette example. The other internal repo
      names the package in a host-provisioning install check
- [ ] Land the deprecating forwarders in both donor repos. The internal package's half is
      tracked by its own counterpart issue; `fpr` needs a new issue for its four

## Phase 9 — Final naming pass (supersedes the names used in Phases 2, 5 and 6)

Decided with the owner, 2026-10-31, after the intake landed and the names could be read
side by side. Three forks were put to them and all three took the recommendation.

**The principle:** drop prefixes that are *organisational* — `sp_`, `u_`, `fs_`, `meta_`,
which were a donor package's filing system and encode nothing a caller needs. Keep words
that are *contractual* — `assign`, `import`, `to_geojson`, `refresh` — which say what goes
in, what comes out, or whether the caller's file survives.

Twice during review a name was shortened and lost contract information: `bag_utm` next to
`bag_utm_to_sf` read as either direction, and `bag_geojson` dropped a conversion that is
real. Both were reverted. "Tight" has a floor, and the floor is the contract.

- [x] Rename the ten exports:

  | now | final | why |
  |---|---|---|
  | `bag_bcdata` | `bag_bcdc` | one stem for the catalogue family; `bcdc_` is the prefix the upstream bcdata package uses itself |
  | `bag_bcd_get_data` | `bag_bcdc_read` | today's name is a near-collision with `bag_bcdata` and does the opposite: reads to memory, not to disk |
  | `bag_meta_bcd_xref` | `bag_bcdc_index` | `meta_` is organisational |
  | `bag_meta_bcd_xref_col_comments` | `bag_bcdc_cols` | 30 characters, four stacked qualifiers |
  | `bag_layer_info` | `bag_layers` | pure reader, returns a data frame |
  | `bag_fs_backup` | `bag_backup` | `fs_` is organisational; this one genuinely is a backup |
  | `bag_sp_gpkg_backup` | `bag_gpkg_refresh` | refreshes coordinates and **can overwrite its source**; "backup" promised a safety it does not have |
  | `bag_sp_assign_utm` | `bag_assign_utm` | verb leads, grouping the two that annotate an existing object |
  | `bag_sp_assign_latlong` | `bag_assign_latlong` | as above |
  | `bag_sp_assign_sf_from_utm` | `bag_sf_from_utm` | the constructor; not an inverse of `bag_assign_utm`, so not named as a pair |

- [x] Unchanged, deliberately: `bag_url`, `bag_wfs`, `bag_gpx_import` (the verb is
      load-bearing — it writes files and returns `NULL`), `bag_gpkg_to_geojson` (a real
      conversion, and already the clearest name of the set)
- [x] Rename the two internals to the dotted convention this package already uses
      (`.bag_ogr2ogr`, `.bag_reencode`, `.bag_source_resolve`, `.bag_url_args`):
      `bag_chk_sf_point` to `.bag_chk_sf_point`, and `bag_meta_bcd_xref_pkg_schtab` to
      `.bag_bcdc_schtab`
- [x] Four families, each coherent: **download** (3), **catalogue** (4), **files** (4),
      **coordinates** (3). The `gpkg_` stem groups the three GeoPackage functions without
      needing a family of its own.

      Two functions moved to reach those counts, which the plan stated only as totals.
      `bag_bcdc` went from **download** to **catalogue** — the rename table's reason for
      the name is "one stem for the catalogue family", and the four `bag_bcdc*` are what
      make catalogue four. `bag_gpx_import` went from **files** to **download**, which
      makes download three: it is the only one of the five file helpers that brings data
      in from outside the project rather than operating on a file already in hand, and
      the section it renders under is titled "Fetch" — the package's own `Title` is
      "Fetch Public Data **and Field Files** to Disk". Verified by
      `pkgdown::check_pkgdown()`: every export is reached by one of the four groups
- [x] `_pkgdown.yml` reference groups, `.lintr` per-file exclusion paths, `@seealso` and
      `@family` cross-references, and the `system.file(package = )` calls all follow

### Measured asymmetry behind the coordinate names

`bag_assign_utm` and `bag_sf_from_utm` are **not** inverses, so naming them as a
direction pair (`sf_to_utm` / `utm_to_sf`) would promise a round trip that does not close:

| | `bag_assign_utm` | `bag_sf_from_utm` |
|---|---|---|
| accepts | `sf` POINT, required | plain data frame, no geometry |
| returns CRS | the **input** CRS | `crs_return`, default 3005 |
| geometry column | `geometry`, preserved | `geom`, hardcoded |

Measured: 4326 in, 4326 out of the first, 3005 out of the second, with the geometry column
renamed on the way. Left as donor behaviour and documented; `crs_return` and the hardcoded
`geom` land in the files ~20 call sites write, so changing either is a file-format change.

## Phase 10 — Drop the superseded layer remover

Decided with the owner, 2026-10-31. Measured first: badged
`lifecycle::badge("superseded")` by its donor in favour of
`gdalraster::ogr_layer_delete()`, and it has **zero live callers** — an org-wide code
search returned 11 hits, of which the only one in consumer code is a commented-out line.
`gdalraster` is already live in three of our GIS scripts and installed at 2.6.1.

This is the issue's own item 5 criterion, "helpers nothing calls", and it holds more
cleanly here than for the ten deleted in Phase 3: those at least had live callers under
their pre-extraction names.

- [x] Deleted `R/bag_u_rm_gpkg_layers.R`, its test file (11 blocks) and its `man/` page
- [x] Dropped `lifecycle` from `Suggests` — this was its only user
- [x] No `_pkgdown.yml` edit needed: its reference index uses `has_concept()` groups, so
      the entry drops out with the function. Exports 15 to 14, `man/` 14 pages, tests
      310 to 292 passing, `document()` clean
- [x] **Precondition met:** the data-loss defect was filed with the internal package
      before the deletion, carrying the fixed implementation, since that repo still ships
      the broken version and deleting our copy would otherwise leave the fix nowhere

## Phase 11 — Remove magrittr (folded into this branch)

Decided with the owner, 2026-10-31. First deferred to its own issue, then folded in on
reflection: Phase 9's rename opens these same four files, and the column-order tests have
to be written either way, so doing it separately would mean touching them twice and
reviewing them twice.

Measured: no newer package of ours declares `magrittr` or uses `%>%` in `R/` at all —
0 of 68 R files in one, 0 of 46 in another, 0 of 49, 0 of 18, 0 of 17, 0 of 11. Five older
packages declare it. Adding it here would make this the only new-generation package
carrying it, imported along with the donated functions.

The port is smaller than first judged: only **two** of the four donated files use
magrittr's `.` placeholder, and both uses are `sf::st_coordinates(.)` called **twice** on
the same geometry. Computing it once into a variable and injecting with `!!` is shorter,
does half the work, and is immune to the data-masking trap a bare variable inside
`mutate()` has. The other two files need only `|>`.

- [x] Closed the column-order test gap **before any rewrite**: every column assertion
      was `%in% names()`, so order was unpinned on exactly the three functions a rewrite
      would touch, and callers write those columns to disk. Measured first, then pinned:
      the three are **inconsistent with each other** and deliberately left so.
      `bag_assign_utm` and `bag_sf_from_utm` place the new columns before the geometry,
      because they end on `dplyr::select()` calls that push geometry last;
      `bag_assign_latlong` has no `select()`, so `mutate()` appends past the geometry and
      its columns land after it. Pinned rather than reconciled: the files callers write
      back carry this order. Mutation-checked with two `relocate()` edits in a copy of the
      tree, 4 tests red
- [x] **`dplyr::arrange(epsg)` turned out to be dead once the loop replaced
      `group_split`**, and was removed. It existed to make the group order agree with the
      separately derived CRS vector. A mutation test is what found it: deleting it left
      the ordering test **green**, because the rows now come back zone-ordered from the
      sorted loop keys and `bind_rows()`. Reversing the loop keys takes that test red, so
      the invariant is still pinned — just by the loop rather than by a prior sort
- [x] **Two tests added for the trap the `!!` injection exists to close.** Nothing in the
      suite distinguished `!!xy[, 1]` from a bare `xy[, 1]`, so the reason for the
      injection was unpinned. Each new test hands the function a decoy column named like
      the local it injects — `xy`, and `lon` for the zone arithmetic — and asserts the
      coordinates still come from the geometry. Mutation-checked by dropping the five
      `!!` marks: 5 assertions red
- [x] Per file, done with the Phase 9 rename so each is touched once:
      `bag_assign_latlong` — drop the two `st_coordinates(.)` calls for one, inject with
      `!!`; `bag_assign_utm` — the same, plus replace the `group_split`/`map2` pair whose
      group order has to match a separately derived CRS vector (an invariant held together
      by a comment) with a loop over `unique(sort(epsg))`; `bag_sf_from_utm` — `%>%` to
      `|>`, its `.x` is a purrr lambda and needs nothing; `bag_gpkg_refresh` — `%>%` to
      `|>`, a plain chain
- [x] `magrittr` out of `Imports` (16 to 15) and the four `@importFrom magrittr %>%` lines
      out; `rlang` stays for `:=` and `.data`
- [x] The four per-file `pipe_consistency_linter` exclusions come out of `.lintr` with it

## Owed at the end (reported, done after merge)

- [ ] File `fpr`'s forwarder issue, and report on the counterpart issue that bag exists
- [x] **Reported every donor defect found while porting.** Nine were found and only one
      had been filed; the rest sat in `progress.md`, reported nowhere, and this list did
      not ask for them. Filed 2026-10-31, grouped by function and each verified still
      present in the donor's current tree first: three issues with the internal package
      (the catalogue family's column-case/doubled-call/undeclared-import, the GPX reader's
      three, and the layer remover's data-loss path), and
      [fpr#139](https://github.com/NewGraphEnvironment/fpr/issues/139) for the
      never-firing geometry guard plus
      [fpr#140](https://github.com/NewGraphEnvironment/fpr/issues/140) for the
      `dir_backup` branch. Correction made while verifying: the guard is in **three** fpr
      helpers, not four — `fpr_sp_assign_sf_from_utm()` takes a plain data frame and
      correctly has none
- [ ] Report to the umbrella issue that its ODM conditional is settled — drone jobs do
      still run — and that three public repos depend on `ngr`'s copies of the helpers this
      branch deletes, which its ngr-retirement row has to cover
- [ ] Update the internal ecosystem registry's row and tagline for this repo, which still
      describes the deleted functions
- [ ] Unpin the consumer once its switch PR has landed

## Validation

- [x] Tests pass — FAIL 0 | WARN 0 | SKIP 2 | PASS 377, `lintr` 0,
      `check(vignettes = FALSE)` 0/0/0
- [x] `/code-check` clean (once over the branch with `/code-check branch`). Three rounds,
      19 findings, all reproduced and all fixed; 26 mutations red. Round 1: 9. Round 2: 6,
      **two inside round 1's fixes** — which is what put the loop on the enumeration rule.
      Round 3: 4, plus the mechanism (*a fix lands on the caller the symptom arrived
      through, and the sibling over the same container keeps the behaviour*) and the
      mechanical enumeration that ends it. Two of the 19 were data loss, one of them a
      regression introduced by Phase 11's rewrite
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:

- `devtools::test()` green, with `bag_url()`'s 30 `test_that()` blocks over 630 lines
  intact — the suite's centre of mass. Note two of `bag_wfs()`'s six blocks are `skip()`ed
  outright and two assert almost nothing, so green there proves little; the intake's new
  tests are where coverage actually has to come from
- `devtools::check(vignettes = FALSE)` with no ERROR or WARNING, in particular no
  undeclared-import note from the pruned `Imports:` or the intake
- **Counts agree:** `grep -c '^export(' NAMESPACE` equals the number of `man/*.Rd` files
  equals the number of functions the branch means to ship. The cheapest proof that the
  prune, the intake and `document()` are in step
- **`R CMD build` and inspect the tarball** for a leaked `bag.Rproj` — the one failure
  Phase 4 warns about, and `devtools::check()` does not report it
- **`pak::pkg_install("NewGraphEnvironment/bag")` into a clean library**, and then install
  the pinned consumer against it. The only check that catches the consumer breakage
- No `\.spk_` or `spk_` string survives in `tests/`, and every `mockery::stub()` target
  resolves in the namespace
- `git grep -i 'spacehakr\|spk_'` returns only `NEWS.md` history and `planning/archive/`.
  Written this way the gate is meetable: `CITATION.cff`, `dev/vm_packages.md` and
  `planning/README.md` are all fixed in Phase 4 rather than exempted
- Each consumer repo's CI green on its own switch PR — **after** this branch merges, since
  those PRs resolve `Remotes:` against the default branch
