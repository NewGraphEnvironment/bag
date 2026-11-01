#' Import GPX waypoints and tracks from a GPS mounted as a volume
#'
#' Reads GPX files from one or more directories — typically a Garmin unit mounted over
#' USB — filters them to a time window, tags each feature's name with a surveyor string so
#' names from different units do not collide, and writes the result as both GPX and a
#' GeoPackage layer.
#'
#' Set `dates_view = TRUE` to print the times available in the files and write nothing.
#' That is the way to choose `time_start` and `time_end` without guessing.
#'
#' @param dir_gpx_waypoints [character] Directory holding the GPX waypoint files.
#' @param dir_gpx_tracks [character] One or more directories holding the GPX track files.
#' @param dir_out [character] Directory to write to. Created if absent. **Required.**
#' @param time_start,time_end [character] Inclusive bounds on the waypoint creation time
#'   and on the end time of each track, as `"YYYY-MM-DD"` or
#'   `"YYYY-MM-DD HH:MM:SS"`. **Interpreted as UTC**, which is the zone GPX records times
#'   in. `NULL` (the default) applies no bound on that end.
#' @param layer_output_name [character] Appended to every feature name and to each output
#'   layer name, so that names from different units or surveyors stay distinct — for
#'   example `"2026_ai"`. **Required.**
#' @param gpkg_name [character] Base name of the output GeoPackage, without the extension.
#'   **Required.**
#' @param dates_view [logical] Print the available times and write nothing. Default
#'   `FALSE`.
#' @param gpx_layer_type [character] Which GPX layers to read. One or more of
#'   `"waypoints"`, `"tracks"` and `"track_points"`.
#'
#' @return `NULL`, invisibly. Called for the files it writes.
#'
#' @family files
#' @export
#'
#' @importFrom chk chk_character chk_flag chk_string
#' @importFrom cli cli_abort cli_alert_info
#' @importFrom dplyr arrange bind_rows filter mutate pull
#' @importFrom fs dir_create dir_ls path
#' @importFrom lubridate ymd_hms
#' @importFrom purrr map
#' @importFrom rlang .data
#' @importFrom sf st_read st_write
#'
#' @examples
#' \dontrun{
#' # see what is on the unit before choosing a window
#' bag_gpx_import(
#'   dir_out = "~/gps",
#'   layer_output_name = "2026_ai",
#'   gpkg_name = "gps_2026",
#'   dates_view = TRUE
#' )
#'
#' bag_gpx_import(
#'   dir_out = "~/gps",
#'   layer_output_name = "2026_ai",
#'   gpkg_name = "gps_2026",
#'   time_start = "2026-01-01"
#' )
#' }
bag_gpx_import <- function(dir_gpx_waypoints = "/Volumes/GARMIN/Garmin/GPX/",
                           dir_gpx_tracks = c(
                             "/Volumes/GARMIN/Garmin/GPX/Archive/",
                             "/Volumes/GARMIN/Garmin/GPX/Current/"
                           ),
                           dir_out,
                           time_start = NULL,
                           time_end = NULL,
                           layer_output_name,
                           gpkg_name,
                           dates_view = FALSE,
                           gpx_layer_type = c("waypoints", "tracks", "track_points")) {

  chk::chk_string(dir_gpx_waypoints)
  chk::chk_character(dir_gpx_tracks)
  chk::chk_string(dir_out)
  chk::chk_string(layer_output_name)
  chk::chk_string(gpkg_name)
  chk::chk_flag(dates_view)
  chk::chk_character(gpx_layer_type)

  valid_layers <- c("waypoints", "tracks", "track_points")
  if (!all(gpx_layer_type %in% valid_layers)) {
    cli::cli_abort(c(
      "Invalid {.arg gpx_layer_type}.",
      i = "Allowed values are {.val {valid_layers}}."
    ))
  }

  # Parsed to an explicit UTC instant rather than left to the comparison. The donor
  # compared a POSIXct `time` column against these as bare strings, so R coerced them in
  # the machine's zone: the same call filtered to a boundary 8 hours apart on a Vancouver
  # machine and a UTC one. GPX records times in UTC, so that is the zone to read them in.
  parse_bound <- function(x, arg) {
    if (is.null(x)) return(NULL)
    chk::chk_string(x)
    v <- suppressWarnings(lubridate::ymd_hms(x, truncated = 3, tz = "UTC"))
    if (is.na(v)) {
      cli::cli_abort("{.arg {arg}} is not a date or time: {.val {x}}.")
    }
    v
  }
  time_start <- parse_bound(time_start, "time_start")
  time_end <- parse_bound(time_end, "time_end")

  fs::dir_create(dir_out)

  # Anchored on the extension. The donor passed `pattern` and `full.names` to
  # fs::dir_ls(), which takes neither -- they were absorbed silently, so EVERY file in the
  # track directories was read as GPX. Measured: a directory of four files returned all
  # four, including a .txt. The waypoint side used list.files(pattern = ".gpx"), an
  # unanchored regex that also matched "weird_gpx.csv".
  files_waypoints <- list.files(dir_gpx_waypoints, pattern = "\\.gpx$", full.names = TRUE)
  files_tracks <- unlist(purrr::map(dir_gpx_tracks, ~ fs::dir_ls(.x, regexp = "\\.gpx$")))

  process_layer <- function(layer, files) {
    if (length(files) == 0) {
      cli::cli_alert_info("No GPX files found for {.field {layer}}; nothing written.")
      return(invisible(NULL))
    }

    layer_data <- files |>
      purrr::map(sf::st_read, layer = layer, quiet = TRUE) |>
      dplyr::bind_rows()

    # Tracks carry no `time`; their name is the timestamp the unit minted.
    if (!("time" %in% names(layer_data))) {
      layer_data <- layer_data |>
        dplyr::mutate(
          name_old = .data$name,
          time = lubridate::ymd_hms(.data$name_old, tz = "UTC")
        )
    } else {
      layer_data <- layer_data |>
        dplyr::mutate(name_old = .data$name)
    }

    layer_data <- layer_data |>
      dplyr::mutate(name = paste0(layer_output_name, "_", .data$name)) |>
      dplyr::arrange(.data$time)

    if (dates_view) {
      cli::cli_alert_info(
        "These are all {.field {layer}} times read, unfiltered. Nothing has been written."
      )
      cat(format(dplyr::pull(layer_data, .data$time), "%Y-%m-%d %H:%M:%S"), sep = "\n")
      return(invisible(NULL))
    }

    if (!is.null(time_start)) {
      layer_data <- dplyr::filter(layer_data, .data$time >= time_start)
    }
    if (!is.null(time_end)) {
      layer_data <- dplyr::filter(layer_data, .data$time <= time_end)
    }

    path_gpx <- fs::path(dir_out, paste0("gps_", layer, "_", layer_output_name, ".gpx"))
    path_gpkg <- fs::path(dir_out, paste0(gpkg_name, ".gpkg"))
    layer_out <- paste0("gps_", layer, "_", layer_output_name)

    sf::st_write(
      layer_data,
      path_gpx,
      dataset_options = "GPX_USE_EXTENSIONS=yes",
      delete_dsn = TRUE,
      quiet = TRUE
    )

    sf::st_write(
      layer_data,
      path_gpkg,
      layer = layer_out,
      delete_dsn = FALSE, # keep the other layers already in the GeoPackage
      append = FALSE,
      quiet = TRUE
    )

    cli::cli_alert_info(
      "{nrow(layer_data)} {.field {layer}} written to {.path {path_gpx}} and to {.path {path_gpkg}} (layer {.field {layer_out}})."
    )
    invisible(NULL)
  }

  for (layer in gpx_layer_type) {
    if (grepl("track", layer)) {
      process_layer(layer, files_tracks)
    } else {
      process_layer(layer, files_waypoints)
    }
  }

  invisible(NULL)
}
