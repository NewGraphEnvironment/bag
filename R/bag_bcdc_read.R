#' Read a BC Data Catalogue layer
#'
#' A convenience wrapper on [bcdata::bcdc_query_geodata()] and [bcdata::collect()]. Queries
#' a catalogue record, optionally filters it on one column, optionally keeps only named
#' columns, cleans the column names, and optionally drops the geometry.
#'
#' @param bcdata_record_id [character] The catalogue record, given as its permanent id
#'   (`"7ecfafa6-5e18-48cd-8d9b-eae5b5ea2881"`), its record name (`"pscis-assessments"`) or
#'   its object name (`"WHSE_FISH.PSCIS_ASSESSMENT_SVW"`). Record names are listed at
#'   <https://catalogue.data.gov.bc.ca/>. Case is not significant: an id containing a `.` is
#'   upper-cased and one without is lower-cased.
#' @param col_extract [character] Columns to keep. `NULL` (default) keeps all of them. Case
#'   is not significant.
#' @param drop_geom [logical] Drop the geometry column from the returned `sf` object.
#'   Default `FALSE`.
#' @param col_filter [character] A single column to filter on. `NULL` (default) applies no
#'   filter. Case is not significant.
#' @param col_filter_value [character] The values to keep in `col_filter`. Required when
#'   `col_filter` is given.
#'
#' @return An `sf` object with cleaned names, or a [tibble::tibble] when `drop_geom` is
#'   `TRUE`.
#'
#' @seealso [bag_bcdc_index()] for finding a record's object name, and [bag_bcdc()] to
#'   write a catalogue layer straight to a GeoPackage instead of returning it.
#' @family catalogue
#' @export
#'
#' @importFrom bcdata bcdc_query_geodata collect
#' @importFrom chk chk_character chk_flag chk_string
#' @importFrom cli cli_abort
#' @importFrom dplyr all_of filter select
#' @importFrom janitor clean_names
#' @importFrom rlang sym
#' @importFrom sf st_drop_geometry
#' @importFrom stringr str_to_lower str_to_upper
#'
#' @examples
#' \dontrun{
#' bag_bcdc_read(
#'   bcdata_record_id = "7ecfafa6-5e18-48cd-8d9b-eae5b5ea2881",
#'   col_filter = "FUNDING_PROJECT_NUMBER",
#'   col_filter_value = "skeena_2023_Phase1",
#'   col_extract = c("EXTERNAL_CROSSING_REFERENCE", "STREAM_CROSSING_ID"),
#'   drop_geom = TRUE
#' )
#'
#' # every record, two columns
#' bag_bcdc_read(
#'   bcdata_record_id = "bc-airports",
#'   col_extract = c("AIRPORT_NAME", "DESCRIPTION")
#' )
#' }
bag_bcdc_read <- function(bcdata_record_id,
                          col_extract = NULL,
                          drop_geom = FALSE,
                          col_filter = NULL,
                          col_filter_value = NULL) {

  chk::chk_string(bcdata_record_id)
  chk::chk_flag(drop_geom)
  if (!is.null(col_filter)) chk::chk_string(col_filter)
  if (!is.null(col_filter_value)) chk::chk_character(col_filter_value)
  if (!is.null(col_extract)) chk::chk_character(col_extract)

  if (!is.null(col_filter) && is.null(col_filter_value)) {
    cli::cli_abort("{.arg col_filter_value} cannot be NULL when {.arg col_filter} is provided.")
  }

  # A record given as schema.table is upper case in the catalogue; a record name or
  # permanent id is lower case. The `.` is what distinguishes them.
  bcdata_record_id <- if (grepl(".", bcdata_record_id, fixed = TRUE)) {
    stringr::str_to_upper(bcdata_record_id)
  } else {
    stringr::str_to_lower(bcdata_record_id)
  }

  if (!is.null(col_filter)) col_filter <- stringr::str_to_upper(col_filter)
  if (!is.null(col_extract)) col_extract <- stringr::str_to_upper(col_extract)

  # One path, not four. The donor had a block per combination of col_filter and
  # col_extract, each query -> [filter] -> collect -> [select] with the same abort repeated
  # three times.
  q <- bcdata::bcdc_query_geodata(bcdata_record_id)

  if (!is.null(col_filter)) {
    q <- dplyr::filter(q, !!rlang::sym(col_filter) %in% col_filter_value)
  }

  x <- bcdata::collect(q)

  if (!is.null(col_extract)) {
    x <- dplyr::select(x, dplyr::all_of(col_extract))
  }

  # The donor did not abort when neither argument was given, because an empty layer is a
  # fact about the layer rather than a failed query. Kept.
  if (nrow(x) == 0 && (!is.null(col_filter) || !is.null(col_extract))) {
    cli::cli_abort(c(
      "No records found in {.val {bcdata_record_id}}.",
      i = if (!is.null(col_filter)) {
        "Check that {.field {col_filter}} holds {.val {col_filter_value}}."
      },
      i = if (!is.null(col_extract)) {
        "Check that {.field {col_extract}} {?is a column/are columns} of the record."
      }
    ))
  }

  x <- janitor::clean_names(x)

  if (drop_geom) {
    x <- sf::st_drop_geometry(x)
  }

  x
}
