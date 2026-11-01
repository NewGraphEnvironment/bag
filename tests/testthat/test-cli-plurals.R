# A package-wide guard, not a test of one function.
#
# Four times during this branch a cli plural marker went in without a usable quantity in
# its own string, and each was found by a message rendering wrongly at run time rather
# than by anything in the suite. cli resolves `{?a/b}` against the most recent quantity
# in the string it is formatting, and every bullet of a cli_abort()/cli_warn() vector is
# formatted separately -- so a marker in a bullet with no substitution of its own either
# renders at quantity 1 forever, or aborts with "Cannot pluralize without a quantity".
#
# A one-time sweep closed the class and then new code reopened it, which is the argument
# for making the sweep a test. This parses R/ rather than recalling what is there, so a
# marker added tomorrow is covered without anyone remembering to add a case.

testthat::test_that("every cli plural marker in R/ has a quantity in its own string", {
  dir_r <- testthat::test_path("..", "..", "R")
  testthat::skip_if_not(dir.exists(dir_r), "source tree not available (installed tests)")

  files <- list.files(dir_r, pattern = "[.]R$", full.names = TRUE)
  testthat::expect_gt(length(files), 0)

  # String literals, via the parser rather than a regex over the raw text, so a `{?` in
  # a comment is not mistaken for one in a message.
  strings <- unlist(lapply(files, function(f) {
    pd <- utils::getParseData(parse(f, keep.source = TRUE))
    pd$text[pd$token == "STR_CONST"]
  }))
  marked <- grep("{?", strings, fixed = TRUE, value = TRUE)
  testthat::expect_gt(length(marked), 0)

  # The quantity has to be set BEFORE the first marker, in the same string. Any
  # interpolation does it, including an explicit cli::qty().
  missing_qty <- vapply(marked, function(s) {
    head <- substr(s, 1, regexpr("{?", s, fixed = TRUE) - 1)
    !grepl("\\{[^{}?][^{}]*\\}", head)
  }, logical(1))

  testthat::expect_equal(
    unname(which(missing_qty)), integer(0),
    info = paste(
      "cli plural marker with no preceding quantity:\n",
      paste(marked[missing_qty], collapse = "\n ")
    )
  )
})
