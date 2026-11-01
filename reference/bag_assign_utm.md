# Assign UTM zone, easting and northing to an sf point object

Derives the NAD 83 UTM zone from each point's longitude, transforms each
zone's points to that zone's projected CRS to read off easting and
northing, and returns the object in its original CRS with those three
columns written in.

## Usage

``` r
bag_assign_utm(
  dat = NULL,
  col_zone = "utm_zone",
  col_easting = "easting",
  col_northing = "northing",
  sig_dig = 0
)
```

## Arguments

- dat:

  An `sf` data frame of `POINT` geometry.

- col_zone:

  [character](https://rdrr.io/r/base/character.html) Name of the column
  to hold the UTM zone.

- col_easting:

  [character](https://rdrr.io/r/base/character.html) Name of the column
  to hold the easting.

- col_northing:

  [character](https://rdrr.io/r/base/character.html) Name of the column
  to hold the northing.

- sig_dig:

  [numeric](https://rdrr.io/r/base/numeric.html) Digits to round easting
  and northing to.

## Value

An `sf` data frame in the input CRS, with the zone, easting and northing
columns assigned.

## Details

Rows come back **ordered by UTM zone**, not in their input order. That
is the donor's behaviour and is relied on by the files its callers write
back.

## See also

[`bag_sf_from_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_sf_from_utm.md)
to build an `sf` object from such columns — not an inverse of this
function, which returns the input CRS where that one returns
`crs_return` — and
[`bag_assign_latlong()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_latlong.md)
for latitude and longitude columns.

Other coordinates:
[`bag_assign_latlong()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_latlong.md),
[`bag_sf_from_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_sf_from_utm.md)

## Examples

``` r
sf_df <- data.frame(
  lon = c(-128.5, -123.5, -118.5), # UTM zones 9, 10 and 11
  lat = c(45.5, 45.5, 45.5)
) |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)

bag_assign_utm(dat = sf_df)
#> Warning: `col_easting` and `col_northing` do not name columns of `dat`.
#> ℹ Looking for easting and northing.
#> ℹ They will be created. Pass the existing names if that is not what you want.
#> Simple feature collection with 3 features and 3 fields
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -128.5 ymin: 45.5 xmax: -118.5 ymax: 45.5
#> Geodetic CRS:  WGS 84
#>   utm_zone easting northing            geometry
#> 1        9  539063  5038618 POINT (-128.5 45.5)
#> 2       10  460937  5038618 POINT (-123.5 45.5)
#> 3       11  382810  5039591 POINT (-118.5 45.5)
```
