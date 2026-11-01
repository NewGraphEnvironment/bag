# Read a BC Data Catalogue layer

A convenience wrapper on
[`bcdata::bcdc_query_geodata()`](https://bcgov.github.io/bcdata/reference/bcdc_query_geodata.html)
and
[`bcdata::collect()`](https://dplyr.tidyverse.org/reference/compute.html).
Queries a catalogue record, optionally filters it on one column,
optionally keeps only named columns, cleans the column names, and
optionally drops the geometry.

## Usage

``` r
bag_bcdc_read(
  bcdata_record_id,
  col_extract = NULL,
  drop_geom = FALSE,
  col_filter = NULL,
  col_filter_value = NULL
)
```

## Arguments

- bcdata_record_id:

  [character](https://rdrr.io/r/base/character.html) The catalogue
  record, given as its permanent id
  (`"7ecfafa6-5e18-48cd-8d9b-eae5b5ea2881"`), its record name
  (`"pscis-assessments"`) or its object name
  (`"WHSE_FISH.PSCIS_ASSESSMENT_SVW"`). Record names are listed at
  <https://catalogue.data.gov.bc.ca/>. Case is not significant: an id
  containing a `.` is upper-cased and one without is lower-cased.

- col_extract:

  [character](https://rdrr.io/r/base/character.html) Columns to keep.
  `NULL` (default) keeps all of them. Case is not significant.

- drop_geom:

  [logical](https://rdrr.io/r/base/logical.html) Drop the geometry
  column from the returned `sf` object. Default `FALSE`.

- col_filter:

  [character](https://rdrr.io/r/base/character.html) A single column to
  filter on. `NULL` (default) applies no filter. Case is not
  significant.

- col_filter_value:

  [character](https://rdrr.io/r/base/character.html) The values to keep
  in `col_filter`. Required when `col_filter` is given.

## Value

An `sf` object with cleaned names, or a
[tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
when `drop_geom` is `TRUE`.

## See also

[`bag_bcdc_index()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_index.md)
for finding a record's object name, and
[`bag_bcdc()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc.md)
to write a catalogue layer straight to a GeoPackage instead of returning
it.

Other catalogue:
[`bag_bcdc()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc.md),
[`bag_bcdc_cols()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_cols.md),
[`bag_bcdc_index()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_index.md)

## Examples

``` r
if (FALSE) { # \dontrun{
bag_bcdc_read(
  bcdata_record_id = "7ecfafa6-5e18-48cd-8d9b-eae5b5ea2881",
  col_filter = "FUNDING_PROJECT_NUMBER",
  col_filter_value = "skeena_2023_Phase1",
  col_extract = c("EXTERNAL_CROSSING_REFERENCE", "STREAM_CROSSING_ID"),
  drop_geom = TRUE
)

# every record, two columns
bag_bcdc_read(
  bcdata_record_id = "bc-airports",
  col_extract = c("AIRPORT_NAME", "DESCRIPTION")
)
} # }
```
