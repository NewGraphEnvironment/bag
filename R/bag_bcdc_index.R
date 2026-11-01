#' Build a lookup table of BC Data Catalogue layers
#'
#' Walks every BC Data Catalogue package that advertises a WMS resource and returns one row
#' per WMS layer, giving the `schema.table` object name a download needs alongside the
#' catalogue record it came from.
#'
#' @param pkg_exclude [character] Package names to exclude. Defaults to
#'   `"bc-web-map-library"`, which is associated with several datasets that have no WMS
#'   download capability.
#'
#' @return A [tibble::tibble] with columns `object_name`, `package_name`, `url_browser`,
#'   `description`, `id_package`, `id_dataset` and `url_download`.
#'
#' @seealso [bag_bcdc_cols()] for the column descriptions of one layer,
#'   and [bag_bcdc_read()] to read a layer once its object name is known.
#' @family catalogue
#' @export
#'
#' @importFrom bcdata bcdc_search
#' @importFrom chk chk_character
#' @importFrom cli cli_alert_danger cli_alert_warning
#' @importFrom dplyr bind_rows distinct filter group_by left_join mutate n row_number
#'   select ungroup
#' @importFrom purrr map map2_df map_df map_lgl pluck
#' @importFrom stringr str_to_lower
#'
#' @examples
#' \dontrun{
#' lookup_table <- bag_bcdc_index()
#' head(lookup_table)
#' }
bag_bcdc_index <- function(pkg_exclude = c("bc-web-map-library")) {

  chk::chk_character(pkg_exclude)

  # Start from the packages that advertise a wms resource.
  l_raw <- bcdata::bcdc_search(res_format = "wms", n = 10000)

  l <- l_raw[!(names(l_raw) %in% pkg_exclude)]

  # Every package should carry a resource_df to drill into.
  test_resource_df <- all(
    l |>
      purrr::map(purrr::pluck, "resource_df") |>
      purrr::map_lgl(is.list)
  )

  if (!test_resource_df) {
    cli::cli_alert_danger("Not all data packages contain a list element called {.field resource_df}.")
  }

  bcdata_lookup_raw <- l |>
    purrr::map_df(
      ~ purrr::pluck(.x, "resource_df") |>
        dplyr::mutate(object_name_idx = dplyr::row_number()) |>
        dplyr::filter(format == "wms"),
      .id = "package_name"
    ) |>
    dplyr::select(url, id_dataset = id, package_name, object_name_idx)

  # Packages holding more than one wms resource. Not duplicate names -- one catalogue
  # package can publish several layers -- but worth surfacing, because the row index below
  # picks one resource per package and the others are not represented.
  pkgs_multi_wms <- bcdata_lookup_raw |>
    dplyr::group_by(package_name) |>
    dplyr::filter(dplyr::n() > 1) |>
    dplyr::ungroup()

  object_names <- purrr::map2_df(
    .x = bcdata_lookup_raw$package_name,
    .y = bcdata_lookup_raw$object_name_idx,
    .f = ~ .bag_bcdc_schtab(pkg_list = l, pkg_name = .x, row_idx = .y)
  ) |>
    dplyr::mutate(object_name = stringr::str_to_lower(object_name))

  # The package id and notes, so each object name can be joined to its catalogue record.
  #
  # NA rather than the NULL pluck() returns for a missing element, for the reason
  # .bag_bcdc_schtab() carries at length: list() drops a NULL entry, bind_rows() NA-fills
  # the gap wherever some other package supplied the field, and so the hole never shows
  # -- until EVERY package lacks it, when the column is absent altogether and the code
  # downstream fails naming a column the caller never passed.
  pluck_chr <- function(x, key) {
    v <- purrr::pluck(x, key)
    if (is.null(v)) NA_character_ else as.character(v)
  }

  id_description <- l |>
    purrr::map(function(pkg) {
      list(
        id_package = pluck_chr(pkg, "id"),
        description = pluck_chr(pkg, "notes")
      )
    }) |>
    dplyr::bind_rows(.id = "package_name")

  # Joined on the row index as well as the package name. `package_name` alone is not a key
  # here: a catalogue package publishing N WMS resources has N rows on both sides, so a
  # join by name alone returns N^2 of them, and N^2 - N carry an object_name paired with
  # some other resource's dataset id. Measured on a fixture with one two-resource package:
  # 6 rows where 4 are correct.
  bcdata_lookup <- dplyr::left_join(
    dplyr::left_join(
      bcdata_lookup_raw,
      object_names,
      by = c("package_name", "object_name_idx")
    ),
    id_description,
    by = "package_name"
  ) |>
    dplyr::mutate(url_browser = paste0("https://catalogue.data.gov.bc.ca/dataset/", id_package)) |>
    dplyr::select(
      object_name, package_name, url_browser, description,
      id_package, id_dataset, url_download = url
    )

  if (nrow(pkgs_multi_wms) > 0) {
    # Used only inside the cli string below, which codetools does not parse.
    pkgs <- pkgs_multi_wms |> # nolint: object_usage_linter.
      dplyr::select(package_name) |>
      dplyr::distinct()

    cli::cli_alert_warning(
      "{nrow(pkgs)} catalogue package{?s} publish{?es/} more than one WMS resource: {.val {pkgs$package_name}}."
    )
  }

  bcdata_lookup
}
