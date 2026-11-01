pts <- function(crs = 3005) {
  d <- sf::st_as_sf(
    data.frame(site = c("a", "b"), lon = c(-128.5, -123.5), lat = c(54.5, 50.5)),
    coords = c("lon", "lat"), crs = 4326
  )
  if (crs != 4326) d <- sf::st_transform(d, crs)
  d
}

testthat::test_that("bag_assign_latlong rejects input that is not sf POINT", {
  testthat::skip_if_not_installed("sf")

  testthat::expect_error(bag_assign_latlong(NULL), "not NULL")
  testthat::expect_error(bag_assign_latlong(data.frame(a = 1)), "sf")
})

testthat::test_that("bag_assign_latlong validates the column name arguments", {
  testthat::skip_if_not_installed("sf")

  testthat::expect_error(bag_assign_latlong(pts(), col_lat = 1L), class = "chk_error")
  testthat::expect_error(bag_assign_latlong(pts(), col_lon = 1L), class = "chk_error")
})

testthat::test_that("bag_assign_latlong appends lat and lon", {
  testthat::skip_if_not_installed("sf")

  out <- bag_assign_latlong(pts())

  testthat::expect_true(all(c("lat", "lon") %in% names(out)))
  testthat::expect_equal(nrow(out), 2L)
})

testthat::test_that("bag_assign_latlong returns WGS 84 degrees, whatever the input CRS", {
  testthat::skip_if_not_installed("sf")

  out <- bag_assign_latlong(pts(3005))

  # If the transform to 4326 were skipped, these would be BC Albers metres.
  testthat::expect_true(all(out$lon > -140 & out$lon < -110))
  testthat::expect_true(all(out$lat > 45 & out$lat < 62))
})

testthat::test_that("bag_assign_latlong round trips to the input CRS", {
  testthat::skip_if_not_installed("sf")

  for (crs in c(3005, 4326, 26909)) {
    out <- bag_assign_latlong(pts(crs))
    testthat::expect_equal(sf::st_crs(out)$epsg, crs)
  }
})

testthat::test_that("bag_assign_latlong honours custom column names", {
  testthat::skip_if_not_installed("sf")

  out <- bag_assign_latlong(pts(), col_lon = "long")

  testthat::expect_true("long" %in% names(out))
  testthat::expect_false("lon" %in% names(out))
})

testthat::test_that("bag_assign_latlong leaves the geometry unmoved", {
  testthat::skip_if_not_installed("sf")

  d <- pts(3005)
  out <- bag_assign_latlong(d)

  # The CRS round trip must return the same coordinates, not merely the same CRS.
  testthat::expect_equal(
    unname(sf::st_coordinates(out)),
    unname(sf::st_coordinates(d)),
    tolerance = 1e-6
  )
})

testthat::test_that("bag_assign_latlong returns its columns in a fixed order", {
  testthat::skip_if_not_installed("sf")

  # Exact order, not set membership, because callers write these columns to disk.
  #
  # Note this function places its new columns AFTER the geometry column, where
  # bag_assign_utm() places its BEFORE. The difference is real and is the donors':
  # the UTM function ends on dplyr::select() calls that push geometry last, and this one
  # has none, so mutate() appends past it. Pinned rather than reconciled -- the files
  # callers write back carry this order, so "tidying" it is a format change.
  out <- bag_assign_latlong(pts())
  testthat::expect_equal(names(out), c("site", "geometry", "lon", "lat"))

  renamed <- bag_assign_latlong(pts(), col_lat = "latitude", col_lon = "longitude")
  testthat::expect_equal(names(renamed), c("site", "geometry", "longitude", "latitude"))
})

testthat::test_that("bag_assign_latlong is not shadowed by a column named like its local", {
  testthat::skip_if_not_installed("sf")

  # The coordinates are read into a local `xy` and injected into mutate() with `!!`. A
  # bare `xy` inside a data-masked verb would resolve to a COLUMN of that name in
  # preference to the local, so a caller's own `xy` column would silently supply the
  # coordinates. Decoy values chosen to be nothing like a longitude or a latitude.
  d <- pts()
  d$xy <- matrix(c(-1, -2, -3, -4), ncol = 2)

  out <- bag_assign_latlong(d)
  expected <- sf::st_coordinates(sf::st_transform(pts(), 4326))

  testthat::expect_equal(out$lon, unname(expected[, 1]))
  testthat::expect_equal(out$lat, unname(expected[, 2]))
})

testthat::test_that("bag_assign_latlong round trips a CRS with no EPSG code", {
  testthat::skip_if_not_installed("sf")

  # st_crs(parameters = TRUE)$epsg is NA for a CRS with no authority, and
  # st_transform(crs = NA) then aborts "crs not found: is it missing?", naming nothing.
  albers <- paste(
    "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126",
    "+datum=NAD83 +units=m +no_defs"
  )
  d <- sf::st_transform(pts(), albers)
  testthat::expect_true(is.na(sf::st_crs(d, parameters = TRUE)$epsg))

  out <- bag_assign_latlong(d)
  testthat::expect_equal(sf::st_crs(out), sf::st_crs(d))
  testthat::expect_equal(round(out$lon, 4), c(-128.5, -123.5))
})

testthat::test_that("bag_assign_latlong treats an unplaceable row as its sibling does", {
  testthat::skip_if_not_installed("sf")

  # It wrote NaN and said nothing, where bag_assign_utm() writes NA and warns. NaN is an
  # NA in R and reaches disk as NULL or an empty field either way, so the difference that
  # mattered was the silence.
  d <- sf::st_sf(
    site = c("a", "b"),
    geometry = sf::st_sfc(sf::st_point(c(-128.5, 54.5)), sf::st_point(), crs = 4326)
  )

  w <- testthat::expect_warning(bag_assign_latlong(d), "no usable coordinates")
  testthat::expect_match(conditionMessage(w), "1 row")

  out <- suppressWarnings(bag_assign_latlong(d))
  testthat::expect_equal(nrow(out), 2L)
  testthat::expect_true(is.na(out$lon[out$site == "b"]))
  testthat::expect_false(is.nan(out$lon[out$site == "b"]))
  testthat::expect_equal(out$lon[out$site == "a"], -128.5)
})

testthat::test_that("bag_assign_latlong refuses an object whose CRS is unusable", {
  testthat::skip_if_not_installed("sf")

  d <- sf::st_as_sf(
    data.frame(site = c("a", "b"), x = c(1, 2), y = c(1, 2)),
    coords = c("x", "y"), crs = NA
  )

  testthat::expect_error(bag_assign_latlong(d), "no usable CRS")
})
