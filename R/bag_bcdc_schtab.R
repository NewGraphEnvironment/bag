#' Cross reference a BC Data Catalogue package name with its object name
#'
#' Internal. Helper used by [bag_bcdc_index()] to drill through one catalogue package and
#' pull the `object_name` out of its `resources` list at a given row index. The index is the
#' row of the package's `resource_df` that holds the WMS resource, because a package can
#' hold several datasets and only the WMS one has the `schema.table` a download needs.
#'
#' @param pkg_list [list] Complete metadata by package, as returned by
#'   [bcdata::bcdc_search()].
#' @param pkg_name [character] A single package name, naming an element of `pkg_list`.
#' @param row_idx [numeric] Row index of the WMS resource within that package.
#'
#' @return A [tibble::tibble] with columns `object_name`, `package_name` and
#'   `object_name_idx`. `object_name` is `NA` when the package carries no `object_name` at
#'   that index. The index is returned so the caller can join on it: `package_name` alone
#'   is not a key when a package publishes more than one WMS resource.
#'
#' @importFrom purrr pluck
#' @importFrom tibble tibble
#' @noRd
.bag_bcdc_schtab <- function(pkg_list = NULL, pkg_name = NULL, row_idx = NULL) {
  ob_name <- pkg_list |>
    purrr::pluck(pkg_name) |>
    purrr::pluck("resources") |>
    purrr::pluck(row_idx) |>
    purrr::pluck("object_name")

  # pluck() returns NULL for a missing element, and tibble() drops a NULL column rather
  # than erroring -- so this row comes back 1x1. bind_rows() in bag_bcdc_index() then
  # NA-fills it, which is why the gap has never shown. It only bites when EVERY package
  # lacks object_name: bind_rows() yields no such column at all, and the mutate() that
  # lower-cases it fails with "object 'object_name' not found". Carrying NA keeps the
  # column present in that case.
  if (is.null(ob_name)) {
    ob_name <- NA_character_
  }

  tibble::tibble(object_name = ob_name, package_name = pkg_name, object_name_idx = row_idx)
}
