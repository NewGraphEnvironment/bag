#' Refresh a single-layer point GeoPackage's coordinate columns
#'
#' Reads a one-layer point GeoPackage, optionally refreshes its UTM columns with
#' [bag_assign_utm()], optionally applies a caller-supplied transformation, optionally
#' writes the result back over the GeoPackage, and writes `.csv` and `.RData` backups.
#'
#' It is named for the refresh rather than for the backups because
#' `write_back_to_path = TRUE` **overwrites `path_gpkg`**. The backups are a side effect,
#' not the contract.
#'
#' Both backups exist on purpose. The `.csv` is the versionable one; the `.RData` holds the
#' object exactly, because rebuilding it from the csv introduces small differences.
#'
#' @param path_gpkg [character] Path to a GeoPackage holding exactly one point layer.
#'   More than one *spatial* layer is refused, since which to refresh would be decided by
#'   layer order. Support tables carrying no geometry — QGIS's `layer_styles`, for one —
#'   are not counted, and survive the write-back.
#' @param dir_backup [character] Directory for the backups. Created if absent.
#' @param update_utm [logical] Refresh the UTM columns with [bag_assign_utm()]. Default
#'   `TRUE`.
#' @param fn_site_id A function applied to the data after the UTM step, or `NULL` (default)
#'   to apply nothing. It is called as `fn_site_id(dat)` and must return the data.
#'
#'   This is where the fish-passage package's site-id assignment is injected. That logic is
#'   about site identity rather than about files, so it stays in that package and is passed
#'   in rather than imported — neither package depends on the other.
#' @param write_back_to_path [logical] Overwrite the layer in `path_gpkg` with the result,
#'   keeping its name. Default `FALSE`. Only that layer is replaced, so a style saved into
#'   the GeoPackage is left alone.
#' @param write_to_csv [logical] Write a geometry-dropped `.csv` backup. Default `TRUE`.
#' @param write_to_rdata [logical] Write an `.RData` backup holding the object under the
#'   GeoPackage's base name. Default `TRUE`.
#' @param return_object [logical] Return the updated object. Default `FALSE`.
#' @param ... Passed to [bag_assign_utm()].
#'
#' @return The updated `sf` object when `return_object` is `TRUE`, otherwise `NULL`
#'   invisibly. Called for the files it writes.
#'
#' @seealso [bag_backup()] for a plain file copy, and [bag_assign_utm()] for the
#'   coordinate step.
#' @family files
#' @export
#'
#' @importFrom chk chk_dir chk_file chk_flag chk_function chk_string
#' @importFrom cli cli_abort
#' @importFrom fs dir_create path
#' @importFrom readr write_csv
#' @importFrom sf st_drop_geometry st_layers st_read st_write
#' @importFrom tools file_path_sans_ext
#'
#' @examples
#' \dontrun{
#' # refresh the coordinate columns and hand the object back, writing nothing
#' updated <- bag_gpkg_refresh(
#'   path_gpkg = "~/Projects/gis/my_project/form_fiss_site_2026.gpkg",
#'   write_to_csv = FALSE,
#'   write_to_rdata = FALSE,
#'   return_object = TRUE,
#'   # passed through to bag_assign_utm()
#'   col_easting = "utm_easting",
#'   col_northing = "utm_northing",
#'   sig_dig = 3
#' )
#' }
bag_gpkg_refresh <- function(path_gpkg = NULL,
                             dir_backup = "data/backup/",
                             update_utm = TRUE,
                             fn_site_id = NULL,
                             write_back_to_path = FALSE,
                             write_to_csv = TRUE,
                             write_to_rdata = TRUE,
                             return_object = FALSE,
                             ...) {

  chk::chk_file(path_gpkg)
  chk::chk_string(dir_backup)
  chk::chk_flag(update_utm)
  chk::chk_flag(write_back_to_path)
  chk::chk_flag(write_to_csv)
  chk::chk_flag(write_to_rdata)
  chk::chk_flag(return_object)
  if (!is.null(fn_site_id)) chk::chk_function(fn_site_id)

  # The documented precondition, enforced: st_read() with no `layer` silently takes the
  # first one, so a multi-layer GeoPackage would otherwise be read in part with nothing
  # said. Counted over SPATIAL layers only -- `st_layers()` also lists support tables
  # such as QGIS's `layer_styles`, and a styled Mergin field form is the documented use
  # case, so counting those refused the very files this function is for. The
  # discriminator is the property itself: a support table has no geometry type.
  layers <- .bag_gpkg_layers(path_gpkg)

  if (length(layers$name) != 1L) {
    cli::cli_abort(c(
      "{.arg path_gpkg} must hold exactly one spatial layer.",
      x = "{.path {path_gpkg}} holds {length(layers$name)}: {.val {layers$name}}.",
      i = "Which one to refresh would otherwise be decided by layer order."
    ))
  }
  layer_name <- layers$name

  # The same CRS check bag_gpkg_to_geojson() makes, for the same reason: a GeoPackage
  # layer with no spatial reference reads back as a real CRS object, not as NA, so
  # without this an `srs_id` of 0 was taken for WGS 84 and the UTM zone derived from
  # coordinates that are not degrees, while -1 aborted out of GDAL naming neither the
  # layer nor the CRS.
  if (.bag_crs_unusable(layers$crs[[1]])) {
    cli::cli_abort(c(
      "The layer in {.arg path_gpkg} has no usable CRS.",
      x = "{.path {path_gpkg}}, layer {.val {layer_name}}.",
      i = "Coordinates are derived by reprojecting, so the layer's CRS has to be known.",
      i = "Set one with {.fn sf::st_crs} first."
    ))
  }

  dat <- sf::st_read(dsn = path_gpkg, layer = layer_name, quiet = TRUE)

  .bag_chk_sf_point(dat, arg = "the layer in path_gpkg")

  if (update_utm) {
    dat <- bag_assign_utm(dat, ...)
  }

  if (!is.null(fn_site_id)) {
    dat <- fn_site_id(dat)
    # A callback that returns the wrong shape would otherwise be written to disk.
    .bag_chk_sf_point(dat, arg = "the result of fn_site_id")
  }

  if (write_back_to_path) {
    # Two departures from the donor, which wrote `delete_dsn = TRUE` and no `layer`.
    #
    # `layer` is explicit because st_write() otherwise names the layer after the file's
    # base name, so a layer called `sites` in `form_fiss_site_2026.gpkg` came back called
    # `form_fiss_site_2026`, breaking every QGIS project, Mergin form and script naming
    # it. The donor at least wrote without `quiet = TRUE`, so a user saw the rename.
    #
    # `delete_layer` replaces that one layer; `delete_dsn` deleted the whole GeoPackage
    # and rebuilt it, which destroyed everything else in the file -- a saved QGIS style
    # in `layer_styles`, and `gpkg_metadata`, which no count of layers can even see.
    # Measured: with `delete_layer` the style table and its rows survive, and a changed
    # column set still lands.
    sf::st_write(
      dat, path_gpkg,
      layer = layer_name, append = FALSE, delete_layer = TRUE, quiet = TRUE
    )
  }

  if (write_to_csv) {
    fs::dir_create(dir_backup)
    dat |>
      sf::st_drop_geometry() |>
      readr::write_csv(
        fs::path(dir_backup, paste0(tools::file_path_sans_ext(basename(path_gpkg)), ".csv")),
        na = ""
      )
  }

  if (write_to_rdata) {
    fs::dir_create(dir_backup)

    # The object is renamed so the .RData carries an informative name rather than "dat".
    # It is bound in a scratch environment, not this function's own frame: a GeoPackage
    # called `dat.gpkg` otherwise rebound -- and then rm()'d -- the working object, so the
    # call died at `return(dat)`, and `obj_name.gpkg` handed save() an sf object where it
    # wanted a name. Both aborted after write_back_to_path had already rewritten the file.
    obj_name <- tools::file_path_sans_ext(basename(path_gpkg))
    env_save <- new.env(parent = emptyenv())
    assign(obj_name, dat, envir = env_save)
    save(
      list = obj_name,
      envir = env_save,
      file = fs::path(dir_backup, obj_name, ext = "RData")
    )
  }

  if (return_object) {
    return(dat)
  }

  invisible(NULL)
}
