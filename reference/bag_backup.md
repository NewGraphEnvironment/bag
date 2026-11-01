# Back up a file, with an optional timestamp

Copies a file into a backup directory, appending a stamp to the name so
successive backups sit alongside each other rather than replacing one
another.

## Usage

``` r
bag_backup(
  path_dir_in,
  path_in_file,
  path_dir_out,
  stamp = format(Sys.time(), "%Y%m%d%H%M")
)
```

## Arguments

- path_dir_in:

  [character](https://rdrr.io/r/base/character.html) Directory holding
  the file.

- path_in_file:

  [character](https://rdrr.io/r/base/character.html) Name of the file,
  within `path_dir_in`.

- path_dir_out:

  [character](https://rdrr.io/r/base/character.html) Directory to copy
  into. Created if absent.

- stamp:

  [character](https://rdrr.io/r/base/character.html) Appended to the
  file's base name, before the extension. Defaults to the current time
  as `YYYYMMDDHHMM`. `NULL` appends nothing, which means the backup
  collides with any earlier one of the same name.

## Value

[character](https://rdrr.io/r/base/character.html) The path written,
invisibly.

## See also

[`bag_gpkg_refresh()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_refresh.md)
for a GeoPackage whose coordinate columns are refreshed as well, with
csv and RData copies alongside.

Other files:
[`bag_gpkg_refresh()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_refresh.md),
[`bag_gpkg_to_geojson()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_to_geojson.md),
[`bag_layers()`](http://www.newgraphenvironment.com/bag/reference/bag_layers.md)

## Examples

``` r
if (FALSE) { # \dontrun{
bag_backup(
  path_dir_in = file.path(tempdir(), "my_project"),
  path_in_file = "background_layers.gpkg",
  path_dir_out = file.path(tempdir(), "backups")
)
} # }
```
