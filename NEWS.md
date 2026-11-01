# bag 0.5.0

**The package is renamed from spacehakr to bag, every exported function is renamed with
it, and ten functions are gone.** Nothing written against `spacehakr 0.4.2` keeps working.
Install `NewGraphEnvironment/spacehakr@v0.4.2` for the old package — the tag still
resolves through GitHub's repository redirect.

The subject is now one thing: fetching public data and field files to disk.

## The name

`spacehakr` described a grab-bag of spatial helpers. The package no longer is one, so the
name no longer described it. `bag` is what it does — it fetches things and puts them
somewhere.

The old pkgdown site at `www.newgraphenvironment.com/spacehakr/` goes dark. GitHub
redirects repository URLs but not Pages paths. The site is now
`www.newgraphenvironment.com/bag/`.

## Functions that stayed, renamed

| spacehakr 0.4.2 | bag 0.5.0 |
|---|---|
| `spk_source_url()` | `bag_url()` |
| `spk_source_bcdata()` | `bag_bcdc()` |
| `spk_geoserv_dlv()` | `bag_wfs()` |
| `spk_layer_info()` | `bag_layers()` |

## Functions removed

`spk_gdalwarp()`, `spk_join()`, `spk_odm()`, `spk_poly_to_points()`, `spk_q_layer_info()`,
`spk_rast_ext()`, `spk_rast_not_empty()`, `spk_rast_rm_empty()`, `spk_res()` and
`spk_stac_calc()`. These were raster, drone-imagery and STAC helpers — a different subject
— and nothing called them under these names.

**`ngr` exports its own independent copies of all ten and does not depend on this
package**, so code calling `ngr_spk_*` is unaffected. That is where this family came from
and where it remains.

The two pkgdown articles went with them: both documented only `spk_stac_calc()`.

## Functions added

Ten. Eleven were taken in from two older first-party packages whose subject is
reporting rather than fetching; one of those, a GeoPackage layer remover, was then
dropped again (below).

**Nothing calling the old names breaks**, because those packages still hold their own
copies of these functions — they are not forwarders yet. Adding deprecating forwarders,
so the two do not drift apart, is tracked in each of them.

- **BC Data Catalogue:** `bag_bcdc_read()` reads a record into memory, `bag_bcdc_index()`
  builds a lookup of every catalogue layer with a WMS resource, `bag_bcdc_cols()`
  describes one column.
- **Files:** `bag_gpx_import()` reads a GPS unit's GPX files into a GeoPackage,
  `bag_gpkg_to_geojson()` writes each layer of a GeoPackage out as GeoJSON,
  `bag_backup()` copies a file into a backup directory with a timestamp, and
  `bag_gpkg_refresh()` refreshes a point GeoPackage's coordinate columns.
- **Coordinates:** `bag_assign_utm()` and `bag_assign_latlong()` write coordinate columns
  onto an `sf` object; `bag_sf_from_utm()` builds an `sf` object from UTM columns.

Nine defects were found and fixed while porting these, and each was reported to the
package it came from. Among them: a geometry guard that could never fire, written as
`!x != y` where `!` binds looser than `!=`; a GPX timestamp filter that compared a UTC
instant against a machine-local one; and a GeoPackage layer remover with a data-loss path,
which was then dropped from this package altogether as superseded upstream.

## Other changes

- `magrittr` is not a dependency. The donated functions arrived with magrittr pipelines
  and were rewritten to the native pipe.
- **Dependencies.** `Imports` is 15, from 14: `terra` and `xml2` went with the deleted
  helpers, and `janitor`, `lubridate` and `readr` arrived with the intake. `Suggests` is
  5, from 12: `grDevices`, `kableExtra`, `knitr`, `leafem`, `leaflet`, `mapview`,
  `processx`, `rmarkdown`, `rstac` and `stars` were all there for the deleted functions
  and their articles, and `DBI` and `RSQLite` arrived for the GeoPackage fixtures the
  new tests build.
- The pkgdown reference index is grouped by `@family`, so it now fails the build when an
  export is missing from it. It previously had no `reference:` section at all, which made
  `pkgdown::check_pkgdown()` vacuous.
- The package has a `.lintr` config for the first time. `lintr::lint_package()` is clean.
- `R CMD check` is 0 errors, 0 warnings, 0 notes.

# spacehakr 0.4.2

No change to the package's functions.

- `Config/DOI` in `DESCRIPTION` carries the package's Zenodo concept DOI, so a citation of spacehakr can name the archived record.

# spacehakr 0.4.1

No change to the package's functions. This release exists so the package has a citable, archived version.

- **Citation.** The maintainer is the author, and New Graph Environment Ltd. the copyright holder and funder (`cph`, `fnd` in `Authors@R`) and the publisher in `CITATION.cff`. `citation("spacehakr")` and `knitr::write_bib()` give the entry the stable key `spacehakr`.
- `CITATION.cff` is regenerated from DESCRIPTION by the `update-citation-cff` workflow and is kept out of the build tarball.
- `LICENSE` names New Graph Environment Ltd. as the copyright holder.

# spacehakr 0.4.0

- **[spk_source_url()] silently failed on any URL containing `&`, which is every service
  endpoint.** `system2()` pastes its arguments into a command string and runs it through
  `sh`, quoting only the command itself — measured: `system2("echo", args = "a&b")` prints
  `a` and reports `sh: b: command not found`. A query-string URL was therefore split at
  each `&`, and the trailing `count=1` was read by `sh` as a successful variable
  assignment, so `ogr2ogr` reported **status 0 having written nothing**. Arguments are now
  shell-quoted at the point of invocation.

  The same gap was a **command-injection** vector, not only a correctness bug: a `;`,
  backtick or `$()` reaching `sh` inside a caller-supplied `urls` or `query` value would
  have executed. That matters wherever these values come from a config file or a layer
  catalog rather than from a literal in the calling script.

  This also restores `query`. The 0.3.0 note below says `shQuote()` was removed because
  `system2()` "does not go through a shell"; that is not correct, and a `-where` clause
  containing quotes and spaces has been dying with a shell syntax error (loudly, at least)
  ever since. A caller who worked around it by pre-quoting their query should remove that
  quoting.

- [spk_source_url()] gains `vsi`, choosing the GDAL virtual filesystem each URL is read
  through. `/vsicurl/` — still the default, so nothing changes for existing callers —
  probes a source with a `HEAD` request and reads it with HTTP range requests, which a
  service endpoint addressed by a query string typically supports neither of. Measured
  against a BC Geographic Warehouse WFS on GDAL 3.13.0: `HEAD` returns 404 and a `Range`
  request is answered with a full-body 200, so the open fails before any driver is tried,
  and forcing the driver does not help. `vsi = "curl_streaming"` reads with a single
  sequential `GET` and works. Until now the only way to avoid `/vsicurl/` was to supply
  an `encoding`, which is a statement about a source's character set rather than its
  transport — so a WFS endpoint could not be expressed at all.

- **Behaviour change:** [spk_source_url()] now requires `layer` when a URL carries a
  query string. The derived name was `tools::file_path_sans_ext(basename(url))`, which
  for a WFS `GetFeature` request is the entire query string. A caller who relied on the
  derived name for a query-string URL — a presigned object URL, say — must now pass
  `layer` explicitly.

- [spk_source_url()] no longer leaks temp files when given several URLs with an
  `encoding`. `on.exit()` was registered inside the loop, so all registrations resolved
  to the last value of the source path: the final temp file was unlinked once per URL
  and every earlier one survived for the life of the session. Measured at 2 of 3 leaked.

- [spk_source_url()] refuses `encoding` combined with a non-default `vsi`. An encoded
  source is downloaded and re-encoded before conversion, so it never reaches a virtual
  filesystem, and honouring one argument while silently dropping the other is what made
  `encoding` usable as a transport switch in the first place.

# spacehakr 0.3.0

- [spk_source_url()] now fails loudly. The `ogr2ogr` exit status was never checked, so a
  bad URL, a 404 or an unreadable source returned exactly what success returned, and a
  layer that was never written looked identical to one that was. `stderr` now goes to a
  file rather than being merged into a discarded value, and a non-zero status aborts
  naming the URL and the tail of the diagnostic.

- [spk_source_url()] gains `open_options`, `a_srs`, `t_srs`, `layer` and `encoding`. A
  non-spatial CSV carrying coordinate columns can now become a point layer
  (`-oo X_POSSIBLE_NAMES=`, `-a_srs`), a source that is not UTF-8 is fetched and
  re-encoded before conversion (GDAL's CSV driver has no encoding open option), and the
  layer name no longer has to be whatever the URL's file name happens to be.

- [spk_source_url()] creates the output GeoPackage when it does not exist, rather than
  requiring one to append to.

- **Behaviour change:** [spk_source_url()]'s `query` is no longer passed through
  `shQuote()`. `system2()` with an argument vector does not go through a shell, so the
  quotes were reaching `-where` literally and the filter is unlikely to have worked. A
  caller who compensated by pre-quoting their query should remove that quoting.

# spacehakr 0.2.0

- Add [spk_source_url()] and [spk_source_bcdata()], which fetch layers into a
  GeoPackage from an arbitrary URL and from the BC Data Catalogue respectively.
  Sourcing data from public endpoints is what a reader needs to regenerate a
  report's inputs, so these belong in a public package.

  [spk_source_url()] reads through GDAL's `/vsicurl/` virtual filesystem and takes an
  optional SQL `query` applied as `-where`. It subsumes a separate CSV-only fetcher
  that was byte-equivalent to it with the filter omitted, so there is one entry point
  rather than two.

  `bcdata` joins `Imports` for [spk_source_bcdata()].

- Adopt the two STAC articles from `ngr`. Both demonstrate `spk_stac_calc()`, so
  they follow the function here rather than documenting a deprecated shim on ngr's
  site. They live in `vignettes/articles/` — pkgdown builds them, `R CMD build`
  ignores them. As true vignettes they would have to build on all five check
  runners against the live Planetary Computer API.
- Exclude `.git` from the build. In a `git worktree` checkout `.git` is a *file* holding an absolute developer path, and `R CMD build` ships it (it is only excluded when it is a directory).

# spacehakr 0.1.0

First tagged release. Twelve spatial functions extracted from `ngr`'s `ngr_spk_*`
family — GDAL and OpenDroneMap command building, GeoServer WFS download, STAC
raster math, spatial joins and raster utilities. See the
[reference index](https://newgraphenvironment.github.io/spacehakr/reference/).

This release exists so `ngr` has a pinnable version to depend on while it
deprecates its own copies of these functions
([ngr#7](https://github.com/NewGraphEnvironment/ngr/issues/7)).

- Declare `rlang` in `Imports`. It was imported by `spk_join()` via
  `@importFrom rlang .data` but never declared, so `R CMD check` failed with
  `Namespace dependency missing from DESCRIPTION Imports/Depends entries`. This
  went unnoticed because the package had no `R-CMD-check` workflow.
- Add an `R-CMD-check` workflow, so the twelve test files run on every push
  rather than never.
- Guard the `gdalwarp` run in `test-spk_gdalwarp.R`. It shelled out to the GDAL
  CLI at file top level with no guard, which errors the whole file on any
  machine without it — including every GitHub runner. Now scoped to a
  `test_that()` block that skips when `gdalwarp` is not on `PATH`.
