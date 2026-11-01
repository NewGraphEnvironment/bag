# Describe one column of a BC Data Catalogue layer

Checks that a `schema.table` and column exist in the BC Data Catalogue
WMS service and returns the catalogue's own description of that column.

## Usage

``` r
bag_bcdc_cols(schema_table, column)
```

## Arguments

- schema_table:

  [character](https://rdrr.io/r/base/character.html) The object name of
  the layer, as `schema.table` — for example
  `"whse_imagery_and_base_maps.gsr_airports_svw"`. Case is not
  significant; it is upper-cased before the query.

- column:

  [character](https://rdrr.io/r/base/character.html) The column to
  describe. Case is not significant.

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
with the `schema_table` as given, the column name, its local R type and
the catalogue's column comments. Zero rows when the column does not
exist in the layer.

## See also

[`bag_bcdc_index()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_index.md)
for the layer lookup this complements.

Other catalogue:
[`bag_bcdc()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc.md),
[`bag_bcdc_index()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_index.md),
[`bag_bcdc_read()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_read.md)

## Examples

``` r
if (FALSE) { # \dontrun{
bag_bcdc_cols(
  "whse_imagery_and_base_maps.gsr_airports_svw",
  "airport_name"
)
} # }
```
