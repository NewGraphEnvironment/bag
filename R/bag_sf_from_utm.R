#' Build an sf object from NAD 83 UTM zone, easting and northing columns
#'
#' Groups a plain data frame by its UTM zone column, promotes each group to `sf` in that
#' zone's projected CRS, transforms every group to one geographic CRS, and binds them back
#' together.
#'
#' `crs_return` must be a CRS that is valid across every zone in the data — BC Albers
#' (3005, the default) or WGS 84 (4326), rather than one UTM zone's own CRS, because a
#' point from zone 9 expressed in zone 11's CRS is simply wrong. An earlier version of
#' this sentence said "must be geographic", which excluded its own default: BC Albers is
#' projected. The property that matters is province-wide validity, not geographic versus
#' projected, and it is not something the function can check — a UTM `crs_return` is
#' accepted and gives silently wrong coordinates for every zone but one.
#'
#' @param dat A data frame carrying UTM zone, easting and northing columns.
#' @param col_utm_zone [character] Name of the UTM zone column.
#' @param col_easting [character] Name of the easting column.
#' @param col_northing [character] Name of the northing column.
#' @param crs_return [numeric] EPSG code to return in. Must be valid across every zone
#'   present — not a single UTM zone's CRS. Default 3005 (BC Albers).
#'
#' @return An `sf` data frame in `crs_return`, ordered by UTM zone.
#'
#' @seealso [bag_assign_utm()] to write those columns onto an `sf` object. The two are
#'   not inverses: that one returns its input's CRS and keeps the `geometry` column, this
#'   one returns `crs_return` and names the geometry column `geom`.
#' @family coordinates
#' @export
#'
#' @importFrom chk chk_numeric chk_string
#' @importFrom cli cli_abort
#' @importFrom dplyr arrange bind_rows group_split
#' @importFrom purrr map
#' @importFrom rlang sym
#' @importFrom sf st_as_sf st_transform
#'
#' @examples
#' \dontrun{
#' bag_sf_from_utm(pscis_all)
#' }
bag_sf_from_utm <- function(dat = NULL,
                            col_utm_zone = "utm_zone",
                            col_easting = "easting",
                            col_northing = "northing",
                            crs_return = 3005) {

  if (is.null(dat)) {
    cli::cli_abort("{.arg dat} must be a data frame, not NULL.")
  }
  if (!is.data.frame(dat)) {
    cli::cli_abort("{.arg dat} must inherit from a data frame.")
  }
  chk::chk_string(col_utm_zone)
  chk::chk_string(col_easting)
  chk::chk_string(col_northing)
  chk::chk_numeric(crs_return)

  # A presence guard, which this function did without for a while. It was written, then
  # removed because tibble already reported a missing column by name and all of them at
  # once, so no mutation could tell the two apart -- and then it was needed again, because
  # the value checks below read those columns and `dat[["easting"]]` on a column that is
  # not there is NULL, which turned a clear report into a different failure entirely.
  cols_needed <- c(col_utm_zone, col_easting, col_northing)
  cols_missing <- cols_needed[!cols_needed %in% names(dat)]
  if (length(cols_missing) > 0) {
    cli::cli_abort(c(
      "{cli::qty(length(cols_missing))}{?Column/Columns} {.field {cols_missing}}
       {?is/are} not in {.arg dat}."
    ))
  }

  # The VALUES are a different question, and the removed guard's rationale used to be
  # read as covering both. bag_assign_utm() -- the documented partner -- writes NA zone, easting
  # and northing for a row it could not place, and handing that straight back here
  # aborted from inside sf with "missing values in coordinates not allowed", naming a
  # group_split() index rather than a row or a column. A zone column read by readr from
  # an all-empty csv column arrives as character, and aborted the same way.
  zone_raw <- dat[[col_utm_zone]]
  if (!is.numeric(zone_raw)) {
    cli::cli_abort(c(
      "{.field {col_utm_zone}} must be numeric.",
      x = "It is {.cls {class(zone_raw)[1]}}.",
      i = "A column read from a csv that was empty comes back as character."
    ))
  }

  placed <- !is.na(zone_raw) &
    !is.na(dat[[col_easting]]) &
    !is.na(dat[[col_northing]])

  rows_bad <- which(placed & !zone_raw %in% 1:60)
  if (length(rows_bad) > 0) {
    cli::cli_abort(c(
      "{.field {col_utm_zone}} must hold UTM zone numbers, 1 to 60.",
      x = "{cli::qty(length(rows_bad))}Row{?s} {.val {rows_bad}}.",
      i = "{cli::qty(length(unique(zone_raw[rows_bad])))}Holding
           {.val {unique(zone_raw[rows_bad])}}."
    ))
  }

  # group_split() on a 0-row frame yields no groups, so bind_rows() would return a plain
  # tibble rather than the `sf` object documented above. One promotion of the empty frame
  # gives an `sf` with the same columns. The zone CRS is a placeholder with no rows to
  # place: 26909 is the westernmost of the three BC zones.
  if (nrow(dat) == 0) {
    # sf computes a bounding box here and warns four times over an empty one ("no
    # non-missing arguments to min/max"). Muffled by message rather than with
    # suppressWarnings(), so any other warning sf raises still reaches the caller.
    empty <- withCallingHandlers(
      sf::st_as_sf(
        dat,
        coords = c(col_easting, col_northing),
        crs = 26909,
        remove = FALSE,
        sf_column_name = "geom"
      ),
      warning = function(w) {
        if (grepl("no non-missing arguments to (min|max)", conditionMessage(w))) {
          invokeRestart("muffleWarning")
        }
      }
    )
    return(sf::st_transform(empty, crs = crs_return))
  }

  # Rows that cannot be placed are carried through with empty geometry rather than
  # dropped or aborted on, which is what bag_assign_utm() does with the same input, so
  # the two compose: its output is valid input here and the row count survives the trip.
  .bag_warn_unplaced(sum(!placed), "geom")

  # The donor's pipeline. Its `.x` is purrr's lambda argument, not magrittr's placeholder,
  # so the native pipe carries it unchanged.
  out <- dat[placed, ] |>
    dplyr::arrange(!!rlang::sym(col_utm_zone)) |>
    dplyr::group_split(!!rlang::sym(col_utm_zone)) |>
    purrr::map(~ sf::st_as_sf(
      .x,
      coords = c(col_easting, col_northing),
      crs = 26900 + unique(.x[[col_utm_zone]]),
      remove = FALSE,
      sf_column_name = "geom"
    )) |>
    purrr::map(sf::st_transform, crs = crs_return) |>
    dplyr::bind_rows()

  if (all(placed)) {
    return(out)
  }

  # The geometry column is ASSIGNED and then promoted, not passed to st_sf() alongside
  # the frame: st_sf(df, geom = sfc) splices the frame's columns and returns one row per
  # COLUMN -- measured, a 1-row 4-column frame came back as 4 rows.
  unplaced <- dat[!placed, ]
  unplaced[["geom"]] <- sf::st_sfc(
    rep(list(sf::st_point()), sum(!placed)),
    crs = sf::st_crs(crs_return)
  )
  unplaced <- sf::st_sf(unplaced, sf_column_name = "geom")

  dplyr::bind_rows(out, unplaced)
}
