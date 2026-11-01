#' Remove layers from a GeoPackage
#'
#' @description
#' `r lifecycle::badge("superseded")`
#'
#' Superseded by
#' [gdalraster::ogr_layer_delete()](https://github.com/USDAForestService/gdalraster), which
#' deletes a layer in place rather than rebuilding the file.
#'
#' Rebuilds the GeoPackage with the named layers left out, by copying every other layer
#' into a temporary file with `ogr2ogr` and then replacing the original.
#'
#' @param path_gpkg [character] Path to the GeoPackage.
#' @param layers_remove [character] Layers to remove. Every one must exist in the file.
#'
#' @return `NULL`, invisibly. Called for its effect on `path_gpkg`.
#'
#' @seealso [bag_layer_info()] for listing what a GeoPackage holds.
#' @family files
#' @export
#'
#' @importFrom chk chk_character chk_file chk_string
#' @importFrom cli cli_abort
#' @importFrom sf st_layers
#'
#' @examples
#' \dontrun{
#' bag_u_rm_gpkg_layers(
#'   path_gpkg = "~/gis/background_layers.gpkg",
#'   layers_remove = c("old_sites", "scratch")
#' )
#' }
bag_u_rm_gpkg_layers <- function(path_gpkg, layers_remove) {

  chk::chk_string(path_gpkg)
  chk::chk_file(path_gpkg)
  chk::chk_character(layers_remove)

  # Sys.which(), matching bag_url(). The donor compared system2("which", ...)'s status,
  # which is the same test spelled less portably.
  if (!nzchar(Sys.which("ogr2ogr"))) {
    cli::cli_abort(c(
      "{.code ogr2ogr} is not on the PATH.",
      i = "Please install GDAL. On a Mac, {.code brew install gdal}."
    ))
  }

  # A GeoPackage is a SQLite database, so a byte copy is only a snapshot when no write
  # ahead log or rollback journal is beside it. With one present, the file alone is not the
  # database and replacing it loses whatever the sidecar held.
  sidecars <- paste0(path_gpkg, c("-wal", "-shm", "-journal"))
  present <- sidecars[file.exists(sidecars)]
  if (length(present) > 0) {
    cli::cli_abort(c(
      "{.path {path_gpkg}} has {length(present)} SQLite sidecar file{?s} beside it.",
      x = "{.path {basename(present)}}",
      i = "Close whatever has the GeoPackage open, so the sidecar is checkpointed away."
    ))
  }

  all_layers <- sf::st_layers(path_gpkg)$name

  missing <- setdiff(layers_remove, all_layers)
  if (length(missing) > 0) {
    # One abort naming every missing layer, rather than aborting on the first. cli
    # interpolates here; the donor glued the message with glue() first and handed the
    # result to cli_abort(), which then re-read any braces the data contained.
    # The quantity comes first and there is one marker. cli resolves {?s} against the most
    # recent substitution, so a marker placed before any substitution -- or two markers
    # with a different quantity between them -- fails with "Multiple quantities for
    # pluralization", which replaces the whole message and hides what was missing.
    cli::cli_abort(
      "{length(missing)} layer{?s} not in {.path {path_gpkg}}: {.val {missing}}."
    )
  }

  layers_keep <- setdiff(all_layers, layers_remove)

  if (length(layers_keep) == 0) {
    cli::cli_abort(c(
      "That would remove every layer in {.path {path_gpkg}}.",
      i = "Delete the file instead if that is what you want."
    ))
  }

  temp_gpkg <- tempfile(fileext = ".gpkg")
  on.exit(unlink(temp_gpkg), add = TRUE)

  for (layer in layers_keep) {
    args <- c("-f", "GPKG", temp_gpkg, path_gpkg, layer, "-nln", layer, "-update", "-append")
    status <- system2("ogr2ogr", args = shQuote(args), stdout = FALSE, stderr = FALSE)
    # system2(stdout = TRUE) only WARNS on a non-zero exit, so the donor could not see a
    # failed copy -- and it overwrote the original regardless, leaving a GeoPackage missing
    # layers nobody asked to remove. Read the status.
    if (!identical(as.integer(status), 0L)) {
      cli::cli_abort("{.code ogr2ogr} failed with status {status} copying layer {.val {layer}}.")
    }
  }

  # The temp file must hold exactly what we meant to keep before the original is replaced.
  # This is the check that makes the overwrite safe, and it is cheap.
  # file.exists() first: ogr2ogr can report success and write nothing, and st_layers() on
  # a path that is not there aborts with GDAL's "Open failed" rather than reaching the
  # comparison below.
  written <- if (file.exists(temp_gpkg)) sf::st_layers(temp_gpkg)$name else character(0)
  if (!setequal(written, layers_keep)) {
    cli::cli_abort(c(
      "The rebuilt GeoPackage does not hold the layers it should; {.path {path_gpkg}} is unchanged.",
      i = "Expected {.val {sort(layers_keep)}}.",
      x = "Got {.val {sort(written)}}."
    ))
  }

  if (!file.copy(temp_gpkg, path_gpkg, overwrite = TRUE)) {
    cli::cli_abort("Could not replace {.path {path_gpkg}} with the rebuilt GeoPackage.")
  }

  invisible(NULL)
}
