#' Assign latitude and longitude columns to an sf point object
#'
#' Transforms the object to WGS 84, reads off latitude and longitude as columns, and
#' transforms back to the input CRS.
#'
#' @param dat An `sf` data frame of `POINT` geometry.
#' @param col_lat [character] Name of the column to hold the latitude.
#' @param col_lon [character] Name of the column to hold the longitude.
#'
#' @return An `sf` data frame in the input CRS, with latitude and longitude columns
#'   appended.
#'
#' @seealso [bag_assign_utm()] for UTM zone, easting and northing.
#' @family coordinates
#' @export
#'
#' @importFrom chk chk_string
#' @importFrom cli cli_abort
#' @importFrom dplyr mutate
#' @importFrom rlang :=
#' @importFrom sf st_coordinates st_crs st_geometry st_transform
#'
#' @examples
#' \dontrun{
#' sf_df <- data.frame(lon = -128.5, lat = 54.5) |>
#'   sf::st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
#'   sf::st_transform(3005)
#'
#' bag_assign_latlong(sf_df, col_lon = "long")
#' }
bag_assign_latlong <- function(dat = NULL,
                               col_lat = "lat",
                               col_lon = "lon") {

  .bag_chk_sf_point(dat)
  chk::chk_string(col_lon)
  chk::chk_string(col_lat)

  crs_og <- sf::st_crs(dat, parameters = TRUE)$epsg

  dat_wgs <- sf::st_transform(dat, crs = 4326)

  # Coordinates read once rather than once per column, and injected with `!!` so a column
  # of the same name cannot shadow the local vector inside mutate().
  xy <- sf::st_coordinates(dat_wgs)

  dat_wgs |>
    dplyr::mutate(
      {{ col_lon }} := !!xy[, 1],
      {{ col_lat }} := !!xy[, 2]
    ) |>
    sf::st_transform(crs = crs_og)
}
