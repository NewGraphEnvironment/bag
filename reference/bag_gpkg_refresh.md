# Refresh a single-layer point GeoPackage's coordinate columns

Reads a one-layer point GeoPackage, optionally refreshes its UTM columns
with
[`bag_assign_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_utm.md),
optionally applies a caller-supplied transformation, optionally writes
the result back over the GeoPackage, and writes `.csv` and `.RData`
backups.

## Usage

``` r
bag_gpkg_refresh(
  path_gpkg = NULL,
  dir_backup = "data/backup/",
  update_utm = TRUE,
  fn_site_id = NULL,
  write_back_to_path = FALSE,
  write_to_csv = TRUE,
  write_to_rdata = TRUE,
  return_object = FALSE,
  ...
)
```

## Arguments

- path_gpkg:

  [character](https://rdrr.io/r/base/character.html) Path to a
  GeoPackage holding exactly one point layer. More than one *spatial*
  layer is refused, since which to refresh would be decided by layer
  order. Support tables carrying no geometry — QGIS's `layer_styles`,
  for one — are not counted, and survive the write-back.

- dir_backup:

  [character](https://rdrr.io/r/base/character.html) Directory for the
  backups. Created if absent.

- update_utm:

  [logical](https://rdrr.io/r/base/logical.html) Refresh the UTM columns
  with
  [`bag_assign_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_utm.md).
  Default `TRUE`.

- fn_site_id:

  A function applied to the data after the UTM step, or `NULL` (default)
  to apply nothing. It is called as `fn_site_id(dat)` and must return
  the data.

  This is where the fish-passage package's site-id assignment is
  injected. That logic is about site identity rather than about files,
  so it stays in that package and is passed in rather than imported —
  neither package depends on the other.

- write_back_to_path:

  [logical](https://rdrr.io/r/base/logical.html) Overwrite the layer in
  `path_gpkg` with the result, keeping its name. Default `FALSE`. Only
  that layer is replaced, so a style saved into the GeoPackage is left
  alone.

- write_to_csv:

  [logical](https://rdrr.io/r/base/logical.html) Write a
  geometry-dropped `.csv` backup. Default `TRUE`.

- write_to_rdata:

  [logical](https://rdrr.io/r/base/logical.html) Write an `.RData`
  backup holding the object under the GeoPackage's base name. Default
  `TRUE`.

- return_object:

  [logical](https://rdrr.io/r/base/logical.html) Return the updated
  object. Default `FALSE`.

- ...:

  Passed to
  [`bag_assign_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_utm.md).

## Value

The updated `sf` object when `return_object` is `TRUE`, otherwise `NULL`
invisibly. Called for the files it writes.

## Details

It is named for the refresh rather than for the backups because
`write_back_to_path = TRUE` **overwrites `path_gpkg`**. The backups are
a side effect, not the contract.

Both backups exist on purpose. The `.csv` is the versionable one; the
`.RData` holds the object exactly, because rebuilding it from the csv
introduces small differences.

## See also

[`bag_backup()`](http://www.newgraphenvironment.com/bag/reference/bag_backup.md)
for a plain file copy, and
[`bag_assign_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_utm.md)
for the coordinate step.

Other files:
[`bag_backup()`](http://www.newgraphenvironment.com/bag/reference/bag_backup.md),
[`bag_gpkg_to_geojson()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_to_geojson.md),
[`bag_layers()`](http://www.newgraphenvironment.com/bag/reference/bag_layers.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# refresh the coordinate columns and hand the object back, writing nothing
updated <- bag_gpkg_refresh(
  path_gpkg = file.path(tempdir(), "form_fiss_site_2026.gpkg"),
  write_to_csv = FALSE,
  write_to_rdata = FALSE,
  return_object = TRUE,
  # passed through to bag_assign_utm()
  col_easting = "utm_easting",
  col_northing = "utm_northing",
  sig_dig = 3
)
} # }
```
