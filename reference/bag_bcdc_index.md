# Build a lookup table of BC Data Catalogue layers

Walks every BC Data Catalogue package that advertises a WMS resource and
returns one row per WMS layer, giving the `schema.table` object name a
download needs alongside the catalogue record it came from.

## Usage

``` r
bag_bcdc_index(pkg_exclude = c("bc-web-map-library"))
```

## Arguments

- pkg_exclude:

  [character](https://rdrr.io/r/base/character.html) Package names to
  exclude. Defaults to `"bc-web-map-library"`, which is associated with
  several datasets that have no WMS download capability.

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
with columns `object_name`, `package_name`, `url_browser`,
`description`, `id_package`, `id_dataset` and `url_download`.

## See also

[`bag_bcdc_cols()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_cols.md)
for the column descriptions of one layer, and
[`bag_bcdc_read()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_read.md)
to read a layer once its object name is known.

Other catalogue:
[`bag_bcdc()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc.md),
[`bag_bcdc_cols()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_cols.md),
[`bag_bcdc_read()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_read.md)

## Examples

``` r
if (FALSE) { # \dontrun{
lookup_table <- bag_bcdc_index()
head(lookup_table)
} # }
```
