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
#' @seealso [bag_sf_from_utm()] to build an `sf` object from such columns — not an
#'   inverse of this function, which returns the input CRS where that one returns
#'   `crs_return` — and [bag_assign_latlong()] for latitude and longitude columns.
#' @family coordinates
#' @export
#'
#' @importFrom chk chk_string
#' @importFrom cli cli_abort cli_warn
#' @importFrom dplyr bind_rows mutate select
#' @importFrom purrr map
#' @importFrom rlang := sym
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
#' bag_assign_utm(dat = sf_df)
#' }
bag_assign_utm <- function(dat = NULL,
                           col_zone = "utm_zone",
                           col_easting = "easting",
                           col_northing = "northing",
                           sig_dig = 0) {

  .bag_chk_sf_point(dat)
  chk::chk_string(col_zone)
  chk::chk_string(col_easting)
  chk::chk_string(col_northing)

  # Flag the case where the named coordinate columns do not exist yet, since the caller may
  # have meant to point at existing ones.
  if (!col_easting %in% names(dat) || !col_northing %in% names(dat)) {
    cli::cli_warn(c(
      "{.arg col_easting} and {.arg col_northing} are not columns of {.arg dat}.",
      i = "Looking for {.field {col_easting}} and {.field {col_northing}}.",
      i = "They will be created. Pass the existing names if that is not what you want."
    ))
  }

  crs_og <- sf::st_crs(dat, parameters = TRUE)$epsg

  # Longitude is read once, off the WGS 84 copy, and injected with `!!` so a column of the
  # same name cannot shadow the local vector inside mutate(). The donor read it into a
  # `long` column and selected it back out.
  dat_wgs <- sf::st_transform(dat, crs = 4326)
  lon <- sf::st_coordinates(dat_wgs)[, 1]

  dat2 <- dat_wgs |>
    dplyr::mutate(
      {{ col_zone }} := floor((!!lon + 180) / 6) + 1,
      epsg = 26900 + !!rlang::sym(col_zone)
    )

  # One pass per zone, keyed on the sorted zone values themselves. The donor paired a
  # group_split() with a separately derived CRS vector and relied on the two coming out in
  # the same order -- an invariant held together by a comment, which needed an
  # arrange(epsg) above to hold. Here each pass carries the CRS it transforms to, and the
  # sorted keys are what put the rows back in zone order, so neither is needed.
  out_l <- purrr::map(unique(sort(dat2[["epsg"]])), function(epsg_zone) {
    grp <- sf::st_transform(dat2[dat2[["epsg"]] == epsg_zone, ], crs = epsg_zone)
    xy <- sf::st_coordinates(grp)

    grp |>
      dplyr::mutate(
        {{ col_easting }} := round(!!xy[, 1], sig_dig),
        {{ col_northing }} := round(!!xy[, 2], sig_dig)
      ) |>
      sf::st_transform(crs = crs_og)
  })

  out_l |>
    dplyr::bind_rows() |>
    dplyr::select(-epsg)
}
