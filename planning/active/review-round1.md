# Review round 1 — branch `31-rename-spacehakr-to-bag-fetch-public-dat`

## Checklist read

- `code-check.INDEX.md` — in full (37 H3s).
- `code-check-r.INDEX.md` — in full (115 H3s).
- `code-check-shell.INDEX.md` — in full (70 H3s).
- `code-check-spatial.INDEX.md` — in full (94 H3s).

FULL files, sections read in full:

- **code-check.FULL.md** — all 14 H3s under `## Mechanisms`, prose only (`|` table rows
  skipped per brief). Plus 7 of the 14 under `## Rules that stand alone`: "Do not edit
  files a long test run is reading", "Percent-encode a URL at construction, not at
  consumption", "Bare `y`, `n`, `on`, `off`, `yes`, `no` are booleans in YAML 1.1",
  "Documentation Staleness", "A link to a repo-hosted artifact must be *tracked*, not
  merely present", "An assertion that matches an interpolated value cannot see the claim
  around it", "A pluralisation marker takes the quantity of whatever was substituted
  last". **7 standalone H3s not read** (idempotent cold path, per-process override,
  adopting existing config, expiring credential, human-testing artifact, preview flag,
  ordered dispatch), plus the 6 under `## Security` and the 3 under `## Spreadsheets and
  PDFs` — this diff has no credentials, infra, spreadsheet or PDF surface.
- **code-check-r.FULL.md** — 10 of 115: "`fs::dir_ls(glob = )` matches the FULL path",
  "A `data-raw/` script must load the source tree", "Under `R CMD check`, tests run from
  a temp dir against the INSTALLED package", "`file(open = \"wb\", encoding = )` does not
  re-encode on write", "`expect_message(expr, regexp)` checks only the FIRST condition",
  "A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if `pkg` is
  undeclared", "Inside a dplyr verb, a column named like a local variable wins",
  "`bind_rows()` of all-`NULL` is a 0 x 0 tibble", "A `function(...)` mock hides
  arguments the real callee no longer accepts", "`system2(stdout = TRUE)` warns on a
  non-zero exit". **105 not read** — judged from their index lines as naming tools or
  shapes absent from this diff (duckdb/arrow/DBI/Postgres, terra, ggplot2, bookdown/
  pagedown, climr, earthdatalogin, parallel, Rcpp warnings, etc.).
- **code-check-spatial.FULL.md** — 6 of 94: "GeoJSON in a projected CRS is silently
  non-portable", "`sf::st_read()` promotes a mixed POLYGON/MULTIPOLYGON layer to
  all-MULTIPOLYGON", "sf: `st_intersection()` / `st_difference()` return a
  GEOMETRYCOLLECTION", "sf: reproject the polygon to get a lat/lon bbox", "Ask the file
  about its field names, not R", "`sf::st_make_valid()` rewrites geometry that was
  already valid" (and "gdalwarp writes INTO an existing destination", read while
  searching). **87 not read** — the terra/raster, STAC, lidR, gdalcubes, pystac and
  Python-side rules, which this branch deleted the code for.
- **code-check-shell.FULL.md** — 0 of 70 read in full. The only shell surface in the diff
  is `system2("ogr2ogr", args = shQuote(args))`, which is unchanged by this branch (pure
  rename of `.spk_ogr2ogr`), and its quoting behaviour is already documented in that
  function's own roxygen.

## How this was checked

Every claim below was reproduced. Probe scripts are in
`/private/tmp/claude-501/-Users-airvine-Projects-repo-spacehakr/96953e68-6a89-4a65-a434-6e36d29b5c0a/scratchpad/probe/`
and write only into `tempdir()`. For the one probe that needed to build the package
(`R CMD INSTALL`, to check whether the double `filter` import in `NAMESPACE` warns — it
does not; `bcdata` re-exports `dplyr::filter`, so both names resolve to one object), the
tree was copied to
`/private/tmp/claude-501/-Users-airvine-Projects-repo-spacehakr/96953e68-6a89-4a65-a434-6e36d29b5c0a/scratchpad/copy/bag`.
**The tree at `/Users/airvine/Projects/repo/spacehakr` was not edited.**

Donor provenance was checked against the installed `fpr` namespace
(`fpr_sp_assign_utm`, `fpr_sp_assign_latlong`, `fpr_sp_assign_sf_from_utm`,
`fpr_sp_gpkg_backup`), so findings 6, 7 and 4's `delete_dsn` are identified as carried-in
rather than newly introduced.

## Findings

- **[bug]** `R/bag_gpkg_to_geojson.R:56,60` — every layer is written as GeoJSON **in the
  GeoPackage's own CRS**, with no transform. For a BC Albers source — the normal case for
  BC spatial data — the output carries a `crs` member and projected coordinates:

  ```
  "crs": { "type": "name", "properties": { "name": "urn:ogc:def:crs:EPSG::3005" } },
  "coordinates": [ 836538.88122716685757, 1002497.208932122797705 ]
  ```

  RFC 7946 mandates WGS 84 and removed the `crs` member, so GitHub's map preview, Leaflet
  and Mapbox read those numbers as lon/lat and put the feature in the Atlantic. The
  function's own roxygen (lines 3–5) sells exactly that use case — *"GitHub and other web
  platforms render it directly when it is in WGS 84"* — while doing nothing to ensure it.
  QGIS honours the `crs` member, so the file opens correctly on the desktop that wrote it.
  Measured on a 3005 fixture. The bundled `inst/extdata/poly.gpkg` is WGS 84, so every
  test in `test-bag_gpkg_to_geojson.R` is structurally incapable of reaching this, and the
  round-trip check at `test-bag_gpkg_to_geojson.R:69-80` reads the file back through `sf`,
  which honours the `crs` member and agrees.
  - **Rule:** code-check-spatial.md "GeoJSON in a projected CRS is silently non-portable" ; code-check.md "A fixture that cannot reach the failure mode"

- **[bug]** `R/bag_chk_sf_point.R:45` — `inherits(sf::st_geometry(dat), "sfc_POINT")`
  rejects a **0-feature POINT layer**. `sf::st_read()` returns `sfc_GEOMETRY` for an empty
  layer even when the GeoPackage declares the type, measured:

  ```
  st_layers(): layer_name sites, geometry_type Point, features 0
  st_read()  : class(st_geometry(x)) == c("sfc_GEOMETRY", "sfc")
  ```

  So `bag_gpkg_refresh()` on a freshly created, not-yet-filled form GeoPackage — an
  ordinary field state — aborts with
  `` `the layer in path_gpkg` must have POINT geometry. ✖ Its geometry is <sfc_GEOMETRY>. ``
  That diagnosis is false: it *is* a point layer. The roxygen at lines 23–25 justifies the
  guard firing where the donor's never did by the MULTIPOINT length-mismatch case; the
  empty-layer case is a different one and has no such consequence. A
  `length(sf::st_geometry(dat)) == 0` escape, or testing the declared type via
  `sf::st_layers()`, both separate it. No fixture in `test-bag_chk_sf_point.R` or
  `test-bag_gpkg_refresh.R` has an empty layer.
  - **Rule:** code-check.md "Zero-length, empty, and unset are three different things" ; code-check.md "A fixture that cannot reach the failure mode"

- **[bug]** `R/bag_assign_utm.R:82-96` — zero-row input aborts naming an internal column.
  `unique(sort(dat2[["epsg"]]))` on an empty vector is `numeric(0)`, so `purrr::map()`
  returns `list()`, `dplyr::bind_rows(list())` is a 0 x 0 tibble with no columns at all,
  and `dplyr::select(-epsg)` then raises:

  ```
  Can't select columns that don't exist.
  ✖ Column `epsg` doesn't exist.
  ```

  `epsg` is a working column the caller never saw, so the message points at nothing the
  caller can act on. Measured on `pts[0, ]`. Reachable through `bag_gpkg_refresh()`,
  whose `update_utm` defaults to `TRUE`, for any empty point layer that gets past the
  previous finding. The sibling has the mirror shape: `bag_sf_from_utm(df0)` on a 0-row
  frame returns `c("tbl_df", "tbl", "data.frame")` — **not an `sf` object**, contradicting
  its documented `@return An sf data frame in crs_return` (`R/bag_sf_from_utm.R:18`).
  Guard the empty frame, or bind under a zero-row template taken from `dat2[0, ]`.
  - **Rule:** code-check-r.md "`bind_rows()` of all-`NULL` is a 0 x 0 tibble, and a typed template must take its types from the rows' source" ; code-check.md "Zero-length, empty, and unset are three different things"

- **[bug]** `R/bag_gpkg_refresh.R:80,95` — `write_back_to_path = TRUE` renames the layer
  and destroys every sibling layer, and the branch removed the only signal of it.
  `sf::st_read(dsn = path_gpkg)` with no `layer` takes the **first** layer (sf warns, but
  the warning says nothing about what follows), and the write-back is
  `sf::st_write(dat, path_gpkg, append = FALSE, delete_dsn = TRUE, quiet = TRUE)`, which
  deletes the whole GeoPackage and writes one layer named after the **file basename**.
  Measured:

  ```
  before: sites, aoi           # form_fiss_site_2026.gpkg
  after : form_fiss_site_2026  # `aoi` gone; `sites` renamed
  ```

  Single-layer case measured too: a layer called `sites` comes back as
  `form_fiss_site_2026`, so any QGIS project, Mergin form or script that names the layer
  breaks. The documented precondition (`@param path_gpkg` … "holding exactly one point
  layer", line 14) is **not guarded** — `.bag_chk_sf_point()` only inspects whichever layer
  `st_read()` happened to pick. `delete_dsn = TRUE` is donor behaviour (`fpr_sp_gpkg_backup`
  has it), but the donor wrote **without** `quiet = TRUE`, so a user at least saw
  `Writing layer 'form_fiss_site_2026'` and could notice the rename; this branch added
  `quiet = TRUE` and made it silent. `seed_point_gpkg()`
  (`tests/testthat/test-bag_gpkg_refresh.R:1-15`) writes one layer whose name already
  equals the file basename, so the rename is invisible to the suite, and no fixture has two
  layers. Minimum fix: abort when `nrow(sf::st_layers(path_gpkg))` is not 1, and pass the
  layer name through to `st_write(layer = )`.
  - **Rule:** code-check.md "A fixture that cannot reach the failure mode" ; code-check.md "Zero-length, empty, and unset are three different things"

- **[fragile]** `R/bag_gpx_import.R:111-118` — the track side aborts on a missing directory
  where the waypoint side returns empty, so the function's own "nothing to do" branch
  cannot be reached. Measured:

  ```
  fs::dir_ls("/no/such/dir", regexp = "[.]gpx$")  -> ERROR [ENOENT] Failed to search directory
  list.files("/no/such/dir", pattern = "[.]gpx$") -> character(0)
  ```

  Line 111 uses `list.files()` (tolerant); line 112 uses `fs::dir_ls()` (fatal). The
  defaults are two Garmin mount subdirectories, `/Volumes/GARMIN/Garmin/GPX/Archive/` and
  `/Volumes/GARMIN/Garmin/GPX/Current/` — a unit that has never archived has no
  `Archive/`, and an unmounted unit has neither. The call then aborts with a GDAL-free but
  opaque `[ENOENT]` before lines 115–118 can report *"No GPX files found for tracks;
  nothing written"*, and `dates_view = TRUE` aborts the same way. Every test passes a
  directory that exists (`dir_gpx_tracks = d`), so the suite cannot see it. `fs::dir_ls`
  on a path filtered by `fs::dir_exists()` first, or `list.files()` on both sides, closes
  it.
  - **Rule:** code-check.md "A fixture that cannot reach the failure mode"

- **[fragile]** `R/bag_assign_latlong.R:39,52` and `R/bag_assign_utm.R:63,91` — a CRS with
  no EPSG authority code makes the round trip abort with a message naming nothing.
  `crs_og <- sf::st_crs(dat, parameters = TRUE)$epsg` is `NA` for a CRS defined by proj
  string or by a WKT with no authority, and `sf::st_transform(crs = NA)` then raises
  `crs not found: is it missing?` — naming neither the argument nor the CRS. Measured on
  a custom Albers proj string; in `bag_assign_utm` the error arrives wrapped as
  `ℹ In index: 1. Caused by error: ! crs not found: is it missing?`. Both functions
  document `@return An sf data frame in the input CRS`, which also silently stops being
  true wherever the EPSG lookup resolves to a code whose definition differs from the
  stored WKT. `sf::st_crs(dat)` carries the CRS exactly and `st_transform()` accepts it,
  EPSG or not. Carried in from `fpr_sp_assign_utm` / `fpr_sp_assign_latlong` unchanged;
  not among the accepted tradeoffs.
  - **Rule:** none

- **[fragile]** `R/bag_assign_utm.R:74,96` — `epsg` is a hardcoded working column, so a
  caller's own `epsg` column is overwritten and then dropped, silently. Measured: input
  with `epsg = c("keep-a", "keep-b")` returns
  `id, utm_zone, easting, northing, geometry` — the caller's column is gone, no warning.
  `mutate(epsg = 26900 + ...)` clobbers it at line 74 and `select(-epsg)` removes it at
  line 96. The adjacent design note (lines 65–67) says the donor's `long` column was
  removed for exactly this class of reason; `epsg` was left. Keep the zone CRS in a local
  vector rather than a column, or name it with a `.`-prefix the caller cannot collide
  with. Carried in from `fpr_sp_assign_utm`.
  - **Rule:** none

- **[fragile]** `R/bag_sf_from_utm.R:7-9,15-16,52` — the documented constraint on
  `crs_return` is both self-contradictory and unenforced. Lines 7–9 say the returned CRS
  *"must be geographic — BC Albers or WGS 84 rather than a UTM zone"*, but EPSG:3005 (BC
  Albers, and the default) is a **projected** CRS, so the rule as written excludes its own
  example and a reader cannot tell which property is actually required. Nothing checks it
  either — `chk::chk_numeric(crs_return)` is the only validation — so a caller who passes
  one zone's EPSG (26909, say) gets `st_transform()`ed geometry that is silently wrong for
  every point outside that zone, with no error. State the real requirement (one CRS valid
  across every zone present) and assert it, or drop the claim.
  - **Rule:** none

## Noted, not findings

- `R/bag_bcdc_read.R:105` — `"Check that {.field {col_extract}} {?is/are} a column{?s} of
  the record."` renders as *"Check that A and B are a columns of the record."* for more
  than one column: the `{?s}` marker takes the right quantity, but the indefinite article
  is not pluralised away. Measured. Message grammar only, in an abort path — cosmetic, so
  not reported above, and **not** an instance of code-check.md "A pluralisation marker
  takes the quantity of whatever was substituted last" (the quantity is correct here).
  Every other `{?...}` marker in the branch was checked and renders correctly:
  `bag_bcdc_index.R:108` ("1 catalogue package publishes" / "2 catalogue packages
  publish"), `bag_gpkg_to_geojson.R:65`.
- Checked and clean, so stated here rather than left as silence: `tools` and `utils` are
  absent from `DESCRIPTION` `Imports:` while `NAMESPACE` imports from both, which is
  **legal** — `tools:::.check_package_depends()` allows base packages as namespace imports
  without declaration, and it returns `list()` on this tree. `tools:::.check_packages_used_in_tests()`
  is clean, so no test reaches an undeclared package with `::`. The double import of
  `filter` (`bcdata` and `dplyr`) produces no "replacing previous import" warning on a real
  `R CMD INSTALL`, because `bcdata` re-exports `dplyr::filter`. `janitor::clean_names()`
  keeps the `sf` class and the `sf_column` attribute (janitor 2.2.1), so
  `bag_bcdc_read.R:110` is safe. `_pkgdown.yml`'s four `has_concept()` groups cover all
  14 exports. Removing `^vignettes/articles$` from `.Rbuildignore` is safe: `vignettes/`
  no longer exists.
- Not re-flagged because the bodies are unchanged by this branch (pure renames, verified
  in the diff): `bag_wfs()`'s bbox reprojection via `st_bbox(st_transform(st_as_sfc(bbox)))`
  (code-check-spatial.md "sf: reproject the polygon to get a lat/lon bbox, never transform
  the projected bbox corners"), `bag_wfs()` leaving a non-200 response body on disk as
  `<layer>.geojson` before aborting, and `bag_bcdc()`'s `st_intersection()` with a mask
  (code-check-spatial.md "sf: `st_intersection()` / `st_difference()` return a
  GEOMETRYCOLLECTION that QGIS will not draw"). Worth separate issues if wanted, but they
  are not what this branch changed.
