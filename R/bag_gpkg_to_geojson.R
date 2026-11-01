#' Write every layer of a GeoPackage out as GeoJSON
#'
#' Reads each layer of a GeoPackage and writes it as its own `.geojson` file. GeoJSON is
#' convenient for mapping: QGIS picks up changes without a restart, and GitHub and other web
#' platforms render it directly.
#'
#' **Every layer is transformed to WGS 84 (EPSG:4326) on the way out.** RFC 7946 defines
#' GeoJSON as WGS 84 and removed the `crs` member, so a file written in a projected CRS
#' renders in the wrong place everywhere that follows the RFC — GitHub's preview, Leaflet,
#' Mapbox — while opening correctly in QGIS, which still honours the member. BC Albers is
#' the usual CRS of a BC GeoPackage, which is exactly the case that would break.
#'
#' A layer with no usable CRS is therefore **refused**, and refused before anything is
#' written, so a GeoPackage is converted whole or not at all. The check is not
#' `is.na(sf::st_crs(x))`: GDAL's GeoPackage driver never returns a missing CRS. The
#' format reserves `srs_id` −1 for "undefined Cartesian" and 0 for "undefined
#' geographic", and both read back as real CRS objects — the first cannot be transformed
#' at all, and the second would be silently taken for WGS 84. `sf::st_write()` itself
#' produces the −1 case when handed an object whose CRS is `NA`.
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
#' @importFrom sf st_crs st_layers st_read st_transform st_write
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

  # Spatial layers only. A QGIS style table is a layer to st_layers() and has no CRS, so
  # counting it made a styled GeoPackage unconvertible, with a remedy that cannot be run.
  layers <- .bag_gpkg_layers(gpkg_path)
  layer_names <- layers$name

  if (length(layer_names) == 0) {
    cli::cli_abort("{.path {gpkg_path}} contains no spatial layers.")
  }

  # Checked over every layer first, so the loop below cannot abort part way and leave a
  # partial set of .geojson files behind with nothing said about it.
  unreferenced <- layer_names[vapply(layers$crs, .bag_crs_unusable, logical(1))]
  if (length(unreferenced) > 0) {
    cli::cli_abort(c(
      "{.path {gpkg_path}} has {length(unreferenced)} layer{?s} with no usable CRS: \
       {.val {unreferenced}}.",
      i = "GeoJSON is WGS 84 by definition, so coordinates with no CRS cannot be
           written correctly.",
      i = "{cli::qty(length(unreferenced))}Set a CRS on {?it/them} first, with
           {.fn sf::st_crs}."
    ))
  }

  paths_out <- character(length(layer_names))

  for (i in seq_along(layer_names)) {
    layer_name <- layer_names[[i]]
    d <- sf::st_read(dsn = gpkg_path, layer = layer_name, quiet = TRUE)
    path_out <- fs::path(dir_out, paste0(layer_name, ".geojson"))

    # RFC 7946 is WGS 84 only. A layer already in 4326 is left alone rather than round
    # tripped. An unusable CRS was refused above, before anything was written.
    if (sf::st_crs(d) != sf::st_crs(4326)) {
      d <- sf::st_transform(d, crs = 4326)
    }

    # delete_dsn rather than append: one layer per file, rewritten each run.
    sf::st_write(d, dsn = path_out, delete_dsn = TRUE, quiet = TRUE)
    paths_out[[i]] <- path_out
  }

  cli::cli_alert_success(
    "Wrote {length(paths_out)} layer{?s} from {.path {gpkg_path}} to {.path {dir_out}}."
  )

  invisible(paths_out)
}
