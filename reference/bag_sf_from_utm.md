# Build an sf object from NAD 83 UTM zone, easting and northing columns

Groups a plain data frame by its UTM zone column, promotes each group to
`sf` in that zone's projected CRS, transforms every group to one
geographic CRS, and binds them back together.

## Usage

``` r
bag_sf_from_utm(
  dat = NULL,
  col_utm_zone = "utm_zone",
  col_easting = "easting",
  col_northing = "northing",
  crs_return = 3005
)
```

## Arguments

- dat:

  A data frame carrying UTM zone, easting and northing columns.

- col_utm_zone:

  [character](https://rdrr.io/r/base/character.html) Name of the UTM
  zone column.

- col_easting:

  [character](https://rdrr.io/r/base/character.html) Name of the easting
  column.

- col_northing:

  [character](https://rdrr.io/r/base/character.html) Name of the
  northing column.

- crs_return:

  [numeric](https://rdrr.io/r/base/numeric.html) EPSG code to return in.
  Must be valid across every zone present — not a single UTM zone's CRS.
  Default 3005 (BC Albers).

## Value

An `sf` data frame in `crs_return`, ordered by UTM zone.

## Details

`crs_return` must be a CRS that is valid across every zone in the data —
BC Albers (3005, the default) or WGS 84 (4326), rather than one UTM
zone's own CRS, because a point from zone 9 expressed in zone 11's CRS
is simply wrong. An earlier version of this sentence said "must be
geographic", which excluded its own default: BC Albers is projected. The
property that matters is province-wide validity, not geographic versus
projected, and it is not something the function can check — a UTM
`crs_return` is accepted and gives silently wrong coordinates for every
zone but one.

## See also

[`bag_assign_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_utm.md)
to write those columns onto an `sf` object. The two are not inverses:
that one returns its input's CRS and keeps the `geometry` column, this
one returns `crs_return` and names the geometry column `geom`.

Other coordinates:
[`bag_assign_latlong()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_latlong.md),
[`bag_assign_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_utm.md)

## Examples

``` r
sites <- data.frame(
  site = c("a", "b"),
  utm_zone = c(9, 10),
  easting = c(532381, 605471),
  northing = c(6039269, 6229640)
)

bag_sf_from_utm(sites)
#> Simple feature collection with 2 features and 4 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: 838509.7 ymin: 1058269 xmax: 1290854 ymax: 1254828
#> Projected CRS: NAD83 / BC Albers
#> # A tibble: 2 × 5
#>   site  utm_zone easting northing               geom
#> * <chr>    <dbl>   <dbl>    <dbl>        <POINT [m]>
#> 1 a            9  532381  6039269 (838509.7 1058269)
#> 2 b           10  605471  6229640  (1290854 1254828)
```
