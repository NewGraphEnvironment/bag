#' Check that an object is an sf data frame of POINT geometry
#'
#' Internal. The four coordinate and backup helpers ported from the fish-passage package
#' each repeated the same four checks, so they are factored out here.
#'
#' The geometry check is the one that changed on the way in. The donors wrote it as
#'
#' ```r
#' if (!attributes(sf::st_geometry(dat))$class[1] != "sfc_point")
#'   cli::cli_abort('"dat" must be a point simple feature object')
#' ```
#'
#' In R, `!` binds **looser** than `!=` (`?Syntax`), so `!x != y` is `!(x != y)`, which is
#' `x == y` — not `(!x) != y`, which would have errored, since `!` on a character is an
#' invalid argument type. The condition therefore read *"abort when the class IS
#' `sfc_point`"*, and the class sf actually sets is `sfc_POINT`, in upper case. So the guard
#' was false for every input and **never fired, on a point layer or a polygon one**.
#'
#' Removing the `!` would not have fixed it either: the case mismatch alone would then have
#' aborted on every valid point layer, which is the opposite failure. Hence `inherits()`
#' against the class sf sets.
#'
#' Note this guard now fires where it never did. That is deliberate — the callers compute
#' `sf::st_coordinates(x)[, 1]` and assign it as a column, which for MULTIPOINT returns
#' more rows than features and fails with a length error several steps later.
#'
#' A **zero-feature** layer is accepted, because `sf::st_read()` returns `sfc_GEOMETRY`
#' for one however the file declares its type — measured on a GeoPackage whose
#' `st_layers()` reports `geomtype` `Point` and `features` 0. A freshly created,
#' not-yet-filled field form is exactly that, and rejecting it would report "its geometry
#' is `<sfc_GEOMETRY>`", which is false: it is a point layer with nothing in it. The
#' MULTIPOINT consequence the guard exists for cannot arise with no features.
#'
#' @param dat The object to check.
#' @param arg [character] The argument name to use in the message.
#'
#' @return `dat`, invisibly, when it passes.
#'
#' @importFrom cli cli_abort
#' @importFrom sf st_geometry
#' @noRd
.bag_chk_sf_point <- function(dat, arg = "dat") {
  if (is.null(dat)) {
    cli::cli_abort("{.arg {arg}} must be an sf data frame of POINT geometry, not NULL.")
  }
  if (!is.data.frame(dat)) {
    cli::cli_abort("{.arg {arg}} must inherit from a data frame.")
  }
  if (!inherits(dat, "sf")) {
    cli::cli_abort("{.arg {arg}} must be an {.cls sf} object.")
  }
  geom <- sf::st_geometry(dat)
  if (length(geom) > 0 && !inherits(geom, "sfc_POINT")) {
    cli::cli_abort(c(
      "{.arg {arg}} must have POINT geometry.",
      x = "Its geometry is {.cls {class(geom)[1]}}."
    ))
  }
  invisible(dat)
}
