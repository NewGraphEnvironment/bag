#' Assign UTM zone, easting and northing to an sf point object
#'
#' Derives the NAD 83 UTM zone from each point's longitude, transforms each zone's points to
#' that zone's projected CRS to read off easting and northing, and returns the object in its
#' original CRS with those three columns written in.
#'
#' Rows come back **ordered by UTM zone**, not in their input order. That is the donor's
#' behaviour and is relied on by the files its callers write back.
#'
#' @param dat An `sf` data frame of `POINT` geometry.
#' @param col_zone [character] Name of the column to hold the UTM zone.
#' @param col_easting [character] Name of the column to hold the easting.
#' @param col_northing [character] Name of the column to hold the northing.
#' @param sig_dig [numeric] Digits to round easting and northing to.
#'
#' @return An `sf` data frame in the input CRS, with the zone, easting and northing columns
#'   assigned.
#'
#' @seealso [bag_sp_assign_sf_from_utm()] for the inverse, and [bag_sp_assign_latlong()] for
#'   latitude and longitude columns.
#' @family coordinates
#' @export
#'
#' @importFrom chk chk_string
#' @importFrom cli cli_abort cli_warn
#' @importFrom dplyr arrange bind_rows distinct group_by group_split mutate pull select
#' @importFrom magrittr %>%
#' @importFrom purrr map map2
#' @importFrom rlang sym
#' @importFrom sf st_coordinates st_crs st_geometry st_transform
#'
#' @examples
#' \dontrun{
#' sf_df <- data.frame(
#'   lon = c(-128.5, -123.5, -118.5), # UTM zones 9, 10 and 11
#'   lat = c(45.5, 45.5, 45.5)
#' ) |>
#'   sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)
#'
#' bag_sp_assign_utm(dat = sf_df)
#' }
bag_sp_assign_utm <- function(dat = NULL,
                              col_zone = "utm_zone",
                              col_easting = "easting",
                              col_northing = "northing",
                              sig_dig = 0) {

  bag_chk_sf_point(dat)
  chk::chk_string(col_zone)
  chk::chk_string(col_easting)
  chk::chk_string(col_northing)

  # Flag the case where the named coordinate columns do not exist yet, since the caller may
  # have meant to point at existing ones.
  if (!col_easting %in% names(dat) || !col_northing %in% names(dat)) {
    cli::cli_warn(c(
      "{.arg col_easting} ({.field {col_easting}}) and {.arg col_northing} ({.field {col_northing}}) are not columns of {.arg dat}.",
      i = "They will be created. Pass the existing column names if that is not what you want."
    ))
  }

  crs_og <- sf::st_crs(dat, parameters = TRUE)$epsg

  # The pipelines below are the donor's, unchanged. They use magrittr's `.` placeholder
  # inside dplyr::mutate(), which the native pipe has no equivalent for, and their row
  # ordering and CRS round trip are relied on by the files ~20 call sites write back. A
  # rewrite is where a regression would come from, so the import is declared instead.
  dat2 <- dat %>%
    sf::st_transform(crs = 4326) %>%
    dplyr::mutate(
      long = sf::st_coordinates(.)[, 1]
    ) %>%
    dplyr::mutate({{ col_zone }} := floor((long + 180) / 6) + 1) %>%
    dplyr::mutate(epsg = 26900 + !!rlang::sym(col_zone)) %>%
    dplyr::arrange(epsg) %>%
    dplyr::select(-long)

  crs_l <- dat2 %>%
    dplyr::distinct(epsg) %>%
    dplyr::pull(epsg)

  # Grouped by the same key the frame was sorted on, so the group order matches crs_l.
  form_l <- dat2 %>%
    dplyr::group_by(epsg) %>%
    dplyr::group_split()

  form_l %>%
    purrr::map2(crs_l, sf::st_transform) %>%
    purrr::map(~ dplyr::mutate(
      .,
      {{ col_easting }} := round(sf::st_coordinates(.)[, 1], sig_dig),
      {{ col_northing }} := round(sf::st_coordinates(.)[, 2], sig_dig)
    )) %>%
    purrr::map(sf::st_transform, crs = crs_og) %>%
    dplyr::bind_rows() %>%
    dplyr::select(-epsg)
}
