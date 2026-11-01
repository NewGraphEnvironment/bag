# Write every layer of a GeoPackage out as GeoJSON

Reads each layer of a GeoPackage and writes it as its own `.geojson`
file. GeoJSON is convenient for mapping: QGIS picks up changes without a
restart, and GitHub and other web platforms render it directly.

## Usage

``` r
bag_gpkg_to_geojson(dir_in, dir_out, file_name_in)
```

## Arguments

- dir_in:

  [character](https://rdrr.io/r/base/character.html) Directory holding
  the GeoPackage.

- dir_out:

  [character](https://rdrr.io/r/base/character.html) Directory to write
  the GeoJSON files to. Created if absent.

- file_name_in:

  [character](https://rdrr.io/r/base/character.html) Name of the
  GeoPackage, without the `.gpkg` extension.

## Value

A [character](https://rdrr.io/r/base/character.html) vector of the files
written, invisibly.

## Details

**Every layer is transformed to WGS 84 (EPSG:4326) on the way out.** RFC
7946 defines GeoJSON as WGS 84 and removed the `crs` member, so a file
written in a projected CRS renders in the wrong place everywhere that
follows the RFC — GitHub's preview, Leaflet, Mapbox — while opening
correctly in QGIS, which still honours the member. BC Albers is the
usual CRS of a BC GeoPackage, which is exactly the case that would
break.

A layer with no usable CRS is therefore **refused**, and refused before
anything is written, so a GeoPackage is converted whole or not at all.
The check is not `is.na(sf::st_crs(x))`: GDAL's GeoPackage driver never
returns a missing CRS. The format reserves `srs_id` −1 for "undefined
Cartesian" and 0 for "undefined geographic", and both read back as real
CRS objects — the first cannot be transformed at all, and the second
would be silently taken for WGS 84.
[`sf::st_write()`](https://r-spatial.github.io/sf/reference/st_write.html)
itself produces the −1 case when handed an object whose CRS is `NA`.

## See also

[`bag_layers()`](http://www.newgraphenvironment.com/bag/reference/bag_layers.md)
for listing a data source's layers and geometry types.

Other files:
[`bag_backup()`](http://www.newgraphenvironment.com/bag/reference/bag_backup.md),
[`bag_gpkg_refresh()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_refresh.md),
[`bag_layers()`](http://www.newgraphenvironment.com/bag/reference/bag_layers.md)

## Examples

``` r
if (FALSE) { # \dontrun{
bag_gpkg_to_geojson(
  dir_in = "~/gps",
  dir_out = "~/gps/geojson",
  file_name_in = "gps_2026"
)
} # }
```
