# The donors' version of this guard never fired, for any input. These tests exist so that
# cannot happen again quietly: one case per branch, and a polygon case that the donor's
# condition waved through.

pt <- function(n = 2) {
  sf::st_as_sf(
    data.frame(lon = seq(-128.5, -128.5 + (n - 1) / 10, length.out = n), lat = rep(54.5, n)),
    coords = c("lon", "lat"), crs = 4326
  )
}

pg <- function() {
  sf::st_sf(
    id = 1,
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = 4326
    )
  )
}

mpt <- function() {
  sf::st_sf(
    id = 1,
    geometry = sf::st_sfc(sf::st_multipoint(cbind(c(0, 1), c(0, 1))), crs = 4326)
  )
}

testthat::test_that("bag_chk_sf_point accepts an sf POINT object", {
  testthat::skip_if_not_installed("sf")
  testthat::expect_silent(bag_chk_sf_point(pt()))
  testthat::expect_identical(bag_chk_sf_point(pt()), pt())
})

testthat::test_that("bag_chk_sf_point rejects NULL", {
  testthat::expect_error(bag_chk_sf_point(NULL), "not NULL")
})

testthat::test_that("bag_chk_sf_point rejects a non data frame", {
  testthat::expect_error(bag_chk_sf_point(1:3), "data frame")
})

testthat::test_that("bag_chk_sf_point rejects a plain data frame", {
  testthat::expect_error(bag_chk_sf_point(data.frame(a = 1)), "sf")
})

testthat::test_that("bag_chk_sf_point rejects POLYGON geometry", {
  testthat::skip_if_not_installed("sf")

  # This is the case the donors' guard waved through. `!` binds looser than `!=` in R, so
  # `!class != "sfc_point"` is `class == "sfc_point"`, and the class sf sets is
  # "sfc_POINT" -- false for a point layer AND for this one, so nothing ever aborted.
  testthat::expect_error(bag_chk_sf_point(pg()), "POINT geometry")
})

testthat::test_that("bag_chk_sf_point rejects MULTIPOINT geometry", {
  testthat::skip_if_not_installed("sf")

  # Not pedantry: the callers do st_coordinates(x)[, 1] and assign it as a column, which
  # for MULTIPOINT has more rows than features and fails several steps later.
  testthat::expect_error(bag_chk_sf_point(mpt()), "POINT geometry")
})

testthat::test_that("bag_chk_sf_point names the geometry it got", {
  testthat::skip_if_not_installed("sf")

  err <- testthat::expect_error(bag_chk_sf_point(pg()))
  testthat::expect_match(conditionMessage(err), "sfc_POLYGON")
})

testthat::test_that("bag_chk_sf_point uses the argument name it is given", {
  testthat::expect_error(bag_chk_sf_point(NULL, arg = "the layer in path_gpkg"), "path_gpkg")
})
