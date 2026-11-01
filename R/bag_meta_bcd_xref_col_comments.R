#' Describe one column of a BC Data Catalogue layer
#'
#' Checks that a `schema.table` and column exist in the BC Data Catalogue WMS service and
#' returns the catalogue's own description of that column.
#'
#' @param schema_table [character] The object name of the layer, as
#'   `schema.table` — for example `"whse_imagery_and_base_maps.gsr_airports_svw"`. Case is
#'   not significant; it is upper-cased before the query.
#' @param column [character] The column to describe. Case is not significant.
#'
#' @return A [tibble::tibble] with the `schema_table` as given, the column name, its local
#'   R type and the catalogue's column comments. Zero rows when the column does not exist
#'   in the layer.
#'
#' @seealso [bag_meta_bcd_xref()] for the layer lookup this complements.
#' @family metadata
#' @export
#'
#' @importFrom bcdata bcdc_describe_feature
#' @importFrom chk chk_string
#' @importFrom cli cli_abort cli_alert_danger
#' @importFrom dplyr filter mutate select
#' @importFrom stringr str_to_lower str_to_upper
#'
#' @examples
#' \dontrun{
#' bag_meta_bcd_xref_col_comments(
#'   "whse_imagery_and_base_maps.gsr_airports_svw",
#'   "airport_name"
#' )
#' }
bag_meta_bcd_xref_col_comments <- function(schema_table, column) {

  chk::chk_string(schema_table)
  chk::chk_string(column)

  column <- stringr::str_to_lower(column)

  # One request, not two: the donor called bcdc_describe_feature() inside a tryCatch for
  # the error message and then again for the value, so every call hit the service twice.
  d <- tryCatch(
    bcdata::bcdc_describe_feature(stringr::str_to_upper(schema_table)),
    error = function(e) {
      cli::cli_abort(
        "The object name {.val {schema_table}} does not exist in the BC Data Catalogue WMS service.",
        parent = e
      )
    }
  )

  d <- dplyr::mutate(d, col_name = stringr::str_to_lower(col_name))

  if (!column %in% d$col_name) {
    cli::cli_alert_danger("Column {.field {column}} does not exist in table {.val {schema_table}}.")
  }

  d |>
    dplyr::filter(col_name == column) |>
    dplyr::mutate(object_name = schema_table) |>
    dplyr::select(object_name, col_name, col_type_local = local_col_type, col_comments = column_comments)
}
