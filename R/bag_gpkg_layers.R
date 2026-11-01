#' The spatial layers of a GeoPackage, and their CRSs
#'
#' Internal. One answer to "which layers of this file hold geometry", for every function
#' here that opens a GeoPackage. There were two of them and they disagreed: one counted
#' spatial layers, the other counted every layer `sf::st_layers()` reports.
#'
#' That difference is not academic. A GeoPackage is a SQLite database, and QGIS saves a
#' layer's style into it as a plain table called `layer_styles`. `st_layers()` lists that
#' table — measured, even when it is not registered in `gpkg_contents` — with no geometry
#' type and a `crs` of `NA`. A styled Mergin field form is the documented input for both
#' functions, so the consumer that counted every layer refused the very files it is for,
#' and did so with a remedy ("set a CRS on it") that cannot be carried out on a style
#' table.
#'
#' The discriminator is the property rather than the name: a support table has no
#' geometry type. Matching on `"layer_styles"` would catch QGIS's table and miss every
#' other aspatial one.
#'
#' One consumer deliberately does not use this: `bag_layers()` calls `sf::st_layers()`
#' directly, because its whole job is to report what a data source contains — an
#' aspatial table is an answer there, not noise, and it is reported with a `geomtype` of
#' `NA`. That is the only raw `st_layers()` call left in the package.
#'
#' @param path [character] Path to a GeoPackage.
#'
#' @return A list with `name`, a character vector of the spatial layers' names, and
#'   `crs`, the matching list of their CRSs.
#'
#' @importFrom sf st_layers
#' @noRd
.bag_gpkg_layers <- function(path) {
  layers <- sf::st_layers(path)

  has_geom <- vapply(
    layers$geomtype,
    function(g) length(g) > 0 && !all(is.na(g)),
    logical(1)
  )

  list(name = layers$name[has_geom], crs = layers$crs[has_geom])
}
