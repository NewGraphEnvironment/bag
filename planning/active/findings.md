# Findings — Rename spacehakr to bag (#31)

## Issue context

**If we do it:** spacehakr becomes bag, a package named for the one job its callers use it
for: fetching public data and field files and saving them to disk. Published reports can
then get their sourcing and file helpers from a public package, and its imports shrink to
what fetching needs. **If we never do:** the package keeps a name that says nothing, twelve
functions nobody calls, and a `terra` import those twelve exist for, while the sourcing
helpers reports actually need stay in an internal package.

### Problem

Of spacehakr's 14 exports, two have callers: `spk_source_url()` and `spk_source_bcdata()`,
which download a layer from a URL or the BC Data Catalogue into a GeoPackage. The rest are
drone-imagery and raster helpers (`spk_odm`, `spk_gdalwarp`, the `spk_rast_*` set,
`spk_res`, `spk_stac_calc`, `spk_join`, `spk_poly_to_points`, `spk_q_layer_info`) with no
direct callers. Seven related functions, also fetchers and spatial file helpers, sit in an
internal package, and published reporting pipelines call them.

### Proposed Solution

1. **Rename the repository and package to `bag`, prefix `bag_`.** GitHub redirects the old
   URL, but a renamed repository cannot also publish a `spacehakr` package of forwarders,
   so the three repositories that call `spacehakr::` switch to `bag::` in the same move.
   Cut a final `spacehakr` release before the rename, so the last version under the old
   name stays installable by its tag.
2. **Keep and rename the live functions:** `spk_source_bcdata()` → `bag_bcdata()`,
   `spk_source_url()` → `bag_url()`; `spk_geoserv_dlv()` → `bag_wfs()`, and
   `spk_layer_info()` → `bag_layer_info()`.
3. **Take in the seven fetchers and file helpers** (a BC Data Catalogue cross-reference and
   its column comments, a catalogue reader, a GPX reader, GeoPackage-to-GeoJSON, a
   GeoPackage layer remover and a field-file backup), with their tests written here. Most
   have none.
4. **Take in fpr's field-file helpers:** `fpr_sp_gpkg_backup()` and the `fpr_sp_assign_*`
   coordinate functions, with forwarders left in fpr.
5. **Delete the helpers with no callers.** Git history and a tag before the deletion keep
   them. `spk_odm` moves to the drone-imagery catalogue's own tooling if it still runs
   drone jobs.
6. **Imports drop to what fetching needs** (`bcdata`, `sf`, `httr2`, `xml2`, `cli`, `chk`,
   `fs`). `terra` goes with the raster helpers.

The other members of the effort, and the rules behind it, are tracked under the
`track:package-boundaries` label.

## The name is free

- Not in CRAN's package index: 25,636 names extracted from
  `available_packages_by_name.html`, controls `sf` and `terra` both found, no exact or
  case-variant `bag`. Nearest neighbours are `bage`, `baggr`, `baguette`, `bagyo`.
- `gh api repos/NewGraphEnvironment/bag` → 404, and no repo in the org starts with `bag`.
- The two sibling names the umbrella issue plans, `chef` and `flick`, are also free.

## `v0.4.2` is already the pre-deletion tag

`git diff v0.4.2..HEAD` over `R/`, `tests/`, `man/`, `NAMESPACE`, `DESCRIPTION` and `inst/`
is empty. The only two commits since the tag touched `CITATION.cff` (the bot) and
`CLAUDE.md` (a conventions sync). So issue item 1's "cut a final `spacehakr` release before
the rename" is already satisfied, and effort rule 4's "a tag before deleting" needs no new
tag.

## Who actually calls this package

Measured by sweeping every checkout under `~/Projects/repo`, excluding `.git`, `docs/` and
`renv/`.

**Three repositories call `spacehakr::` in live code** — matching the issue's "three
repositories" exactly. One is public (`restoration_wedzin_kwa_2024`, a single
`spk_source_url()` call in a water-quality sourcing script); two are internal. Between them
they call only `spk_source_url()` and `spk_source_bcdata()`, confirming the premise. Only
one declares the dependency in its `DESCRIPTION`, in both `Imports:` and `Remotes:`.

**Four things in the repo that declares it break on the package *name*, not on a
`spacehakr::` call**, so a grep for the `::` form finds none of them:

| what | why it breaks |
|---|---|
| a WFS canary script | asserts on `packageVersion("spacehakr")` |
| a deprecation test | greps its own function bodies for `spacehakr::spk_[A-Za-z0-9_]+` and checks each target against `getNamespaceExports("spacehakr")` |
| three `mockery::stub()` targets | the package name appears in the stub string |
| a vignette | a runnable `spacehakr::spk_source_bcdata()` example |

The deprecation test is gated on `skip_if_not_installed("spacehakr")`, so after the rename
it **skips silently** rather than failing — the quiet direction.

The other internal caller names the package in a host-provisioning install check as well as
at its one call site.

## The twelve "uncalled" helpers are live under their old names

`ngr` still exports twelve `ngr_spk_*` functions, and they are **independent
implementations, not shims** — `ngr/DESCRIPTION` contains no `spacehakr` line in `Imports`
or `Remotes`, and the bodies carry no `spacehakr::` call. So deleting spacehakr's copies
strands nobody.

Three public repos call ngr's copies in live code:

| repo | functions |
|---|---|
| `restoration_wedzin_kwa_2024` | `ngr_spk_geoserv_dlv`, `ngr_spk_layer_info` (×2), `ngr_spk_join` (×2), `ngr_spk_res` (×2), `ngr_spk_gdalwarp` (×2) |
| `stac_uav_bc` | `ngr_spk_odm` (×3) |
| `fish_passage_peace_2024_reporting` | `ngr_spk_join` |

Two consequences:

- **The umbrella issue's ODM conditional is settled.** `spk_odm` moves to the drone
  catalogue's own tooling "if it still runs drone jobs" — it does, three live call sites.
- **Keeping `spk_geoserv_dlv()` and `spk_layer_info()` is justified.** Both look dead under
  their spacehakr names and are in live use under their ngr ones.

It also means the umbrella issue's claim that thirteen of ngr's functions "are already
shims into spacehakr" is not reproducible from the checkout.

## The published URL, measured rather than chosen

`gh api repos/NewGraphEnvironment/spacehakr/pages` reports
`html_url: http://www.newgraphenvironment.com/spacehakr/` with `cname: null` and
`source: {branch: gh-pages, path: /}` — an org-level verified domain, so every repo
publishes at `www.newgraphenvironment.com/<repo>/`.

Both candidate URLs return 200, and the `.github.io` form **redirects to**
`www.newgraphenvironment.com/<repo>/`. Checked against a sibling package too, same
behaviour. So `_pkgdown.yml`'s host is the one GitHub serves, and `DESCRIPTION`'s
`.github.io` form is a working alias. Eight of nine sibling packages use the alias in
`_pkgdown.yml`; this repo is the exception, and it happens to be the one that matches
what Pages reports.

Decided: `https://www.newgraphenvironment.com/bag/` in both. There are **three** stale
copies to fix, not two — `_pkgdown.yml`, `DESCRIPTION` and `CLAUDE.md`'s Repository
Context block.

The Pages path derives from the repo name, so it cannot resolve to `/bag/` until the repo
is renamed. That is what puts the rename first.

## Dependency reach, per keeper

Grepped `<pkg>::` across `R/`, then checked the keepers' four test files individually.

| keeper | reaches |
|---|---|
| `bag_url` | chk, cli, fs, httr2, tools, utils |
| `bag_bcdata` | bcdata, chk, sf, stringr |
| `bag_wfs` | chk, cli, fs, httr2, sf, stringr |
| `bag_layer_info` | dplyr, glue, purrr, sf |
| the keepers' tests add | mockery, testthat, and sf / fs / bcdata / tools |

So `Imports:` goes from 14 to **10**: `bcdata, chk, cli, dplyr, fs, glue, httr2, purrr, sf,
stringr`.

- `terra` is reachable only from `spk_rast_ext`, `spk_rast_not_empty`, `spk_res`,
  `spk_stac_calc`, and a `@seealso` in `spk_rast_rm_empty`. The `spk_odm.R` hit is the word
  "terrain".
- `rlang` survives only as `@importFrom rlang .data` in the deleted join.
- `tibble` and `xml2` only in the deleted QGIS reader.
- **The issue's own target list is wrong in both directions**: it keeps `xml2`, which goes
  with the QGIS reader, and omits `dplyr`, `glue`, `purrr` and `stringr`, which the keepers
  need.
- `tools`, `utils` and `stats` sit in `NAMESPACE` `importFrom()` without being in
  `DESCRIPTION Imports:`. Pre-existing, CI green, left alone.

`Suggests:` keeps only `mockery` and `testthat`. `stars` is referenced nowhere in the repo
at all — a dead Suggest. `knitr` and `rmarkdown` become unreachable too: `knitr` survives
only in `README.Rmd`, which is `.Rbuildignore`d, and no `VignetteBuilder` is set.

## Fixtures and globals

- `inst/extdata/poly.gpkg` is read by a **keeper's** test (`test-spk_layer_info.R:5, 18,
  99`), so it stays. `points.gpkg` is read only by the deleted join test and by
  `README.Rmd:74`. `test1.tif` and `test2.tif` have no surviving consumer.
- `globalVariables()` keeps `driver` and `name` — used at `spk_layer_info.R:38` (bare, in a
  `purrr::map_chr()`) and `:53` (`dplyr::select(-driver)`). `.data`, `layer_name` and
  `time_exported` go with the deleted files.
- `R/utils.R`'s `@importFrom stats setNames` is dead once the deletions land: its only
  users are `spk_poly_to_points.R:57` and `spk_q_layer_info.R:56`.

## Both pkgdown articles document only the deleted STAC function

`spk_stac_calc` is the sole package function either article mentions; the only other
`spacehakr` reference in each is `library(spacehakr)`. So both go with it, and bag ships no
article until one is written for fetching.

## The donor functions, and what they carry

Eleven, not nine as first assumed. **Seven have no test file** — counted by listing both
`tests/testthat/` directories, not from the issues:

- From the internal package, seven move (an eighth is retired there, not moved). Four have
  no test: the column-comments companion, the GPX reader, the GeoJSON converter and the
  layer remover. An unexported xref helper travels with the xref pair.
- From `fpr`, four move. Only `fpr_sp_assign_utm` has a test file.

Defects a straight copy would carry in:

| function | defect |
|---|---|
| the catalogue reader | calls `cli::` with no `@importFrom cli` |
| the GeoJSON converter | declares an unused `@importFrom dplyr`, calls `chk::` undeclared |
| all four `fpr` ones | `if (!attributes(sf::st_geometry(dat))$class[1] != "sfc_point")` — a double negation, so the point-geometry guard never does what it reads as |
| the layer remover | badged `lifecycle::badge("superseded")` in favour of `gdalraster::ogr_layer_delete()` |

Both import defects pass in the donor package because imports resolve through sibling
files rather than declarations — the same trap its earlier move hit.

**One dependency-graph consequence:** `fpr_make_geopackage()` stays in `fpr` and calls
`fpr_sp_assign_sf_from_utm()`. Moving that helper makes `fpr` depend on `bag`. Either `fpr`
takes `bag` as an `Import`, or that one helper stays behind.

## The consumer-install hazard

Merging `Package: bag` to the default branch makes the one consumer that declares the
dependency **uninstallable**: its `Remotes:` entry follows the GitHub redirect and installs
a package *named* `bag`, leaving its `Imports: spacehakr` unsatisfiable. Nine reporting
repos install that consumer.

This repo's `CLAUDE.md` has a whole section on the adjacent hazard — unpinned `Remotes:`
turning a consumer's CI red on an unrelated PR — and it also says entries exist in two
named consumers. **One of those two has no such entry at all**, measured. That makes the
pin safe: with a single consumer, "pin everywhere or nowhere" is satisfied by pinning it,
and the two-consumers-at-two-tags conflict cannot arise.

So: pin to `@v0.4.2` before this branch merges, unpin when its switch PR lands.

## Other stale claims to fix while here

- `CLAUDE.md` lists `httr` under Key Dependencies. `httr` (v1) is used nowhere; the package
  uses `httr2`.
- `dev/vm_packages.md` is titled for spacehakr and names about a dozen packages the prune
  removes, plus "Docker (for OpenDroneMap functions)".
- `planning/README.md:33` names the package and is **not** under `planning/archive/`, so a
  grep gate that exempts only the archive still trips on it.
- An internal ecosystem registry carries a row for this repo whose tagline describes the
  deleted functions.
- `spk_geoserv_dlv`'s `@examples` calls `spk_geoserv_dl()` — a name that has not existed
  since the `v` was added.
- `R/spk_source_url.R:357`, in an `@noRd` block, references `[spk_gdalwarp()]`. Invisible
  to `check` because `@noRd` generates no Rd, and a keeper→deleted reference.

## Two gates that look stronger than they are

- **`pkgdown::check_pkgdown()` is vacuous here.** `_pkgdown.yml` is four lines with no
  `reference:` section, so the index is auto-generated and there is nothing to check. Add
  a `reference:` section to make the gate real.
- **`mockery::stub()` does not verify its target exists.** The `.spk_*` helper names are
  passed as character strings (`test-spk_source_url.R:395, 396, 422, 428, 457, 458, 498`,
  and two more). A missed rename is a silent no-op that falls through to the real function
  — and in the block at `:382` that means a live `httr2` request in a suite whose own
  comment says no test touches the network, plus a real `ogr2ogr` shell-out. Two of the
  three affected blocks would fail cleanly; that one would not.

Also worth knowing before leaning on green: of `bag_wfs()`'s six `test_that()` blocks, two
are `skip()`ed outright and two assert only `TRUE` and `is(bbox, "bbox")`.

## Environment

`check_pkg_stale.sh`: the **installed** spacehakr is `0.4.0` against a `0.4.2` source.
Reinstall before running `lintr::lint_package()` or the suite — both resolve against the
installed package, so a stale install reports lints and failures that do not belong to the
source tree. Fifteen other first-party packages are also stale; only this one matters here.

`CLAUDE.md` is not published by the pkgdown site — both `CLAUDE.html` and `CLAUDE.md`
return 404 on the live site, and the shared workflow gates root pages with
`allowed-pages: 404 authors index LICENSE-text`.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| CRAN name check reported `bag` free *and* found no package starting `ba`, with 25,636 links on the page | The probe was broken, not the world: names are wrapped in `<span class="CRAN">`, not bare in the anchor. Re-extracted; controls `sf` and `terra` then both resolved |
| `curl -o /dev/null -w %{http_code}` on `cran.r-project.org/package=<name>` returned 303 for every name, including `sf` | A redirect, so the status carries no information. Used the name index instead |
| Zenodo's search API returned `hits: 0` for the concept DOI | Query shape, not a missing record. `curl -L` on `doi.org/10.5281/zenodo.23524742` resolves to a live record titled for spacehakr |
