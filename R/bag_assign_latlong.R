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

  # The same check its siblings make over this container. An sf object whose CRS is
  # missing, or is one of the GeoPackage format's "undefined" placeholders, aborts out of
  # GDAL several steps later with a message naming neither the argument nor the CRS.
  if (.bag_crs_unusable(sf::st_crs(dat))) {
    cli::cli_abort(c(
      "{.arg dat} has no usable CRS.",
      i = "Coordinates are derived by reprojecting, so the CRS has to be known.",
      i = "Set one with {.fn sf::st_crs} first."
    ))
  }

  # The CRS object, not its EPSG code: `st_crs(parameters = TRUE)$epsg` is NA for a CRS
  # with no authority, and st_transform(crs = NA) then aborts naming nothing.
  crs_og <- sf::st_crs(dat)

  dat_wgs <- sf::st_transform(dat, crs = 4326)

  # Coordinates read once rather than once per column, and injected with `!!` so a column
  # of the same name cannot shadow the local vector inside mutate().
  xy <- sf::st_coordinates(dat_wgs)

  # A row with empty or NA geometry reads back as NaN here. Its sibling bag_assign_utm()
  # writes NA for the same input and says so; this one wrote NaN and said nothing. NaN is
  # an NA in R and reaches disk as a NULL or an empty field either way, so the difference
  # that mattered was the silence.
  lon <- xy[, 1]
  lat <- xy[, 2]
  lon[is.nan(lon)] <- NA_real_
  lat[is.nan(lat)] <- NA_real_
  .bag_warn_unplaced(sum(is.na(lon)), c(col_lon, col_lat))

  dat_wgs |>
    dplyr::mutate(
      {{ col_lon }} := !!lon,
      {{ col_lat }} := !!lat
    ) |>
    sf::st_transform(crs = crs_og)
}
