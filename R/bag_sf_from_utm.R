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

  # No guard on the coordinate columns. One was written here and then removed: tibble
  # already reports a missing column by name, and all of them at once ("Columns `easting`
  # and `northing` don't exist"), so the guard changed nothing a caller could observe --
  # a mutation test could not tell the two apart. The tests below pin that reporting.

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

  # The donor's pipeline. Its `.x` is purrr's lambda argument, not magrittr's placeholder,
  # so the native pipe carries it unchanged.
  dat |>
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
}
