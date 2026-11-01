# Assign latitude and longitude columns to an sf point object

Transforms the object to WGS 84, reads off latitude and longitude as
columns, and transforms back to the input CRS.

## Usage

``` r
bag_assign_latlong(dat = NULL, col_lat = "lat", col_lon = "lon")
```

## Arguments

- dat:

  An `sf` data frame of `POINT` geometry.

- col_lat:

  [character](https://rdrr.io/r/base/character.html) Name of the column
  to hold the latitude.

- col_lon:

  [character](https://rdrr.io/r/base/character.html) Name of the column
  to hold the longitude.

## Value

An `sf` data frame in the input CRS, with latitude and longitude columns
appended.

## See also

[`bag_assign_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_utm.md)
for UTM zone, easting and northing.

Other coordinates:
[`bag_assign_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_utm.md),
[`bag_sf_from_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_sf_from_utm.md)

## Examples

``` r
sf_df <- data.frame(lon = -128.5, lat = 54.5) |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
  sf::st_transform(3005)

bag_assign_latlong(sf_df, col_lon = "long")
#> Simple feature collection with 1 feature and 2 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 838509.3 ymin: 1058270 xmax: 838509.3 ymax: 1058270
#> Projected CRS: NAD83 / BC Albers
#>                   geometry   long  lat
#> 1 POINT (838509.3 1058270) -128.5 54.5
```
