# Changelog

## bag 0.5.0

**The package is renamed from spacehakr to bag, every exported function
is renamed with it, and ten functions are gone.** Nothing written
against `spacehakr 0.4.2` keeps working. Install
`NewGraphEnvironment/spacehakr@v0.4.2` for the old package — the tag
still resolves through GitHub’s repository redirect.

The subject is now one thing: fetching public data and field files to
disk.

### The name

`spacehakr` described a grab-bag of spatial helpers. The package no
longer is one, so the name no longer described it. `bag` is what it does
— it fetches things and puts them somewhere.

The old pkgdown site at `www.newgraphenvironment.com/spacehakr/` goes
dark. GitHub redirects repository URLs but not Pages paths. The site is
now `www.newgraphenvironment.com/bag/`.

### Functions that stayed, renamed

| spacehakr 0.4.2 | bag 0.5.0 |
|----|----|
| `spk_source_url()` | [`bag_url()`](http://www.newgraphenvironment.com/bag/reference/bag_url.md) |
| `spk_source_bcdata()` | [`bag_bcdc()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc.md) |
| `spk_geoserv_dlv()` | [`bag_wfs()`](http://www.newgraphenvironment.com/bag/reference/bag_wfs.md) |
| `spk_layer_info()` | [`bag_layers()`](http://www.newgraphenvironment.com/bag/reference/bag_layers.md) |

### Functions removed

`spk_gdalwarp()`, `spk_join()`, `spk_odm()`, `spk_poly_to_points()`,
`spk_q_layer_info()`, `spk_rast_ext()`, `spk_rast_not_empty()`,
`spk_rast_rm_empty()`, `spk_res()` and `spk_stac_calc()`. These were
raster, drone-imagery and STAC helpers — a different subject — and
nothing called them under these names.

**`ngr` keeps serving all ten, and it is pinned so that it can.** Its
`ngr_spk_*` functions are deprecating forwarders whose bodies call
`spacehakr::spk_*()`, and it carries `spacehakr` in `Imports:`. So `ngr`
pins `NewGraphEnvironment/spacehakr@v0.4.2`, the last release before
this one, and keeps installing a package that still has them. Code
calling `ngr_spk_*` is unaffected.

Retiring those forwarders — re-pointing the two whose targets survive
here under new names, rehoming the four that have callers and no
successor, deleting the six that have neither — is tracked in `ngr`
rather than here.

The two pkgdown articles went with them: both documented only
`spk_stac_calc()`.

### Functions added

Ten. Eleven were taken in from two older first-party packages whose
subject is reporting rather than fetching; one of those, a GeoPackage
layer remover, was then dropped again (below).

**Nothing calling the old names breaks**, because those packages still
hold their own copies of these functions — they are not forwarders yet.
Adding deprecating forwarders, so the two do not drift apart, is tracked
in each of them.

- **BC Data Catalogue:**
  [`bag_bcdc_read()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_read.md)
  reads a record into memory,
  [`bag_bcdc_index()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_index.md)
  builds a lookup of every catalogue layer with a WMS resource,
  [`bag_bcdc_cols()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_cols.md)
  describes one column.
- **Files:**
  [`bag_gpx_import()`](http://www.newgraphenvironment.com/bag/reference/bag_gpx_import.md)
  reads a GPS unit’s GPX files into a GeoPackage,
  [`bag_gpkg_to_geojson()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_to_geojson.md)
  writes each layer of a GeoPackage out as GeoJSON,
  [`bag_backup()`](http://www.newgraphenvironment.com/bag/reference/bag_backup.md)
  copies a file into a backup directory with a timestamp, and
  [`bag_gpkg_refresh()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_refresh.md)
  refreshes a point GeoPackage’s coordinate columns.
- **Coordinates:**
  [`bag_assign_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_utm.md)
  and
  [`bag_assign_latlong()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_latlong.md)
  write coordinate columns onto an `sf` object;
  [`bag_sf_from_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_sf_from_utm.md)
  builds an `sf` object from UTM columns.

Nine defects were found and fixed while porting these, and each was
reported to the package it came from. Among them: a geometry guard that
could never fire, written as `!x != y` where `!` binds looser than `!=`;
a GPX timestamp filter that compared a UTC instant against a
machine-local one; and a GeoPackage layer remover with a data-loss path,
which was then dropped from this package altogether as superseded
upstream.

### Other changes

- `magrittr` is not a dependency. The donated functions arrived with
  magrittr pipelines and were rewritten to the native pipe.
- **Dependencies.** `Imports` is 15, from 14: `terra` and `xml2` went
  with the deleted helpers, and `janitor`, `lubridate` and `readr`
  arrived with the intake. `Suggests` is 5, from 12: `grDevices`,
  `kableExtra`, `knitr`, `leafem`, `leaflet`, `mapview`, `processx`,
  `rmarkdown`, `rstac` and `stars` were all there for the deleted
  functions and their articles, and `DBI` and `RSQLite` arrived for the
  GeoPackage fixtures the new tests build.
- The pkgdown reference index is grouped by `@family`, so it now fails
  the build when an export is missing from it. It previously had no
  `reference:` section at all, which made
  [`pkgdown::check_pkgdown()`](https://pkgdown.r-lib.org/reference/check_pkgdown.html)
  vacuous.
- The package has a `.lintr` config for the first time.
  `lintr::lint_package()` is clean.
- `R CMD check` is 0 errors, 0 warnings, 0 notes.
