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

testthat::test_that("bag_assign_utm rejects input that is not sf POINT", {
  testthat::skip_if_not_installed("sf")

  testthat::expect_error(bag_assign_utm(NULL), "not NULL")
  testthat::expect_error(bag_assign_utm(data.frame(a = 1)), "sf")
})

testthat::test_that("bag_assign_utm validates the column name arguments", {
  testthat::skip_if_not_installed("sf")
  d <- three_zones()

  testthat::expect_error(bag_assign_utm(d, col_zone = 1L), class = "chk_error")
  testthat::expect_error(bag_assign_utm(d, col_easting = 1L), class = "chk_error")
  testthat::expect_error(bag_assign_utm(d, col_northing = 1L), class = "chk_error")
})

testthat::test_that("bag_assign_utm assigns the three columns", {
  testthat::skip_if_not_installed("sf")

  out <- suppressWarnings(bag_assign_utm(three_zones()))

  testthat::expect_true(all(c("utm_zone", "easting", "northing") %in% names(out)))
  testthat::expect_equal(nrow(out), 3L)
})

testthat::test_that("bag_assign_utm derives the zone from longitude", {
  testthat::skip_if_not_installed("sf")

  out <- suppressWarnings(bag_assign_utm(three_zones()))

  testthat::expect_equal(out$utm_zone[out$site == "z9"], 9)
  testthat::expect_equal(out$utm_zone[out$site == "z10"], 10)
  testthat::expect_equal(out$utm_zone[out$site == "z11"], 11)
})

testthat::test_that("bag_assign_utm gives each zone its own easting, not one shared CRS", {
  testthat::skip_if_not_installed("sf")

  out <- suppressWarnings(bag_assign_utm(three_zones()))

  # A UTM easting sits within the zone's own band; all three being near each other is the
  # tell that one CRS was applied to every point.
  testthat::expect_true(all(out$easting > 100000 & out$easting < 900000))
})

testthat::test_that("bag_assign_utm returns the input CRS, not the UTM one", {
  testthat::skip_if_not_installed("sf")

  for (crs in c(4326, 3005)) {
    out <- suppressWarnings(bag_assign_utm(three_zones(crs)))
    testthat::expect_equal(sf::st_crs(out)$epsg, crs)
  }
})

testthat::test_that("bag_assign_utm honours custom column names", {
  testthat::skip_if_not_installed("sf")

  out <- suppressWarnings(bag_assign_utm(
    three_zones(),
    col_zone = "zone_utm", col_easting = "utm_easting", col_northing = "utm_northing"
  ))

  testthat::expect_true(all(c("zone_utm", "utm_easting", "utm_northing") %in% names(out)))
  testthat::expect_false("easting" %in% names(out))
})

testthat::test_that("bag_assign_utm rounds to sig_dig", {
  testthat::skip_if_not_installed("sf")

  rounded <- suppressWarnings(bag_assign_utm(three_zones(), sig_dig = 0))
  finer <- suppressWarnings(bag_assign_utm(three_zones(), sig_dig = 3))

  testthat::expect_equal(rounded$easting, round(rounded$easting, 0))
  # at three decimals at least one value should differ from its whole number
  testthat::expect_false(isTRUE(all.equal(finer$easting, round(finer$easting, 0))))
})

testthat::test_that("bag_assign_utm returns rows ordered by zone", {
  testthat::skip_if_not_installed("sf")

  # The donor sorts by zone and the files its callers write back carry that order, so a
  # change here would churn every one of them.
  shuffled <- three_zones()[c(3, 1, 2), ]
  out <- suppressWarnings(bag_assign_utm(shuffled))

  testthat::expect_equal(out$utm_zone, sort(out$utm_zone))
})

testthat::test_that("bag_assign_utm warns when the coordinate columns are absent", {
  testthat::skip_if_not_installed("sf")

  w <- testthat::expect_warning(bag_assign_utm(three_zones()))
  # Both the argument name and the value it holds: matching only the interpolated value
  # cannot see whether the message still says which argument is meant, and matching only
  # the argument name broke silently when the message was reworded for line length.
  testthat::expect_match(conditionMessage(w), "col_easting")
  testthat::expect_match(conditionMessage(w), "easting")
})

testthat::test_that("bag_assign_utm stays quiet when the coordinate columns exist", {
  testthat::skip_if_not_installed("sf")

  d <- three_zones()
  d$easting <- 0
  d$northing <- 0

  # Guard against the warning firing unconditionally, which the test above cannot see.
  testthat::expect_no_warning(bag_assign_utm(d))
})

testthat::test_that("bag_assign_utm drops its working columns", {
  testthat::skip_if_not_installed("sf")

  out <- suppressWarnings(bag_assign_utm(three_zones()))

  # `epsg` is still a working column and is still selected out. `long` was one before the
  # magrittr removal, which reads longitude into a local vector instead of a column, so
  # that assertion now pins the output contract rather than a removal step.
  testthat::expect_false("epsg" %in% names(out))
  testthat::expect_false("long" %in% names(out))
})

testthat::test_that("bag_assign_utm returns its columns in a fixed order", {
  testthat::skip_if_not_installed("sf")

  # Exact order, not set membership. Every other column assertion in this file uses
  # `%in% names()`, which cannot see a reordering -- and callers write these columns
  # straight to disk, so the order is part of the output format, not cosmetics. Here the
  # three new columns land BEFORE the geometry column, which the trailing
  # dplyr::select(-epsg) is what produces.
  out <- suppressWarnings(bag_assign_utm(three_zones()))
  testthat::expect_equal(
    names(out),
    c("site", "utm_zone", "easting", "northing", "geometry")
  )

  # And with renamed columns, so the assertion pins positions rather than literal names.
  renamed <- suppressWarnings(bag_assign_utm(
    three_zones(),
    col_zone = "zone_utm", col_easting = "utm_easting", col_northing = "utm_northing"
  ))
  testthat::expect_equal(
    names(renamed),
    c("site", "zone_utm", "utm_easting", "utm_northing", "geometry")
  )
})

testthat::test_that("bag_assign_utm is not shadowed by columns named like its locals", {
  testthat::skip_if_not_installed("sf")

  # Longitude and the per-zone coordinates are read into locals `lon` and `xy` and
  # injected with `!!`. A bare name inside a data-masked verb resolves to a COLUMN of
  # that name first, so without the injection a caller's own `lon` column would drive the
  # zone arithmetic. The decoys below all sit in zone 11 if they were believed.
  d <- three_zones()
  d$lon <- c(-115, -115, -115)
  d$xy <- matrix(rep(-1, 6), ncol = 2)

  out <- suppressWarnings(bag_assign_utm(d))
  reference <- suppressWarnings(bag_assign_utm(three_zones()))

  testthat::expect_equal(out$utm_zone, reference$utm_zone)
  testthat::expect_equal(out$easting, reference$easting)
  testthat::expect_equal(out$northing, reference$northing)
})

testthat::test_that("bag_assign_utm keeps its columns on a zero-row input", {
  testthat::skip_if_not_installed("sf")

  # With no rows there are no zones, so the per-zone loop yields no groups. Binding those
  # gives a 0 x 0 tibble, which loses every column the caller passed in. Reachable through
  # bag_gpkg_refresh(), whose update_utm defaults to TRUE, on an empty field form.
  out <- suppressWarnings(bag_assign_utm(three_zones()[0, ]))

  testthat::expect_s3_class(out, "sf")
  testthat::expect_equal(nrow(out), 0L)
  testthat::expect_equal(
    names(out),
    c("site", "utm_zone", "easting", "northing", "geometry")
  )
})

testthat::test_that("bag_assign_utm round trips a CRS with no EPSG code", {
  testthat::skip_if_not_installed("sf")

  # st_crs(parameters = TRUE)$epsg is NA for a CRS with no authority, and
  # st_transform(crs = NA) then aborts "crs not found: is it missing?", naming nothing.
  albers <- paste(
    "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126",
    "+datum=NAD83 +units=m +no_defs"
  )
  d <- sf::st_transform(three_zones(), albers)
  testthat::expect_true(is.na(sf::st_crs(d, parameters = TRUE)$epsg))

  out <- suppressWarnings(bag_assign_utm(d))
  testthat::expect_equal(sf::st_crs(out), sf::st_crs(d))
  testthat::expect_equal(out$utm_zone, c(9, 10, 11))
})

testthat::test_that("bag_assign_utm leaves a caller's own epsg column alone", {
  testthat::skip_if_not_installed("sf")

  # The donor held the zone CRS in a column called `epsg` and selected it back out, so a
  # caller's column of that name was overwritten and then deleted, silently.
  d <- three_zones()
  d$epsg <- c("keep-a", "keep-b", "keep-c")

  out <- suppressWarnings(bag_assign_utm(d))

  testthat::expect_true("epsg" %in% names(out))
  testthat::expect_equal(out$epsg, c("keep-a", "keep-b", "keep-c"))
})

testthat::test_that("bag_assign_utm keeps a row whose coordinates are missing", {
  testthat::skip_if_not_installed("sf")

  # An empty POINT is a field row entered without a GPS fix. sort() drops its NA zone, so
  # the row joined no group -- and `epsg == epsg_zone` was NA for it in EVERY pass, which
  # [.data.frame answers with a fabricated all-NA row. One such row became three phantom
  # rows and its own attributes were lost, on a frame bag_gpkg_refresh() writes to disk.
  d <- sf::st_sf(
    site = c("a", "b", "c", "d"),
    note = c("w", "x", "y", "z"),
    geometry = sf::st_sfc(
      sf::st_point(c(-128.5, 54.5)), sf::st_point(c(-123.5, 54.5)),
      sf::st_point(c(-118.5, 54.5)), sf::st_point(),
      crs = 4326
    )
  )

  out <- suppressWarnings(bag_assign_utm(d))

  testthat::expect_equal(nrow(out), nrow(d))
  testthat::expect_setequal(out$site, d$site)
  # the attributes of the unplaced row survive, which is the half a row count misses
  testthat::expect_equal(out$note[out$site == "d"], "z")
  testthat::expect_true(is.na(out$utm_zone[out$site == "d"]))
  testthat::expect_true(is.na(out$easting[out$site == "d"]))
  testthat::expect_true(is.na(out$northing[out$site == "d"]))
  # and the placed rows are unaffected
  testthat::expect_equal(out$utm_zone[out$site %in% c("a", "b", "c")], c(9, 10, 11))
})

testthat::test_that("bag_assign_utm says so when it cannot place a row", {
  testthat::skip_if_not_installed("sf")

  d <- sf::st_sf(
    site = c("a", "b"),
    geometry = sf::st_sfc(sf::st_point(c(-128.5, 54.5)), sf::st_point(), crs = 4326)
  )
  d$easting <- 0
  d$northing <- 0

  w <- testthat::expect_warning(bag_assign_utm(d), "no usable coordinates")
  testthat::expect_match(conditionMessage(w), "1 row")
  testthat::expect_match(conditionMessage(w), "every other column is kept")
})

testthat::test_that("bag_assign_utm names only the coordinate argument that is absent", {
  testthat::skip_if_not_installed("sf")

  # The predicate is an OR and the message was an AND, so a caller who typo'd one
  # argument was told both were wrong and sent to check the one that was right.
  d <- three_zones()
  d$easting <- 0

  w <- testthat::expect_warning(bag_assign_utm(d, col_northing = "north_m"))
  msg <- conditionMessage(w)

  testthat::expect_match(msg, "col_northing")
  testthat::expect_match(msg, "north_m")
  testthat::expect_no_match(msg, "col_easting")
  testthat::expect_match(msg, "does not name a column")
})
