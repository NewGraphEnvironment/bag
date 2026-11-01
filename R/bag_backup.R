#' Back up a file, with an optional timestamp
#'
#' Copies a file into a backup directory, appending a stamp to the name so successive
#' backups sit alongside each other rather than replacing one another.
#'
#' @param path_dir_in [character] Directory holding the file.
#' @param path_in_file [character] Name of the file, within `path_dir_in`.
#' @param path_dir_out [character] Directory to copy into. Created if absent.
#' @param stamp [character] Appended to the file's base name, before the extension.
#'   Defaults to the current time as `YYYYMMDDHHMM`. `NULL` appends nothing, which means
#'   the backup collides with any earlier one of the same name.
#'
#' @return [character] The path written, invisibly.
#'
#' @seealso [bag_gpkg_refresh()] for a GeoPackage whose coordinate columns are refreshed
#'   as well, with csv and RData copies alongside.
#' @family files
#' @export
#'
#' @importFrom chk chk_file chk_string
#' @importFrom cli cli_abort cli_alert_success
#' @importFrom fs dir_create file_copy path path_ext path_ext_remove
#'
#' @examples
#' \dontrun{
#' bag_backup(
#'   path_dir_in = file.path(tempdir(), "my_project"),
#'   path_in_file = "background_layers.gpkg",
#'   path_dir_out = file.path(tempdir(), "backups")
#' )
#' }
bag_backup <- function(path_dir_in,
                       path_in_file,
                       path_dir_out,
                       stamp = format(Sys.time(), "%Y%m%d%H%M")) {

  chk::chk_string(path_dir_in)
  chk::chk_string(path_in_file)
  chk::chk_string(path_dir_out)
  if (!is.null(stamp)) chk::chk_string(stamp)

  path_from <- fs::path(path_dir_in, path_in_file)
  chk::chk_file(path_from)

  fs::dir_create(path_dir_out)

  base_name <- fs::path_ext_remove(path_in_file)
  if (!is.null(stamp)) {
    base_name <- paste0(base_name, "_", stamp)
  }

  path_out_file <- fs::path(
    path_dir_out,
    base_name,
    ext = fs::path_ext(path_in_file)
  )

  # fs::file_copy() refuses an existing target rather than overwriting it, which is the
  # safe direction. Say why, since with stamp = NULL a second run always lands here.
  if (file.exists(path_out_file)) {
    cli::cli_abort(c(
      "{.path {path_out_file}} already exists.",
      i = "Pass a different {.arg stamp}, or remove the existing backup."
    ))
  }

  fs::file_copy(path_from, path_out_file)

  cli::cli_alert_success("Backup created at {.path {path_out_file}}")

  invisible(path_out_file)
}
