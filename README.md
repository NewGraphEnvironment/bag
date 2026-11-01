
<!-- README.md is generated from README.Rmd. Please edit that file -->

# bag <img src="man/figures/logo.png" align="right" height="139" alt="bag hex sticker" />

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/NewGraphEnvironment/bag/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/NewGraphEnvironment/bag/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

bag fetches public spatial data and field files, and puts them on disk
where the rest of your work can reach them: a layer behind a URL, a BC
Data Catalogue record, a GeoServer WFS endpoint, or the GPX files on a
GPS unit back from the field. It then does the small jobs that follow —
convert a GeoPackage to GeoJSON, list what a data source holds, back a
file up before you change it, and move point data between geometry and
UTM or latitude/longitude columns.

The point is reproducibility. A fish-passage assessment or a restoration
design rests on data somebody downloaded once; a script that fetches it
again, to a named path, with the coordinate columns regenerated from the
geometry rather than typed, is the difference between a report you can
rebuild next year and one you cannot.

Functions change between releases while the package is experimental —
see
[`NEWS.md`](https://github.com/NewGraphEnvironment/bag/blob/main/NEWS.md),
and pin a release if you need one to hold still.

## Installation

``` r
# install.packages("pak")
pak::pkg_install("NewGraphEnvironment/bag")

# or pin a release
pak::pkg_install("NewGraphEnvironment/bag@v0.5.0")
```

## What it looks like

Ask a data source what it holds, before reading any of it:

``` r
library(bag)

gpkg <- system.file("extdata", "poly.gpkg", package = "bag")

# it also returns each layer's full CRS, which is a WKT block -- trimmed here
bag_layers(gpkg)[, c("name", "geomtype", "features", "fields")]
#>   name geomtype features fields
#> 1 poly  POLYGON        5      3
```

Write the UTM zone, easting and northing a field form expects, derived
from the geometry rather than typed in. Rows come back ordered by zone.
The fourth site below was entered before the GPS had a fix, so it has no
geometry — it keeps its attributes and gets `NA` coordinates rather than
being dropped. Both warnings are the function saying what it did:

``` r
sites <- sf::st_sf(
  site = c("skeena", "bulkley", "peace", "no_fix_yet"),
  geometry = sf::st_sfc(
    sf::st_point(c(-128.5, 54.5)),
    sf::st_point(c(-126.9, 54.8)),
    sf::st_point(c(-121.3, 56.2)),
    sf::st_point(),
    crs = 4326
  )
)

bag_assign_utm(sites)
#> Warning: `col_easting` and `col_northing` do not name columns of `dat`.
#> ℹ Looking for easting and northing.
#> ℹ They will be created. Pass the existing names if that is not what you want.
#> Warning: 1 row of `dat` has no usable coordinates.
#> ℹ Its utm_zone, easting, and northing are NA; every other column is kept.
#> ℹ An empty geometry, or an NA coordinate, does this.
#> Simple feature collection with 4 features and 4 fields (with 1 geometry empty)
#> Geometry type: POINT
#> Dimension:     XY
#> Bounding box:  xmin: -128.5 ymin: 54.5 xmax: -121.3 ymax: 56.2
#> Geodetic CRS:  WGS 84
#>         site utm_zone easting northing            geometry
#> 1     skeena        9  532381  6039269 POINT (-128.5 54.5)
#> 2    bulkley        9  634991  6074558 POINT (-126.9 54.8)
#> 3      peace       10  605471  6229640 POINT (-121.3 56.2)
#> 4 no_fix_yet       NA      NA       NA         POINT EMPTY
```

Fetching is the other half, and it needs the network, so it is not run
here:

``` r
# a layer from the BC Data Catalogue, clipped to a mask, straight to a GeoPackage
bag_bcdc(
  bcdata_record_id = "pscis-assessments",
  path_gpkg = "data/pscis.gpkg",
  mask = aoi
)

# anything GDAL can open behind a URL
bag_url(
  urls = "https://example.org/layers/streams.geojson",
  path_gpkg = "data/streams.gpkg"
)

# the GPX files on a GPS unit, into one GeoPackage
bag_gpx_import(
  dir_out = "data/gps",
  layer_output_name = "2026_field",
  gpkg_name = "gps_2026"
)
```

## Learn more

Every exported function is documented with a runnable example at
<http://www.newgraphenvironment.com/bag/reference/>. The reference index
is grouped by what the function is for: fetching, the BC Data Catalogue,
files, and coordinates.

## Ecosystem

bag is one of several small R packages New Graph Environment builds its
reporting on. [`fwapg`](https://github.com/smnorris/fwapg) and the BC
Data Catalogue are where most of the data it fetches comes from.

## Citation

``` r
citation("bag")
```

The package is archived on Zenodo, and the DOI in `DESCRIPTION` resolves
to the record.

## License

MIT © New Graph Environment Ltd.
