#' Write every layer of a GeoPackage out as GeoJSON
#'
#' Reads each layer of a GeoPackage and writes it as its own `.geojson` file. GeoJSON is
#' convenient for mapping: QGIS picks up changes without a restart, and GitHub and other web
#' platforms render it directly when it is in WGS 84.
#'
#' @param dir_in [character] Directory holding the GeoPackage.
#' @param dir_out [character] Directory to write the GeoJSON files to. Created if absent.
#' @param file_name_in [character] Name of the GeoPackage, without the `.gpkg` extension.
#'
#' @return A [character] vector of the files written, invisibly.
#'
#' @seealso [bag_layers()] for listing a data source's layers and geometry types.
#' @family files
#' @export
#'
#' @importFrom chk chk_dir chk_string
#' @importFrom cli cli_abort cli_alert_success
#' @importFrom fs dir_create path
#' @importFrom purrr pluck
#' @importFrom sf st_layers st_read st_write
#'
#' @examples
#' \dontrun{
#' bag_gpkg_to_geojson(
#'   dir_in = "~/gps",
#'   dir_out = "~/gps/geojson",
#'   file_name_in = "gps_2026"
#' )
#' }
bag_gpkg_to_geojson <- function(dir_in, dir_out, file_name_in) {

  chk::chk_string(dir_in)
  chk::chk_dir(dir_in)
  chk::chk_string(dir_out)
  chk::chk_string(file_name_in)

  gpkg_path <- fs::path(dir_in, paste0(file_name_in, ".gpkg"))
  if (!file.exists(gpkg_path)) {
    cli::cli_abort("No GeoPackage at {.path {gpkg_path}}.")
  }

  fs::dir_create(dir_out)

  layer_names <- sf::st_layers(gpkg_path) |>
    purrr::pluck("name")

  if (length(layer_names) == 0) {
    cli::cli_abort("{.path {gpkg_path}} contains no layers.")
  }

  paths_out <- character(length(layer_names))

  for (i in seq_along(layer_names)) {
    layer_name <- layer_names[[i]]
    d <- sf::st_read(dsn = gpkg_path, layer = layer_name, quiet = TRUE)
    path_out <- fs::path(dir_out, paste0(layer_name, ".geojson"))

    # delete_dsn rather than append: one layer per file, rewritten each run.
    sf::st_write(d, dsn = path_out, delete_dsn = TRUE, quiet = TRUE)
    paths_out[[i]] <- path_out
  }

  cli::cli_alert_success(
    "Wrote {length(paths_out)} layer{?s} from {.path {gpkg_path}} to {.path {dir_out}}."
  )

  invisible(paths_out)
}
