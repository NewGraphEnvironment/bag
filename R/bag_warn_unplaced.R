#' Warn that some rows have no usable coordinates
#'
#' Internal. Three functions here act on the same thing — a point layer's coordinates —
#' and a row whose geometry is empty, or whose coordinates are `NA`, is the same input to
#' all three. It is also a routine one: a field form row entered before the GPS has a fix.
#'
#' They used to disagree about it. One destroyed the row, one carried it through with
#' `NaN` and said nothing, and the third aborted from inside `sf` naming a `group_split()`
#' index. This is the one place that decides what to say, so the next function over this
#' container cannot quietly invent a fourth answer.
#'
#' @param n [integer] How many rows could not be placed.
#' @param cols [character] The columns that will be `NA` for them.
#' @param arg [character] The argument the rows came in through.
#'
#' @return `NULL`, invisibly. Called for the warning.
#'
#' @importFrom cli cli_warn qty
#' @noRd
.bag_warn_unplaced <- function(n, cols, arg = "dat") {
  if (n == 0) {
    return(invisible(NULL))
  }

  # cli resolves {?a/b} against the most recent quantity in the string it is formatting,
  # and each bullet is its own string -- hence the explicit qty() on the second.
  cli::cli_warn(c(
    "{n} row{?s} of {.arg {arg}} ha{?s/ve} no usable coordinates.",
    i = "{cli::qty(n)}{?Its/Their} {.field {cols}} {?is/are} NA; every other column is
         kept.",
    i = "An empty geometry, or an NA coordinate, does this."
  ))

  invisible(NULL)
}
