#' Is a CRS unusable for a transform to WGS 84?
#'
#' Internal. A GeoPackage layer with no spatial reference does not read back as a missing
#' CRS: GDAL's GPKG driver resolves the format's reserved `srs_id` values into real CRS
#' objects. `-1` ("undefined Cartesian") becomes an `ENGCRS` that `sf::st_transform()`
#' cannot use at all, and `0` ("undefined geographic") becomes a `GEOGCRS` that transforms
#' without complaint, silently taking the coordinates for WGS 84.
#'
#' So `is.na(sf::st_crs(x))` is a branch with no reachable true case for GeoPackage input.
#' This tests three things instead: a genuinely missing CRS, either of those two
#' placeholders by name, and — as the backstop that does not depend on GDAL's wording —
#' whether a point in that CRS can actually be transformed to 4326.
#'
#' @param crs A [sf::st_crs()] object, or `NA`.
#'
#' @return `TRUE` when the CRS cannot carry coordinates to WGS 84 meaningfully.
#'
#' @importFrom sf st_crs st_point st_sfc st_transform
#' @noRd
.bag_crs_unusable <- function(crs) {
  if (is.na(crs)) {
    return(TRUE)
  }

  # GDAL names both reserved placeholders "Undefined ... SRS". Matched case-insensitively
  # on the leading word only, so a real CRS whose name happens to contain the word
  # elsewhere is not caught by accident.
  crs_name <- if (is.null(crs$Name)) "" else crs$Name
  if (grepl("^undefined", crs_name, ignore.case = TRUE)) {
    return(TRUE)
  }

  # The property itself, for anything the name check does not recognise.
  probe <- try(
    suppressWarnings(sf::st_transform(sf::st_sfc(sf::st_point(c(0, 0)), crs = crs), 4326)),
    silent = TRUE
  )
  inherits(probe, "try-error")
}
