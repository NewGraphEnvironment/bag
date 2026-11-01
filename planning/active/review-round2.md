# Review round 2 — branch `31-rename-spacehakr-to-bag-fetch-public-dat`

No file in `/Users/airvine/Projects/repo/spacehakr` was edited. Every probe ran from
`/private/tmp/claude-501/-Users-airvine-Projects-repo-spacehakr/96953e68-6a89-4a65-a434-6e36d29b5c0a/scratchpad/probe`,
loading the package with `pkgload::load_all()` and writing only into `tempfile()`
directories. Measured on sf 1.1.2, GEOS 3.13.0, GDAL 3.8.5, PROJ 9.5.1.

## Checklist read

- **code-check.INDEX.md** — in full.
- **code-check.FULL.md** — all 14 H3 sections under `## Mechanisms`, in full (prose, `|`
  table rows skipped). Plus four of the 14 `## Rules that stand alone`: "An assertion
  that matches an interpolated value cannot see the claim around it", "A pluralisation
  marker takes the quantity of whatever was substituted last", "Test the cold/create path
  of idempotent code, not just the warm no-op", "Percent-encode a URL at construction,
  not at consumption", and the three lines of "Documentation Staleness". **Not read in
  full: 9 stand-alone rules, 6 Security rules, 3 Spreadsheets/PDFs rules** — judged to
  name nothing this diff uses (no CI/YAML, credentials, `.tfvars`, firewall rules, S3
  policies, dry-run flags, severity dispatch, repo-hosted artifact links, spreadsheets or
  PDFs).
- **code-check-r.INDEX.md** — in full.
- **code-check-r.FULL.md** — read in full: "Inserting a helper between a roxygen block and
  its function rebinds `@export`", "Under `R CMD check`, tests run from a temp dir against
  the INSTALLED package", "A `pkg::` call in a test passes `devtools::test()` and fails
  `R CMD check` if `pkg` is undeclared", "Inside a dplyr verb, a column named like a local
  variable wins", "A `function(...)` mock hides arguments the real callee no longer
  accepts", "`expect_message(regexp = \"...$\")` never matches", "testthat 3e
  `expect_message()` returns the condition", "`bind_rows()` of all-`NULL` is a 0 x 0
  tibble", "`paste()` with a zero-length argument returns length ONE", "`cli` reads
  `{.name}` as a STYLE", "`$` on a list partial-matches", "`system2(stdout = TRUE)` warns
  on a non-zero exit", "`.Rbuildignore` has no comment syntax", "`R CMD build` ships every
  top-level directory not in `.Rbuildignore`", "`expect_false(identical(x, y))` cannot
  fail when the two are different types", "Tests that silently do not run", "A
  `skip_if_not()` skips only its own `test_that()` block", "`file(open = \"wb\",
  encoding = )` does not re-encode on write", "`fs::path()` collapses the `//` after a URL
  scheme", "`fs::dir_ls(glob = )` matches the FULL path", "`fs::file_move()` onto an
  existing directory", "Base `file.info()` has no inode column", "`ifelse()` with an
  all-NA test", "`sub()` takes one replacement". **~95 headings not opened** (duckdb,
  arrow, DBI/Postgres, ggplot2, bookdown/knitr/paged.js, parallel, climr,
  earthdatalogin, pak, digest/hash, locale collation, POSIXct parsing, readBin, jsonschema
  — none appears in this diff).
- **code-check-shell.INDEX.md** — in full. **code-check-shell.FULL.md: 0 sections
  opened.** The diff contains no shell, no `sed`/`awk`, no `git`/`gh` scripting; the one
  shell-adjacent call, `system2("ogr2ogr", shQuote(args))`, is covered by the two
  code-check.md/code-check-r.md entries read above.
- **code-check-spatial.INDEX.md** — in full.
- **code-check-spatial.FULL.md** — read in full: "bcdata: `filter()` translates the calls
  inside it", "bcdata returns a column whose values are all missing as character", "The BC
  WFS caps an un-paged `GetFeature` at 10,000 features", "bcdata's error text does not
  carry a WFS failure's cause", "sf: name validation must account for the geometry
  column", "sf: reproject the polygon to get a lat/lon bbox", "sf: `st_intersection()` /
  `st_difference()` return a GEOMETRYCOLLECTION", "GeoJSON in a projected CRS is silently
  non-portable", "`sf::st_read()` promotes a mixed POLYGON/MULTIPOLYGON layer", "A GDAL
  failure partway through `sf::st_read()`", "Ask the file about its field names, not R", "A
  GeoPackage is a SQLite database, and that leaks in three ways", "The same leak reaches R
  and OGR SQL", "Restoring a GeoPackage from a copy", "A coordinate stored as an attribute
  can disagree with the geometry it describes", "`sf::gdal_utils()` does not raise when
  GDAL cannot open the source", "gdalwarp writes INTO an existing destination", "A reader
  that accepts a UTC offset may not be applying it", "An offset regex must be anchored to a
  time", "`sf::st_make_valid()` rewrites geometry that was already valid", "`atan2(0, 0)`
  is 0", "A name is not a key: `GNIS_NAME` matches features all over BC", "sf and terra can
  link different GDALs". **~55 headings not opened** — every terra, raster, gdalcubes,
  STAC/pystac, lidR, QGIS-`.qml`, COG/VRT, Wayback and FWA entry; the diff has no raster
  code and no terra dependency (`terra` was removed from `Imports`).

## Findings

Six. Three are in code this branch wrote; two concern round-1 fixes being incomplete or
over-broad; one is a false claim in a new warning message.

---

- **[bug]** `R/bag_assign_utm.R:96-113` — a point whose geometry is **empty**, or whose
  coordinates are `NA`, is **dropped and replaced by one all-NA row per UTM zone**. Every
  attribute of the real row is destroyed, and the row count changes.

  The chain:

  ```r
  lon   <- sf::st_coordinates(dat_wgs)[, 1]        # NA for an empty POINT
  epsg  <- 26900 + dat2[[col_zone]]                # NA for that row
  zones <- unique(sort(epsg))                      # sort() drops NA (na.last = NA)
  dat2[epsg == epsg_zone, ]                        # logical NA subscript -> an all-NA ROW
  ```

  `sort()` silently discards the NA, so the row belongs to no zone and is never emitted.
  Worse, `epsg == epsg_zone` is `NA` for that row in **every** pass, and
  `[.data.frame` answers an `NA` subscript with a fabricated row of `NA`s — so one bad
  input row yields `length(zones)` phantom rows. Output size is
  `n_valid + n_na * n_zones`, not `nrow(dat)`.

  Measured, three zones plus one empty point (4 rows in, 6 out):

  ```
         site note utm_zone easting northing            geometry
  1         a    w        9  532381  6039269 POINT (-128.5 54.5)
  NA...2 <NA> <NA>       NA     NaN      NaN         POINT EMPTY
  2         b    x       10  467619  6039269 POINT (-123.5 54.5)
  NA...4 <NA> <NA>       NA     NaN      NaN         POINT EMPTY
  3         c    y       11  402861  6040190 POINT (-118.5 54.5)
  NA...6 <NA> <NA>       NA     NaN      NaN         POINT EMPTY
  ```

  `site = "d", note = "z"` is gone. No warning, no error.

  **It reaches disk through `bag_gpkg_refresh()`.** A field row entered without a GPS fix
  is exactly this case: an empty-geometry row in a single-layer point GeoPackage. The
  layer still reads back as `sfc_POINT`, so `.bag_chk_sf_point()` accepts it (correctly),
  `update_utm` defaults to `TRUE`, and `write_back_to_path = TRUE` writes the corrupted
  frame over the GeoPackage. Measured end to end on `form_fiss_site_2026.gpkg`, 3 rows in,
  4 rows on disk afterwards:

  ```
    site utm_zone easting northing                geom
  1   s1        9  532381  6039269 POINT (-128.5 54.5)
  2 <NA>       NA      NA       NA         POINT EMPTY
  3 <NA>       NA      NA       NA         POINT EMPTY
  4   s3       11  402861  6040190 POINT (-118.5 54.5)
  ```

  The sibling function is the control: `bag_assign_latlong()`, which does no grouping,
  keeps the row and writes `NaN` into `lon`/`lat` — so this is specific to the per-zone
  split, not to empty geometry in general.

  Reproduce:

  ```r
  d <- sf::st_sf(site = c("a", "b"),
                 geometry = sf::st_sfc(sf::st_point(c(-128.5, 54.5)), sf::st_point(),
                                       crs = 4326))
  suppressWarnings(bag_assign_utm(d))     # row "b" becomes an all-NA row
  ```

  Note this is adjacent to round-1 fix #3 (zero-row input) and was not reached by it: the
  zero-row path is the `length(zones) == 0` branch, while this is the
  `length(zones) >= 1` branch with an NA member. Every fixture in
  `test-bag_assign_utm.R` builds coordinates from literal `lon`/`lat` numbers, so no test
  in the file can reach it.

  Fix direction: resolve the NA before it reaches the subscript, e.g. key the groups on
  `dat2[!is.na(epsg) & epsg == epsg_zone, ]` and decide explicitly what happens to the
  unzoned rows — carry them through with `NA` zone/easting/northing (which is what
  `bag_assign_latlong()` does), or abort naming the offending row numbers. Pin it with a
  fixture that has an empty point among several zones and assert `nrow(out) == nrow(dat)`
  **and** that no input attribute value is lost.
  - **Rule:** code-check.md "Zero-length, empty, and unset are three different things" ; code-check.md "A fixture that cannot reach the failure mode"

---

- **[bug]** `R/bag_gpkg_to_geojson.R:67-70` — **round-1 fix #1 is incomplete.** Its
  documented escape hatch for a layer with no CRS cannot fire on a GeoPackage, so such a
  layer **aborts the whole function** part-way through the loop.

  ```r
  crs_in <- sf::st_crs(d)
  if (!is.na(crs_in) && crs_in != sf::st_crs(4326)) {
    d <- sf::st_transform(d, crs = 4326)
  }
  ```

  The comment above it states the intent: *"one whose CRS is missing is written as it
  stands — `st_transform()` cannot guess, and refusing would make the function useless on
  an unreferenced layer."* But GDAL's GPKG driver never returns `NA_crs_` for an
  unreferenced layer. The GeoPackage spec reserves `srs_id = -1` for "undefined
  Cartesian" and `0` for "undefined geographic", and both read back as a **real CRS
  object**:

  ```
  srs_id -1 -> is.na(st_crs): FALSE   ENGCRS["Undefined Cartesian SRS", ...]
               transform to 4326: ERROR: OGRCreateCoordinateTransformation(): transformation not available
  srs_id  0 -> is.na(st_crs): FALSE   GEOGCRS["Undefined geographic SRS", ...]
               transform to 4326: OK   (silently treats undefined lon/lat as WGS 84)
  ```

  And `sf::st_write()` itself produces the `-1` case — writing an sf whose CRS is `NA`
  warns *"substituting ENGCRS[...] for missing CRS"* and stores `srs_id = -1`. So the
  round trip through sf's own writer reaches the aborting branch:

  ```
  sf-written NA crs -> is.na(st_crs): FALSE
  ```

  Measured on a two-layer GeoPackage (`aaa` in 4326, `zzz_nocrs` unreferenced):

  ```
  result: ERROR: OGRCreateCoordinateTransformation(): transformation not available
  files left in dir_out: aaa.geojson
  ```

  Three things are wrong with that, in increasing order: the message names neither the
  function nor the layer; the loop has already written `aaa.geojson` and reports nothing
  about the partial result; and `is.na(crs_in)` is a **branch with no reachable true case**
  for GeoPackage input, so no mutation of it could ever be caught — restoring the defect
  would not have found this, only asking what would have to be true for the predicate to
  fire.

  `test-bag_gpkg_to_geojson.R` has 10 tests and none constructs an unreferenced layer, so
  the suite is green.

  Fix direction: test the property rather than the proxy — `is.na(crs_in) ||
  grepl("Undefined", crs_in$Name %||% "")` is still a proxy; the robust form is to try the
  transform and handle its failure explicitly (skip the layer with a `cli_alert_warning`
  naming it, or abort up front before any layer is written), and to decide out loud what
  "undefined geographic" means rather than letting GDAL assume WGS 84. Pin both `srs_id`
  values.
  - **Rule:** code-check.md "A proxy is not the property" ; code-check.md "Restore the bug and prove the guard fires"

---

- **[bug]** `R/bag_gpkg_refresh.R:136-139` — the `.RData` block `assign()`s and `rm()`s
  into `environment()`, the function's **own frame**, so a GeoPackage whose base name
  matches one of the function's locals breaks the call.

  ```r
  obj_name <- tools::file_path_sans_ext(basename(path_gpkg))
  assign(obj_name, dat, envir = environment())
  save(list = obj_name, file = fs::path(dir_backup, obj_name, ext = "RData"))
  rm(list = obj_name, envir = environment())
  ```

  Measured, `write_to_rdata = TRUE, return_object = TRUE`:

  ```
  dat.gpkg           -> ERROR: object 'dat' not found
  obj_name.gpkg      -> ERROR: invalid first argument
  layer_name.gpkg    -> ok
  path_gpkg.gpkg     -> ok
  sites.gpkg         -> ok
  ```

  `dat.gpkg`: the `rm()` deletes the function's working object, and `return(dat)` four
  lines later fails. `obj_name.gpkg`: `obj_name` is rebound to the `sf` object, so
  `save(list = obj_name, ...)` is handed a data frame where a character vector is wanted.
  Both are hard aborts *after* `write_back_to_path` has already run, so with
  `write_back_to_path = TRUE` the GeoPackage is rewritten and then the call dies.

  Fix: use a scratch environment — `e <- new.env(); assign(obj_name, dat, envir = e);
  save(list = obj_name, envir = e, file = ...)` — and drop the `rm()` entirely.
  - **Rule:** none

---

- **[fragile]** `R/bag_bcdc_index.R:77-79` — the exact `pluck()` → `bind_rows()` → missing
  column defect that `.bag_bcdc_schtab()` was rewritten to prevent is still present one
  block below it, for `description`.

  `R/bag_bcdc_schtab.R:28-36` documents the mechanism and guards against it:

  > *"`pluck()` returns NULL for a missing element, and `tibble()` drops a NULL column
  > rather than erroring … It only bites when EVERY package lacks object_name:
  > `bind_rows()` yields no such column at all, and the `mutate()` that lower-cases it
  > fails."*

  `id_description` has the same shape and no guard:

  ```r
  id_description <- l |>
    purrr::map(~ list(id_package = purrr::pluck(.x, "id"),
                      description = purrr::pluck(.x, "notes"))) |>
    dplyr::bind_rows(.id = "package_name")
  ```

  `list(description = NULL)` drops the element, so if every surviving package has a NULL
  `notes` the column never exists and the `dplyr::select(..., description, ...)` at line
  97 aborts. Confirmed:

  ```
  # A tibble: 2 x 2 — package_name, id_package     (no `description`)
  select(description) -> ERROR: Can't select columns that don't exist.
  ```

  Reachability is the same order of improbability as the case they fixed (it needs *every*
  package to lack `notes`), which is the argument for fixing both or neither. Same remedy:
  `%||% NA_character_` on each `pluck()`.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness" ; code-check.md "Zero-length, empty, and unset are three different things"

---

- **[fragile]** `R/bag_gpkg_refresh.R:86-93` — **round-1 fix #4's guard is wider than the
  hazard it names**, in two ways, and the second makes the function unusable on the file
  type it is written for.

  (a) The guard is **unconditional**, while its own justification is conditional:

  > *"Writing back replaces the whole GeoPackage, so the others would be lost."*

  Nothing is written back unless `write_back_to_path = TRUE`, which defaults to `FALSE`.
  The function's own `@examples` block passes `write_to_csv = FALSE, write_to_rdata =
  FALSE, return_object = TRUE` — it writes nothing at all — and is still refused on any
  multi-layer source. `test-bag_gpkg_refresh.R:241-244` pins that refusal with
  `write_back_to_path` at its default, so the breadth is deliberate; naming it anyway
  because the documented example is now one of the calls it refuses.

  (b) The count is GDAL's layer list, which includes **QGIS's `layer_styles`** support
  table. Measured: a single-layer form carrying a `layer_styles` table that is *not*
  registered in `gpkg_contents` still lists as a layer —

  ```
  st_layers()$name -> "sites" "layer_styles"
  ERROR: `path_gpkg` must hold exactly one layer.
         ... holds 2: "sites" and "layer_styles".
  ```

  — so a QGIS/Mergin field form with a style saved into the GeoPackage (the documented use
  case, `form_fiss_site_2026.gpkg`) cannot be refreshed at all, by any argument
  combination. The refusal is in the safe direction for `write_back_to_path = TRUE`
  (`delete_dsn` really would destroy that table), which is what makes (a) the load-bearing
  half: moving the guard inside `if (write_back_to_path)` fixes both, since the read path
  needs only `layer =` to be explicit, which it already is.

  Worth noting while the guard is being narrowed: `delete_dsn = TRUE` also destroys
  GeoPackage content that is *not* a layer and therefore invisible to this count —
  `gpkg_metadata`, `gpkg_metadata_reference`. A guard counting layers cannot see those.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

---

- **[fragile]** `R/bag_assign_utm.R:55-61` — the warning states as fact something that is
  false whenever only one of the two columns is absent, and the test that covers it is
  structurally blind to the claim.

  The predicate is an `OR`; the message is an `AND`:

  ```r
  if (!col_easting %in% names(dat) || !col_northing %in% names(dat)) {
    cli::cli_warn(c(
      "{.arg col_easting} and {.arg col_northing} are not columns of {.arg dat}.",
  ```

  Measured, with `easting` present and `col_northing = "north_m"` absent:

  ```
  `col_easting` and `col_northing` are not columns of `dat`.
  ℹ Looking for easting and north_m.
  easting IS a column of dat: TRUE
  ```

  A caller who typo'd one argument is told both are wrong, and the remedy line ("Pass the
  existing names if that is not what you want") then points at the one that was already
  right. `test-bag_assign_utm.R:105-114` asserts only `expect_match(msg, "col_easting")`
  and `expect_match(msg, "easting")` — both interpolated values, which match the sentence
  whether or not the sentence is true — and `:116-125` covers only the both-present case,
  so the one-of-two case is untested in either direction.

  Fix: report the missing ones. Collect `missing <- c(col_easting,
  col_northing)[!c(col_easting, col_northing) %in% names(dat)]` and interpolate that, with
  its own `cli` quantity for the plural; then assert the rendered text for the
  one-absent case, not just the column name.
  - **Rule:** code-check.md "An assertion that matches an interpolated value cannot see the claim around it"

---

## Checked and clean (not findings)

Recorded so a later round need not redo them.

- **Round-1 fix #9** (`bag_bcdc_read()`'s not-found hint) is correct. Rendered through the
  real `cli_abort()` at every combination of `col_filter`/`col_extract` and at both
  `n = 1` and `n = 2`: `"is a column of the record"` / `"are columns of the record"`,
  never `"a columns"`. Each `i =` bullet carries its own quantity, which is what
  code-check.md's bullet-scope rule requires.
- **Every other `cli` pluralisation marker in the diff** has its quantity substituted
  immediately before it: `bag_bcdc_index.R:108` (`{nrow(pkgs)} … package{?s}
  publish{?es/}` renders "1 … package publishes" / "2 … packages publish") and
  `bag_gpkg_to_geojson.R:78` (`{length(paths_out)} layer{?s}`). No `qty()` is misplaced.
- **Round-1 fix #6/#7** (CRS object rather than `$epsg`; `epsg` as a local): verified. A
  proj-string CRS round trips, and a caller's own `epsg` column survives untouched.
- **`bag_assign_utm()` / `bag_sf_from_utm()` column order** is identical between the
  zero-row and non-zero-row paths, in both functions — the shared `bind_rows()` holds.
- **`bag_sf_from_utm()` degenerate inputs** all fail loudly rather than silently: an `NA`
  zone and an out-of-range zone both abort in `st_transform.sfc()` ("cannot transform sfc
  object with missing crs"); an `NA` easting aborts in `st_as_sf.data.frame()` ("missing
  values in coordinates not allowed"). None reaches the `bag_assign_utm` failure above,
  because `group_split()` gives `NA` its own group where a logical subscript does not.
- **`bcdata::filter()` translation**: both call sites comply with
  code-check-spatial.md's rule. `bag_bcdc_read()` passes `col_filter_value` as a plain
  local variable ("a plain local variable translates fine"), and `bag_bcdc()` transforms
  `mask` one statement *before* `filter(INTERSECTS(mask))`.
- **`system2()` quoting** (`bag_url.R:273`): `shQuote(args)` with `stdout = FALSE` and the
  status read off the return value — the shape code-check.md's "A wrapper's exit is not
  the work" prescribes. Verified `-where "code in ('ADMS')"` survives and filters.
- **`on.exit()` accumulation** in `bag_url()` and `.bag_source_resolve()` is correct: the
  caller registers `tmp_files` once over an accumulating vector, and the raw download is
  unlinked by the resolver's own frame while the re-encoded copy it returns is the one the
  caller cleans up.
- **Roxygen block binding**: `R/bag_url.R` holds five helpers after the exported function,
  each with its own block and nothing orphaned. `NAMESPACE` carries exactly 14 `export()`
  lines and `_pkgdown.yml`'s four `has_concept()` groups cover all 14 (`download` 3,
  `catalogue` 4, `files` 4, `coordinates` 3).
- **Package dependency hygiene**: `tools:::.check_package_depends()` and
  `tools:::.check_packages_used()` both return clean, so the undeclared-looking
  `importFrom(tools, …)` / `importFrom(utils, tail)` are fine. Every `pkg::` reached from
  `tests/` (`mockery`, `testthat`, `withr`) is declared in `Suggests`.
- **`.Rbuildignore`**: dropping `^vignettes/articles$` is harmless — `vignettes/` no
  longer exists. `inst/extdata/poly.gpkg`, the one surviving fixture, is still used
  (`test-bag_gpkg_to_geojson.R`).
- **`.bag_url_args(update = )`** has both the cold (`FALSE`, file absent) and warm
  (`TRUE`, file present) paths asserted at the builder level.
- **Aspatial GeoPackage layers** pass through `bag_layers()` and `bag_gpkg_to_geojson()`
  without error (`geomtype` `NA`, one `.geojson` written).
- **`bag_backup()`** handles an extensionless source correctly (`README_202601011200`, no
  trailing dot) and fails loudly, not silently, when `path_in_file` carries a
  subdirectory.
