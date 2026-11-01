# bcdata::bcdc_describe_feature() is mocked — no test here touches the network.

fake_feature <- function() {
  tibble::tibble(
    col_name = c("AIRPORT_NAME", "DESCRIPTION", "GEOMETRY"),
    local_col_type = c("character", "character", "sfc"),
    column_comments = c("Name of the airport", "A description", NA_character_),
    remote_col_type = c("xsd:string", "xsd:string", "gml:GeometryPropertyType")
  )
}

stub_describe <- function(f, value = fake_feature()) {
  mockery::stub(f, "bcdata::bcdc_describe_feature", function(...) value)
  f
}

testthat::test_that("bag_meta_bcd_xref_col_comments validates its arguments", {
  testthat::expect_error(
    bag_meta_bcd_xref_col_comments(1L, "airport_name"),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_meta_bcd_xref_col_comments("whse.table", 1L),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_meta_bcd_xref_col_comments(c("a", "b"), "airport_name"),
    class = "chk_error"
  )
})

testthat::test_that("bag_meta_bcd_xref_col_comments returns the documented columns", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_describe(bag_meta_bcd_xref_col_comments)
  out <- f("whse_imagery_and_base_maps.gsr_airports_svw", "airport_name")

  testthat::expect_named(out, c("object_name", "col_name", "col_type_local", "col_comments"))
  testthat::expect_equal(nrow(out), 1L)
  testthat::expect_equal(out$col_comments, "Name of the airport")
  testthat::expect_equal(out$col_type_local, "character")
})

testthat::test_that("bag_meta_bcd_xref_col_comments returns object_name as the caller gave it", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_describe(bag_meta_bcd_xref_col_comments)
  out <- f("WHSE_Imagery_And_Base_Maps.GSR_Airports_SVW", "airport_name")

  # upper-cased only for the query; the returned value is the caller's string
  testthat::expect_equal(out$object_name, "WHSE_Imagery_And_Base_Maps.GSR_Airports_SVW")
})

testthat::test_that("bag_meta_bcd_xref_col_comments upper-cases the object name for the query", {
  testthat::skip_if_not_installed("mockery")

  seen <- NULL
  f <- bag_meta_bcd_xref_col_comments
  mockery::stub(f, "bcdata::bcdc_describe_feature", function(x, ...) {
    seen <<- x
    fake_feature()
  })

  f("whse_imagery_and_base_maps.gsr_airports_svw", "airport_name")

  testthat::expect_equal(seen, "WHSE_IMAGERY_AND_BASE_MAPS.GSR_AIRPORTS_SVW")
})

testthat::test_that("bag_meta_bcd_xref_col_comments matches a column given in upper case", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_describe(bag_meta_bcd_xref_col_comments)

  # The donor compared the caller's `column` as given against a lower-cased col_name, so an
  # upper-case argument matched nothing: it warned and returned zero rows. Both spellings
  # must now find the column.
  lower <- f("whse.table", "airport_name")
  upper <- f("whse.table", "AIRPORT_NAME")

  testthat::expect_equal(nrow(upper), 1L)
  testthat::expect_equal(upper$col_comments, lower$col_comments)
})

testthat::test_that("bag_meta_bcd_xref_col_comments queries the service exactly once", {
  testthat::skip_if_not_installed("mockery")

  calls <- 0L
  f <- bag_meta_bcd_xref_col_comments
  mockery::stub(f, "bcdata::bcdc_describe_feature", function(...) {
    calls <<- calls + 1L
    fake_feature()
  })

  f("whse.table", "airport_name")

  # The donor called it twice — once inside a tryCatch for the error message, discarding
  # the value, and again for real.
  testthat::expect_equal(calls, 1L)
})

testthat::test_that("bag_meta_bcd_xref_col_comments aborts when the layer does not exist", {
  testthat::skip_if_not_installed("mockery")

  f <- bag_meta_bcd_xref_col_comments
  mockery::stub(f, "bcdata::bcdc_describe_feature", function(...) stop("no such feature type"))

  testthat::expect_error(f("whse.nope", "airport_name"), "does not exist")
})

testthat::test_that("bag_meta_bcd_xref_col_comments flags an absent column and returns no rows", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_describe(bag_meta_bcd_xref_col_comments)

  testthat::expect_message(f("whse.table", "not_a_column"), "not_a_column")
  out <- suppressMessages(f("whse.table", "not_a_column"))
  testthat::expect_equal(nrow(out), 0L)
})

testthat::test_that("bag_meta_bcd_xref_col_comments stays quiet for a column that exists", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_describe(bag_meta_bcd_xref_col_comments)

  # Guard against the alert firing unconditionally, which the test above cannot see.
  testthat::expect_silent(f("whse.table", "airport_name"))
})
