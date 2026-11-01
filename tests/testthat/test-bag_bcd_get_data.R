# bcdata::bcdc_query_geodata() and bcdata::collect() are mocked — no test here touches the
# network. The collect() stub calls force(x) for the reason recorded in test-bag_bcdata.R:
# the native pipe nests the query inside collect(), so without it the query is never
# evaluated and a spy on the record id never fires.

fake_layer <- function(n = 2L, cols = c("AIRPORT_NAME", "DESCRIPTION")) {
  vals <- lapply(cols, function(nm) rep(paste0("v_", nm), n))
  names(vals) <- cols
  d <- as.data.frame(vals, stringsAsFactors = FALSE)
  if (n == 0L) d <- d[0, , drop = FALSE]
  sf::st_sf(
    d,
    geometry = sf::st_sfc(
      lapply(seq_len(n), function(i) sf::st_point(c(1000000 + i, 1000000 + i))),
      crs = 3005
    )
  )
}

# dplyr::filter() is stubbed to a pass-through as well. The real bcdc_query_geodata()
# returns a bcdc_promise that dplyr dispatches on and translates to CQL; a stub cannot
# produce one, so filtering itself is bcdata's to test. What these tests pin is the
# arguments this function hands it -- the spy on rlang::sym() below is what checks the
# column name was upper-cased.
stub_bcdata <- function(f, layer = fake_layer(), on_query = NULL) {
  mockery::stub(f, "bcdata::bcdc_query_geodata", function(record, ...) {
    if (!is.null(on_query)) on_query(record)
    record
  })
  mockery::stub(f, "dplyr::filter", function(.data, ...) .data)
  mockery::stub(f, "bcdata::collect", function(x, ...) {
    force(x)
    layer
  })
  f
}

testthat::test_that("bag_bcd_get_data validates its arguments", {
  testthat::expect_error(bag_bcd_get_data(1L), class = "chk_error")
  testthat::expect_error(bag_bcd_get_data(c("a", "b")), class = "chk_error")
  testthat::expect_error(
    bag_bcd_get_data("bc-airports", drop_geom = "yes"),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_bcd_get_data("bc-airports", col_filter = 1L, col_filter_value = "x"),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_bcd_get_data("bc-airports", col_filter = "A", col_filter_value = 1L),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_bcd_get_data("bc-airports", col_extract = 1L),
    class = "chk_error"
  )
})

testthat::test_that("bag_bcd_get_data requires col_filter_value alongside col_filter", {
  testthat::expect_error(
    bag_bcd_get_data("bc-airports", col_filter = "FUNDING_PROJECT_NUMBER"),
    "col_filter_value"
  )
})

testthat::test_that("bag_bcd_get_data lower-cases a record id with no period", {
  testthat::skip_if_not_installed("mockery")

  seen <- NULL
  f <- stub_bcdata(bag_bcd_get_data, on_query = function(r) seen <<- r)
  f("BC-Airports")

  testthat::expect_equal(seen, "bc-airports")
})

testthat::test_that("bag_bcd_get_data upper-cases a record id containing a period", {
  testthat::skip_if_not_installed("mockery")

  seen <- NULL
  f <- stub_bcdata(bag_bcd_get_data, on_query = function(r) seen <<- r)
  f("whse_fish.pscis_assessment_svw")

  testthat::expect_equal(seen, "WHSE_FISH.PSCIS_ASSESSMENT_SVW")
})

testthat::test_that("bag_bcd_get_data cleans the column names", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_bcdata(bag_bcd_get_data)
  out <- f("bc-airports")

  testthat::expect_true(all(c("airport_name", "description") %in% names(out)))
  testthat::expect_false("AIRPORT_NAME" %in% names(out))
})

testthat::test_that("bag_bcd_get_data keeps the geometry by default and drops it on request", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  f <- stub_bcdata(bag_bcd_get_data)

  kept <- f("bc-airports")
  testthat::expect_s3_class(kept, "sf")

  dropped <- f("bc-airports", drop_geom = TRUE)
  testthat::expect_false(inherits(dropped, "sf"))
  testthat::expect_false("geometry" %in% names(dropped))
})

testthat::test_that("bag_bcd_get_data keeps only col_extract", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_bcdata(bag_bcd_get_data)
  out <- f("bc-airports", col_extract = "AIRPORT_NAME", drop_geom = TRUE)

  testthat::expect_equal(names(out), "airport_name")
})

testthat::test_that("bag_bcd_get_data upper-cases col_extract before selecting", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_bcdata(bag_bcd_get_data)

  # the fixture's columns are upper case, so a lower-case argument only works if the
  # function upper-cases it first
  out <- f("bc-airports", col_extract = "airport_name", drop_geom = TRUE)
  testthat::expect_equal(names(out), "airport_name")
})

testthat::test_that("bag_bcd_get_data upper-cases col_filter before filtering", {
  testthat::skip_if_not_installed("mockery")

  # Capture the expression dplyr::filter is handed, not a spy on rlang::sym(). A
  # pass-through stub of the shape function(.data, ...) never forces `...`, so a spy on
  # sym() is never called and the assertion compares NULL -- the first draft of this test
  # failed that way. The label is also the property worth pinning: what column name
  # actually reaches the filter.
  seen <- NULL
  f <- bag_bcd_get_data
  mockery::stub(f, "bcdata::bcdc_query_geodata", function(record, ...) record)
  mockery::stub(f, "dplyr::filter", function(.data, ...) {
    seen <<- vapply(rlang::enquos(...), rlang::as_label, character(1))
    .data
  })
  mockery::stub(f, "bcdata::collect", function(x, ...) {
    force(x)
    fake_layer()
  })

  f("bc-airports", col_filter = "funding_project_number", col_filter_value = "x")

  testthat::expect_length(seen, 1L)
  testthat::expect_match(seen, "FUNDING_PROJECT_NUMBER")
  testthat::expect_no_match(seen, "funding_project_number")
})

testthat::test_that("bag_bcd_get_data aborts on an empty result when a filter was given", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_bcdata(bag_bcd_get_data, layer = fake_layer(0L))

  testthat::expect_error(
    f("bc-airports", col_filter = "A", col_filter_value = "nope"),
    "No records found"
  )
})

testthat::test_that("bag_bcd_get_data aborts on an empty result when col_extract was given", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_bcdata(bag_bcd_get_data, layer = fake_layer(0L))

  testthat::expect_error(
    f("bc-airports", col_extract = "AIRPORT_NAME"),
    "No records found"
  )
})

testthat::test_that("bag_bcd_get_data returns an empty result when neither argument was given", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_bcdata(bag_bcd_get_data, layer = fake_layer(0L))

  # An empty layer is a fact about the layer, not a failed query, so this must NOT abort.
  # Without this the abort could be made unconditional and every other test would pass.
  out <- f("bc-airports")
  testthat::expect_equal(nrow(out), 0L)
})
