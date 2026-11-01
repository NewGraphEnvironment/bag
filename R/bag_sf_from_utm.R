#' Build an sf object from NAD 83 UTM zone, easting and northing columns
#'
#' Groups a plain data frame by its UTM zone column, promotes each group to `sf` in that
#' zone's projected CRS, transforms every group to one geographic CRS, and binds them back
#' together.
#'
#' The returned CRS must be geographic — BC Albers or WGS 84 rather than a UTM zone —
#' because points from different zones cannot share a projected CRS without one of them
#' being wrong.
#'
#' @param dat A data frame carrying UTM zone, easting and northing columns.
#' @param col_utm_zone [character] Name of the UTM zone column.
#' @param col_easting [character] Name of the easting column.
#' @param col_northing [character] Name of the northing column.
#' @param crs_return [numeric] EPSG code to return in. Must be geographic. Default 3005
#'   (BC Albers).
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
