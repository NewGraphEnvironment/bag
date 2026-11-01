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
#' @importFrom dplyr bind_rows mutate
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
  # have meant to point at existing ones. Only the absent ones are named: the predicate is
  # an OR, so saying "both" sent a caller who typo'd one argument to check the other.
  absent <- c(col_easting = col_easting, col_northing = col_northing)
  absent <- absent[!absent %in% names(dat)]
  if (length(absent) > 0) {
    # Both the argument and the value it holds, and only the ones actually absent. cli
    # resolves {?a/b} against the most recent quantity IN THE SAME STRING, and each
    # bullet is its own string -- hence the explicit qty() on the last.
    cli::cli_warn(c(
      "{.arg {names(absent)}} {?does/do} not name {?a column/columns} of {.arg dat}.",
      i = "Looking for {.field {absent}}.",
      i = "{cli::qty(length(absent))}{?It/They} will be created. Pass the existing
            name{?s} if that is not what you want."
    ))
  }

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

  # The CRS object, not its EPSG code. `st_crs(parameters = TRUE)$epsg` is NA for any CRS
  # with no authority -- a proj string, or a WKT without one -- and st_transform(crs = NA)
  # then aborts with "crs not found: is it missing?", naming neither the argument nor the
  # CRS. The object round trips whether or not EPSG knows it.
  crs_og <- sf::st_crs(dat)

  # Longitude is read once, off the WGS 84 copy, and injected with `!!` so a column of the
  # same name cannot shadow the local vector inside mutate(). The donor read it into a
  # `long` column and selected it back out.
  dat_wgs <- sf::st_transform(dat, crs = 4326)
  lon <- sf::st_coordinates(dat_wgs)[, 1]

  # The zone CRS is a local vector, not a column. The donor kept it in one called `epsg`
  # and selected it back out, which silently overwrote and then deleted any column of
  # that name the caller already had -- the same class of problem the `long` column above
  # was removed for.
  dat2 <- dat_wgs |>
    dplyr::mutate({{ col_zone }} := floor((!!lon + 180) / 6) + 1)

  epsg <- 26900 + dat2[[col_zone]]

  # Rows the zone arithmetic could not place -- an empty POINT, or NA coordinates, which
  # is a field row entered without a GPS fix. They keep every attribute and get NA
  # coordinate columns, which is what the sibling bag_assign_latlong() does. The
  # st_transform() is a no-op that puts the columns through the same tail as a real zone
  # group, so the two cannot come out in different orders.
  add_na_coords <- function(grp) {
    # The zone is set too, not left as the NaN the arithmetic produced: NaN is an NA in
    # R, but it prints differently and would read as a computed value rather than a
    # missing one.
    grp |>
      dplyr::mutate(
        {{ col_zone }} := NA_real_,
        {{ col_easting }} := NA_real_,
        {{ col_northing }} := NA_real_
      ) |>
      sf::st_transform(crs = crs_og)
  }

  read_coords <- function(grp, epsg_zone) {
    grp_utm <- sf::st_transform(grp, crs = epsg_zone)
    xy <- sf::st_coordinates(grp_utm)

    grp_utm |>
      dplyr::mutate(
        {{ col_easting }} := round(!!xy[, 1], sig_dig),
        {{ col_northing }} := round(!!xy[, 2], sig_dig)
      ) |>
      sf::st_transform(crs = crs_og)
  }

  # `placed` is what keeps an unplaceable row out of the subscript below. Without it
  # sort() drops the NA from `zones`, so the row joins no group -- and `epsg == epsg_zone`
  # is NA for it in EVERY pass, which `[.data.frame` answers with a fabricated all-NA row.
  # One such input row became `length(zones)` phantom rows and its own attributes were
  # lost, silently, on a frame bag_gpkg_refresh() then wrote back over the GeoPackage.
  placed <- !is.na(epsg)
  zones <- unique(sort(epsg[placed]))

  # One pass per zone, keyed on the sorted zone values themselves. The donor paired a
  # group_split() with a separately derived CRS vector and relied on the two coming out in
  # the same order -- an invariant held together by a comment, which needed an
  # arrange(epsg) above to hold. Here each pass carries the CRS it transforms to, and the
  # sorted keys are what put the rows back in zone order, so neither is needed.
  groups <- purrr::map(
    zones,
    function(epsg_zone) read_coords(dat2[placed & epsg == epsg_zone, ], epsg_zone)
  )

  n_unplaced <- sum(!placed)
  if (n_unplaced > 0) {
    .bag_warn_unplaced(n_unplaced, c(col_zone, col_easting, col_northing))
    groups <- c(groups, list(add_na_coords(dat2[!placed, ])))
  }

  # No rows at all means no groups, and binding none gives a 0 x 0 tibble that loses every
  # column the caller passed in. One pass over the empty frame produces the same columns
  # instead, and it goes through the same bind_rows() so the column ORDER cannot diverge
  # between the paths -- that bind is what moves geometry last. The zone is a placeholder
  # with no rows to place: 26909 is the westernmost of the three BC zones.
  if (length(groups) == 0) {
    groups <- list(read_coords(dat2, 26909))
  }

  dplyr::bind_rows(groups)
}
