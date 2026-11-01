pts <- function(crs = 3005) {
  d <- sf::st_as_sf(
    data.frame(site = c("a", "b"), lon = c(-128.5, -123.5), lat = c(54.5, 50.5)),
    coords = c("lon", "lat"), crs = 4326
  )
  if (crs != 4326) d <- sf::st_transform(d, crs)
  d
}

testthat::test_that("bag_sp_assign_latlong rejects input that is not sf POINT", {
  testthat::skip_if_not_installed("sf")

  testthat::expect_error(bag_sp_assign_latlong(NULL), "not NULL")
  testthat::expect_error(bag_sp_assign_latlong(data.frame(a = 1)), "sf")
})

testthat::test_that("bag_sp_assign_latlong validates the column name arguments", {
  testthat::skip_if_not_installed("sf")

  testthat::expect_error(bag_sp_assign_latlong(pts(), col_lat = 1L), class = "chk_error")
  testthat::expect_error(bag_sp_assign_latlong(pts(), col_lon = 1L), class = "chk_error")
})

testthat::test_that("bag_sp_assign_latlong appends lat and lon", {
  testthat::skip_if_not_installed("sf")

  out <- bag_sp_assign_latlong(pts())

  testthat::expect_true(all(c("lat", "lon") %in% names(out)))
  testthat::expect_equal(nrow(out), 2L)
})

testthat::test_that("bag_sp_assign_latlong returns WGS 84 degrees, whatever the input CRS", {
  testthat::skip_if_not_installed("sf")

  out <- bag_sp_assign_latlong(pts(3005))

  # If the transform to 4326 were skipped, these would be BC Albers metres.
  testthat::expect_true(all(out$lon > -140 & out$lon < -110))
  testthat::expect_true(all(out$lat > 45 & out$lat < 62))
})

testthat::test_that("bag_sp_assign_latlong round trips to the input CRS", {
  testthat::skip_if_not_installed("sf")

  for (crs in c(3005, 4326, 26909)) {
    out <- bag_sp_assign_latlong(pts(crs))
    testthat::expect_equal(sf::st_crs(out)$epsg, crs)
  }
})

testthat::test_that("bag_sp_assign_latlong honours custom column names", {
  testthat::skip_if_not_installed("sf")

  out <- bag_sp_assign_latlong(pts(), col_lon = "long")

  testthat::expect_true("long" %in% names(out))
  testthat::expect_false("lon" %in% names(out))
})

testthat::test_that("bag_sp_assign_latlong leaves the geometry unmoved", {
  testthat::skip_if_not_installed("sf")

  d <- pts(3005)
  out <- bag_sp_assign_latlong(d)

  # The CRS round trip must return the same coordinates, not merely the same CRS.
  testthat::expect_equal(
    unname(sf::st_coordinates(out)),
    unname(sf::st_coordinates(d)),
    tolerance = 1e-6
  )
})
