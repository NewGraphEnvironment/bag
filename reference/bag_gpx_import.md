# Import GPX waypoints and tracks from a GPS mounted as a volume

Reads GPX files from one or more directories — typically a Garmin unit
mounted over USB — filters them to a time window, tags each feature's
name with a surveyor string so names from different units do not
collide, and writes the result as both GPX and a GeoPackage layer.

## Usage

``` r
bag_gpx_import(
  dir_gpx_waypoints = "/Volumes/GARMIN/Garmin/GPX/",
  dir_gpx_tracks = c("/Volumes/GARMIN/Garmin/GPX/Archive/",
    "/Volumes/GARMIN/Garmin/GPX/Current/"),
  dir_out,
  time_start = NULL,
  time_end = NULL,
  layer_output_name,
  gpkg_name,
  dates_view = FALSE,
  gpx_layer_type = c("waypoints", "tracks", "track_points")
)
```

## Arguments

- dir_gpx_waypoints:

  [character](https://rdrr.io/r/base/character.html) Directory holding
  the GPX waypoint files.

- dir_gpx_tracks:

  [character](https://rdrr.io/r/base/character.html) One or more
  directories holding the GPX track files.

- dir_out:

  [character](https://rdrr.io/r/base/character.html) Directory to write
  to. Created if absent. **Required.**

- time_start, time_end:

  [character](https://rdrr.io/r/base/character.html) Inclusive bounds on
  the waypoint creation time and on the end time of each track, as
  `"YYYY-MM-DD"` or `"YYYY-MM-DD HH:MM:SS"`. **Interpreted as UTC**,
  which is the zone GPX records times in. `NULL` (the default) applies
  no bound on that end.

- layer_output_name:

  [character](https://rdrr.io/r/base/character.html) Appended to every
  feature name and to each output layer name, so that names from
  different units or surveyors stay distinct — for example `"2026_ai"`.
  **Required.**

- gpkg_name:

  [character](https://rdrr.io/r/base/character.html) Base name of the
  output GeoPackage, without the extension. **Required.**

- dates_view:

  [logical](https://rdrr.io/r/base/logical.html) Print the available
  times and write nothing. Default `FALSE`.

- gpx_layer_type:

  [character](https://rdrr.io/r/base/character.html) Which GPX layers to
  read. One or more of `"waypoints"`, `"tracks"` and `"track_points"`.

## Value

`NULL`, invisibly. Called for the files it writes.

## Details

Set `dates_view = TRUE` to print the times available in the files and
write nothing. That is the way to choose `time_start` and `time_end`
without guessing.

## See also

Other download:
[`bag_url()`](http://www.newgraphenvironment.com/bag/reference/bag_url.md),
[`bag_wfs()`](http://www.newgraphenvironment.com/bag/reference/bag_wfs.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# see what is on the unit before choosing a window
bag_gpx_import(
  dir_out = "~/gps",
  layer_output_name = "2026_ai",
  gpkg_name = "gps_2026",
  dates_view = TRUE
)

bag_gpx_import(
  dir_out = "~/gps",
  layer_output_name = "2026_ai",
  gpkg_name = "gps_2026",
  time_start = "2026-01-01"
)
} # }
```
