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

## Phase 4 — Package identity

- [ ] `DESCRIPTION`: `Package: bag`; `Title`/`Description` about fetching public data and
      field files to disk, with the "Extracted from the ngr package" sentence gone;
      `URL`/`BugReports` to the new path; `Version: 0.5.0`
- [ ] `git mv spacehakr.Rproj bag.Rproj` **with** `.Rbuildignore`'s `^spacehakr\.Rproj$` in
      the same commit — out of step, the `.Rproj` ships in the tarball
- [ ] `_pkgdown.yml`: new `url:`, and **add a `reference:` section**. It has none today, so
      the index is auto-generated and `pkgdown::check_pkgdown()` has nothing to check —
      the gate the convention recommends is currently vacuous here
- [ ] `CITATION.cff` by hand via `/citation-cff` — eight hits, and its workflow fires only
      on a push to `main` touching `DESCRIPTION`, so on this branch it stays stale and
      fails the grep gate below
- [ ] `README.Rmd` → re-knit. Larger than a find-and-replace: the two functions the package
      now exists for appear **nowhere** in it today, including in its function table, so
      this is writing their first examples with real output. Also the two CI badge URLs at
      `:20`, the logo `alt` text at `:16`, the install line and the `library()` calls
- [ ] `data-raw/make_hexsticker.R` `package_name <- "bag"`; regenerate `man/figures/logo*.png`
- [ ] `NEWS.md`: a `# bag 0.5.0` heading recording the rename, the four new names, the
      deletion with its `v0.4.2` tag, and the intake. Leave the `# spacehakr <v>` history
- [ ] `dev/vm_packages.md` — titled for spacehakr and wrong in about a dozen places after
      the prune; `planning/README.md:33`; `tests/testthat.R`; the
      `system.file(package = )` calls in the keepers' tests
- [ ] `CLAUDE.md` above the marker: Repository/URL lines, the migration table, the naming
      section, the `@family` list, the `Key Dependencies` list (drop `httr`), the file-name
      and `gh issue create` examples, and the stale `Remotes:` section. Name no internal repo

## Phase 5 — Take in the internal package's seven

Copied in, renamed to `bag_*`, documented and tested here. The deprecating forwarders stay
that package's job (Phase 8). Its unexported xref helper travels with the xref pair.

- [ ] Port and rename the seven: the catalogue cross-reference and its column-comments
      companion, the catalogue reader, the GPX reader, the GeoPackage-to-GeoJSON converter,
      the GeoPackage layer remover, and the field-file backup
- [ ] **Write tests for the four that have none** — the column-comments companion, the GPX
      reader, the GeoJSON converter and the layer remover
- [ ] Fix the two defects a straight copy carries, both of which pass in the donor because
      imports resolve through sibling files: the catalogue reader calls `cli::` with no
      `@importFrom cli`, and the GeoJSON converter declares an unused `@importFrom dplyr`
      while calling `chk::` undeclared
- [ ] Decide the layer remover's fate before porting: it is badged
      `lifecycle::badge("superseded")` in favour of `gdalraster::ogr_layer_delete()`. Port
      it as-is, port it rewritten on `gdalraster`, or retire it instead of moving it
- [ ] Add the imports the intake needs (`janitor` for the reader's name cleaning, and
      whatever the GPX and backup paths reach) — stated in `DESCRIPTION`, not inherited

## Phase 6 — Take in `fpr`'s four

- [ ] Port `fpr_sp_gpkg_backup()` → `bag_gpkg_backup()`, and the three coordinate helpers
      (`fpr_sp_assign_utm`, `fpr_sp_assign_sf_from_utm`, `fpr_sp_assign_latlong`) → `bag_*`
- [ ] **Write tests for the three that have none** (only the UTM one has a test file)
- [ ] Fix the inverted point-geometry guard present in **all four**:
      `if (!attributes(sf::st_geometry(dat))$class[1] != "sfc_point")` is a double negation,
      so the check never does what it reads as. Restore the defect and prove the fixed
      guard fires
- [ ] **Flag the consequence before porting:** `fpr_make_geopackage()` stays in `fpr` and
      calls `fpr_sp_assign_sf_from_utm()`, so moving it makes `fpr` depend on `bag`. Either
      `fpr` takes `bag` as an Import, or that one helper stays. This is the only item here
      that changes another package's dependency graph
- [ ] Add `readr` and `waldo` if the backup function's csv/RData paths are ported intact

## Phase 7 — Verify and release

- [ ] `devtools::test()` green; `lintr::lint_package()` clean. Reinstall first — the
      installed copy is `0.4.0` against a `0.4.2` source, and both `lintr` and the test
      runner resolve against the installed package
- [ ] `devtools::check(vignettes = FALSE)` with no ERROR or WARNING
- [ ] `pkgdown::check_pkgdown()`, now that `_pkgdown.yml` has a `reference:` index
- [ ] Release `bag 0.5.0` as the final commit of the branch, tag, GitHub release

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

## Owed at the end (reported, done after merge)

- [ ] File `fpr`'s forwarder issue, and report on the counterpart issue that bag exists
- [ ] Report to the umbrella issue that its ODM conditional is settled — drone jobs do
      still run — and that three public repos depend on `ngr`'s copies of the helpers this
      branch deletes, which its ngr-retirement row has to cover
- [ ] Update the internal ecosystem registry's row and tagline for this repo, which still
      describes the deleted functions
- [ ] Unpin the consumer once its switch PR has landed

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
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
