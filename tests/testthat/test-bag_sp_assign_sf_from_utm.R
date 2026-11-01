utm_frame <- function() {
  # Three sites in three different NAD 83 UTM zones, as a plain data frame.
  data.frame(
    site = c("z9", "z10", "z11"),
    utm_zone = c(9, 10, 11),
    easting = c(464000, 532000, 601000),
    northing = c(6043000, 6042000, 6041000),
    stringsAsFactors = FALSE
  )
}

testthat::test_that("bag_sp_assign_sf_from_utm rejects input that is not a data frame", {
  testthat::expect_error(bag_sp_assign_sf_from_utm(NULL), "not NULL")
  testthat::expect_error(bag_sp_assign_sf_from_utm(1:3), "data frame")
})

testthat::test_that("bag_sp_assign_sf_from_utm validates its arguments", {
  d <- utm_frame()

  testthat::expect_error(bag_sp_assign_sf_from_utm(d, col_utm_zone = 1L), class = "chk_error")
  testthat::expect_error(bag_sp_assign_sf_from_utm(d, col_easting = 1L), class = "chk_error")
  testthat::expect_error(bag_sp_assign_sf_from_utm(d, col_northing = 1L), class = "chk_error")
  testthat::expect_error(bag_sp_assign_sf_from_utm(d, crs_return = "3005"), class = "chk_error")
})

testthat::test_that("bag_sp_assign_sf_from_utm reports a missing coordinate column by name", {
  # This is tibble's own reporting, not a guard of ours -- one was written and removed
  # because it duplicated this and no mutation could distinguish them. Pinned because it is
  # the observable contract, whoever produces it.
  d <- utm_frame()
  d$easting <- NULL

  testthat::expect_error(bag_sp_assign_sf_from_utm(d), "easting")
})

testthat::test_that("bag_sp_assign_sf_from_utm reports every missing column at once", {
  d <- utm_frame()
  d$easting <- NULL
  d$northing <- NULL

  err <- testthat::expect_error(bag_sp_assign_sf_from_utm(d))
  testthat::expect_match(conditionMessage(err), "easting")
  testthat::expect_match(conditionMessage(err), "northing")
})

testthat::test_that("bag_sp_assign_sf_from_utm returns an sf object in crs_return", {
  testthat::skip_if_not_installed("sf")

  out <- bag_sp_assign_sf_from_utm(utm_frame())

  testthat::expect_s3_class(out, "sf")
  testthat::expect_equal(sf::st_crs(out)$epsg, 3005)
  testthat::expect_equal(nrow(out), 3L)
})

testthat::test_that("bag_sp_assign_sf_from_utm honours crs_return", {
  testthat::skip_if_not_installed("sf")

  out <- bag_sp_assign_sf_from_utm(utm_frame(), crs_return = 4326)

  testthat::expect_equal(sf::st_crs(out)$epsg, 4326)
})

testthat::test_that("bag_sp_assign_sf_from_utm reads each row in its own zone", {
  testthat::skip_if_not_installed("sf")

  out <- bag_sp_assign_sf_from_utm(utm_frame(), crs_return = 4326)
  lon <- sf::st_coordinates(out)[, 1]

  # Each zone's easting means a different longitude. If one CRS were applied to all three
  # rows, the longitudes would cluster instead of spreading across the three zone bands.
  testthat::expect_true(all(lon > -140 & lon < -110))
  testthat::expect_gt(diff(range(lon)), 5)
})

testthat::test_that("bag_sp_assign_sf_from_utm keeps the coordinate columns", {
  testthat::skip_if_not_installed("sf")

  out <- bag_sp_assign_sf_from_utm(utm_frame())

  # remove = FALSE in the donor
  testthat::expect_true(all(c("easting", "northing", "utm_zone") %in% names(out)))
})

testthat::test_that("bag_sp_assign_utm and bag_sp_assign_sf_from_utm round trip", {
  testthat::skip_if_not_installed("sf")

  # The strongest property available: build points, read their UTM columns, rebuild from
  # those columns, and land back on the same ground. Either function alone could be
  # self-consistently wrong; together they cannot.
  start <- sf::st_as_sf(
    data.frame(
      site = c("z9", "z10", "z11"),
      lon = c(-128.5, -123.5, -118.5),
      lat = c(54.5, 54.5, 54.5)
    ),
    coords = c("lon", "lat"), crs = 4326
  )

  with_utm <- suppressWarnings(bag_sp_assign_utm(start, sig_dig = 3))
  rebuilt <- bag_sp_assign_sf_from_utm(sf::st_drop_geometry(with_utm), crs_return = 4326)

  a <- sf::st_coordinates(with_utm)[order(with_utm$site), ]
  b <- sf::st_coordinates(rebuilt)[order(rebuilt$site), ]

  # a metre or so, which is what rounding the easting to three decimals leaves
  testthat::expect_equal(unname(a), unname(b), tolerance = 1e-4)
})
