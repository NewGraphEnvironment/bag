# Points chosen to straddle UTM zones 9, 10 and 11, because the grouped transform is the
# part that can go wrong and a single-zone fixture cannot reach it.

three_zones <- function(crs = 4326) {
  d <- sf::st_as_sf(
    data.frame(
      site = c("z9", "z10", "z11"),
      lon = c(-128.5, -123.5, -118.5),
      lat = c(54.5, 54.5, 54.5)
    ),
    coords = c("lon", "lat"), crs = 4326
  )
  if (crs != 4326) d <- sf::st_transform(d, crs)
  d
}

testthat::test_that("bag_sp_assign_utm rejects input that is not sf POINT", {
  testthat::skip_if_not_installed("sf")

  testthat::expect_error(bag_sp_assign_utm(NULL), "not NULL")
  testthat::expect_error(bag_sp_assign_utm(data.frame(a = 1)), "sf")
})

testthat::test_that("bag_sp_assign_utm validates the column name arguments", {
  testthat::skip_if_not_installed("sf")
  d <- three_zones()

  testthat::expect_error(bag_sp_assign_utm(d, col_zone = 1L), class = "chk_error")
  testthat::expect_error(bag_sp_assign_utm(d, col_easting = 1L), class = "chk_error")
  testthat::expect_error(bag_sp_assign_utm(d, col_northing = 1L), class = "chk_error")
})

testthat::test_that("bag_sp_assign_utm assigns the three columns", {
  testthat::skip_if_not_installed("sf")

  out <- suppressWarnings(bag_sp_assign_utm(three_zones()))

  testthat::expect_true(all(c("utm_zone", "easting", "northing") %in% names(out)))
  testthat::expect_equal(nrow(out), 3L)
})

testthat::test_that("bag_sp_assign_utm derives the zone from longitude", {
  testthat::skip_if_not_installed("sf")

  out <- suppressWarnings(bag_sp_assign_utm(three_zones()))

  testthat::expect_equal(out$utm_zone[out$site == "z9"], 9)
  testthat::expect_equal(out$utm_zone[out$site == "z10"], 10)
  testthat::expect_equal(out$utm_zone[out$site == "z11"], 11)
})

testthat::test_that("bag_sp_assign_utm gives each zone its own easting, not one shared CRS", {
  testthat::skip_if_not_installed("sf")

  out <- suppressWarnings(bag_sp_assign_utm(three_zones()))

  # A UTM easting sits within the zone's own band; all three being near each other is the
  # tell that one CRS was applied to every point.
  testthat::expect_true(all(out$easting > 100000 & out$easting < 900000))
})

testthat::test_that("bag_sp_assign_utm returns the input CRS, not the UTM one", {
  testthat::skip_if_not_installed("sf")

  for (crs in c(4326, 3005)) {
    out <- suppressWarnings(bag_sp_assign_utm(three_zones(crs)))
    testthat::expect_equal(sf::st_crs(out)$epsg, crs)
  }
})

testthat::test_that("bag_sp_assign_utm honours custom column names", {
  testthat::skip_if_not_installed("sf")

  out <- suppressWarnings(bag_sp_assign_utm(
    three_zones(),
    col_zone = "zone_utm", col_easting = "utm_easting", col_northing = "utm_northing"
  ))

  testthat::expect_true(all(c("zone_utm", "utm_easting", "utm_northing") %in% names(out)))
  testthat::expect_false("easting" %in% names(out))
})

testthat::test_that("bag_sp_assign_utm rounds to sig_dig", {
  testthat::skip_if_not_installed("sf")

  rounded <- suppressWarnings(bag_sp_assign_utm(three_zones(), sig_dig = 0))
  finer <- suppressWarnings(bag_sp_assign_utm(three_zones(), sig_dig = 3))

  testthat::expect_equal(rounded$easting, round(rounded$easting, 0))
  # at three decimals at least one value should differ from its whole number
  testthat::expect_false(isTRUE(all.equal(finer$easting, round(finer$easting, 0))))
})

testthat::test_that("bag_sp_assign_utm returns rows ordered by zone", {
  testthat::skip_if_not_installed("sf")

  # The donor sorts by zone and the files its callers write back carry that order, so a
  # change here would churn every one of them.
  shuffled <- three_zones()[c(3, 1, 2), ]
  out <- suppressWarnings(bag_sp_assign_utm(shuffled))

  testthat::expect_equal(out$utm_zone, sort(out$utm_zone))
})

testthat::test_that("bag_sp_assign_utm warns when the coordinate columns are absent", {
  testthat::skip_if_not_installed("sf")

  testthat::expect_warning(bag_sp_assign_utm(three_zones()), "col_easting")
})

testthat::test_that("bag_sp_assign_utm stays quiet when the coordinate columns exist", {
  testthat::skip_if_not_installed("sf")

  d <- three_zones()
  d$easting <- 0
  d$northing <- 0

  # Guard against the warning firing unconditionally, which the test above cannot see.
  testthat::expect_no_warning(bag_sp_assign_utm(d))
})

testthat::test_that("bag_sp_assign_utm drops its working columns", {
  testthat::skip_if_not_installed("sf")

  out <- suppressWarnings(bag_sp_assign_utm(three_zones()))

  testthat::expect_false("epsg" %in% names(out))
  testthat::expect_false("long" %in% names(out))
})
