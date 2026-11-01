# Summarise Layers and Geometry Types in a Spatial Data Source

Extracts and summarises information about layers within a spatial vector
data source. Attempts to determine the geometry type of each layer by
querying a sample feature.

## Usage

``` r
bag_layers(path)
```

## Arguments

- path:

  [character](https://rdrr.io/r/base/character.html) A single string.
  Path to the vector spatial data source (e.g., a GeoPackage or
  shapefile).

## Value

[data.frame](https://rdrr.io/r/base/data.frame.html) A data frame of
available layers and their geometry types. If a layer contains no
geometry, or an error occurs during reading, the `geomtype` will be
`NA`.

## Details

Uses
[`sf::st_layers()`](https://r-spatial.github.io/sf/reference/st_layers.html)
to list available layers in the data source. For each layer, attempts to
read a single feature using an SQL query and determines the geometry
type using
[`sf::st_geometry_type()`](https://r-spatial.github.io/sf/reference/st_geometry_type.html).
Layers with no geometry or errors in reading are safely assigned `NA`.
The `driver` column is removed from the output as it may contain invalid
entries for further data frame operations.

## See also

[`sf::st_layers()`](https://r-spatial.github.io/sf/reference/st_layers.html),
[`sf::st_read()`](https://r-spatial.github.io/sf/reference/st_read.html),
[`sf::st_geometry_type()`](https://r-spatial.github.io/sf/reference/st_geometry_type.html)

Other files:
[`bag_backup()`](http://www.newgraphenvironment.com/bag/reference/bag_backup.md),
[`bag_gpkg_refresh()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_refresh.md),
[`bag_gpkg_to_geojson()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_to_geojson.md)

## Examples

``` r
# Get layer information from a GeoPackage
layer_info <- bag_layers(
  system.file("extdata", "poly.gpkg", package = "bag")
)
```
