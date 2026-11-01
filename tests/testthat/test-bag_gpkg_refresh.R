seed_point_gpkg <- function(n = 3) {
  d <- sf::st_as_sf(
    data.frame(
      site = paste0("s", seq_len(n)),
      lon = seq(-128.5, -118.5, length.out = n),
      lat = rep(54.5, n)
    ),
    coords = c("lon", "lat"), crs = 4326
  )
  dir <- tempfile("gpkgbk_")
  fs::dir_create(dir)
  path <- fs::path(dir, "form_fiss_site_2026.gpkg")
  sf::st_write(d, path, quiet = TRUE)
  path
}

testthat::test_that("bag_gpkg_refresh validates its arguments", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  on.exit(unlink(dirname(path), recursive = TRUE), add = TRUE)

  testthat::expect_error(bag_gpkg_refresh(NULL), class = "chk_error")
  testthat::expect_error(bag_gpkg_refresh(tempfile(fileext = ".gpkg")), class = "chk_error")
  testthat::expect_error(bag_gpkg_refresh(path, dir_backup = 1L), class = "chk_error")
  testthat::expect_error(bag_gpkg_refresh(path, update_utm = "yes"), class = "chk_error")
  testthat::expect_error(bag_gpkg_refresh(path, fn_site_id = "nope"), class = "chk_error")
})

testthat::test_that("bag_gpkg_refresh writes a csv and an RData backup", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  suppressWarnings(bag_gpkg_refresh(path, dir_backup = dir_backup))

  testthat::expect_true(file.exists(fs::path(dir_backup, "form_fiss_site_2026.csv")))
  testthat::expect_true(file.exists(fs::path(dir_backup, "form_fiss_site_2026.RData")))
})

testthat::test_that("bag_gpkg_refresh names the RData object for the GeoPackage", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  suppressWarnings(bag_gpkg_refresh(path, dir_backup = dir_backup))

  e <- new.env()
  load(fs::path(dir_backup, "form_fiss_site_2026.RData"), envir = e)
  testthat::expect_equal(ls(e), "form_fiss_site_2026")
  testthat::expect_s3_class(get("form_fiss_site_2026", envir = e), "sf")
})

testthat::test_that("bag_gpkg_refresh drops the geometry from the csv", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  suppressWarnings(bag_gpkg_refresh(path, dir_backup = dir_backup))
  csv <- utils::read.csv(fs::path(dir_backup, "form_fiss_site_2026.csv"))

  testthat::expect_false("geom" %in% names(csv))
  testthat::expect_false("geometry" %in% names(csv))
  testthat::expect_true("site" %in% names(csv))
})

testthat::test_that("bag_gpkg_refresh creates dir_backup when only RData is written", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  # The donor created dir_backup inside the csv branch only, so this combination failed on
  # a directory that did not exist yet.
  testthat::expect_no_error(
    suppressWarnings(bag_gpkg_refresh(
      path, dir_backup = dir_backup, write_to_csv = FALSE, write_to_rdata = TRUE
    ))
  )
  testthat::expect_true(file.exists(fs::path(dir_backup, "form_fiss_site_2026.RData")))
})

testthat::test_that("bag_gpkg_refresh refreshes the UTM columns when asked", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  out <- suppressWarnings(bag_gpkg_refresh(
    path, dir_backup = dir_backup, update_utm = TRUE, return_object = TRUE
  ))

  testthat::expect_true(all(c("utm_zone", "easting", "northing") %in% names(out)))
})

testthat::test_that("bag_gpkg_refresh leaves the columns alone when update_utm is FALSE", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  out <- bag_gpkg_refresh(
    path, dir_backup = dir_backup, update_utm = FALSE, return_object = TRUE
  )

  testthat::expect_false("utm_zone" %in% names(out))
})

testthat::test_that("bag_gpkg_refresh passes ... through to bag_assign_utm", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  out <- suppressWarnings(bag_gpkg_refresh(
    path, dir_backup = dir_backup, return_object = TRUE,
    col_easting = "utm_easting", col_northing = "utm_northing"
  ))

  testthat::expect_true(all(c("utm_easting", "utm_northing") %in% names(out)))
})

testthat::test_that("bag_gpkg_refresh applies fn_site_id when given one", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  # This is the injection point that replaced the donor's update_site_id branch, so that
  # the site-identity logic can stay in the fish-passage package.
  tagged <- function(d) {
    d$site_id <- paste0("id_", d$site)
    d
  }

  out <- suppressWarnings(bag_gpkg_refresh(
    path, dir_backup = dir_backup, fn_site_id = tagged, return_object = TRUE
  ))

  testthat::expect_true("site_id" %in% names(out))
  testthat::expect_true(all(grepl("^id_", out$site_id)))
})

testthat::test_that("bag_gpkg_refresh applies nothing when fn_site_id is NULL", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  out <- suppressWarnings(bag_gpkg_refresh(
    path, dir_backup = dir_backup, return_object = TRUE
  ))

  testthat::expect_false("site_id" %in% names(out))
})

testthat::test_that("bag_gpkg_refresh rejects an fn_site_id that breaks the object", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  # A callback returning the wrong shape would otherwise be written to disk.
  testthat::expect_error(
    suppressWarnings(bag_gpkg_refresh(
      path, dir_backup = dir_backup, fn_site_id = function(d) sf::st_drop_geometry(d)
    )),
    "fn_site_id"
  )
})

testthat::test_that("bag_gpkg_refresh leaves the GeoPackage alone by default", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  before <- names(sf::st_read(path, quiet = TRUE))
  suppressWarnings(bag_gpkg_refresh(path, dir_backup = dir_backup))

  testthat::expect_equal(names(sf::st_read(path, quiet = TRUE)), before)
})

testthat::test_that("bag_gpkg_refresh writes back when write_back_to_path is TRUE", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  suppressWarnings(bag_gpkg_refresh(
    path, dir_backup = dir_backup, write_back_to_path = TRUE
  ))

  testthat::expect_true("utm_zone" %in% names(sf::st_read(path, quiet = TRUE)))
})

testthat::test_that("bag_gpkg_refresh returns nothing unless asked", {
  testthat::skip_if_not_installed("sf")
  path <- seed_point_gpkg()
  dir_backup <- tempfile("bk_")
  on.exit(unlink(c(dirname(path), dir_backup), recursive = TRUE), add = TRUE)

  out <- suppressWarnings(bag_gpkg_refresh(path, dir_backup = dir_backup))
  testthat::expect_null(out)
})

testthat::test_that("bag_gpkg_refresh rejects a GeoPackage that is not points", {
  testthat::skip_if_not_installed("sf")

  dir <- tempfile("poly_")
  fs::dir_create(dir)
  path <- fs::path(dir, "poly.gpkg")
  sf::st_write(
    sf::st_sf(id = 1, geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))), crs = 4326
    )),
    path, quiet = TRUE
  )
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  testthat::expect_error(bag_gpkg_refresh(path), "POINT geometry")
})
