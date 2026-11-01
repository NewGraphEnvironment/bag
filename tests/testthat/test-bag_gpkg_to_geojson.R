# Built on the bundled poly.gpkg, so there is no fixture to keep in step.

seed_gpkg <- function(layers = c("poly")) {
  src <- system.file("extdata/poly.gpkg", package = "bag")
  d <- sf::st_read(src, quiet = TRUE)
  dir_in <- tempfile("gpkgin_")
  fs::dir_create(dir_in)
  path <- fs::path(dir_in, "source.gpkg")
  for (nm in layers) {
    sf::st_write(d, path, layer = nm, quiet = TRUE, append = FALSE)
  }
  dir_in
}

testthat::test_that("bag_gpkg_to_geojson validates its arguments", {
  testthat::skip_if_not_installed("sf")
  dir_in <- seed_gpkg()
  on.exit(unlink(dir_in, recursive = TRUE), add = TRUE)

  testthat::expect_error(bag_gpkg_to_geojson(1L, tempdir(), "source"), class = "chk_error")
  testthat::expect_error(bag_gpkg_to_geojson(dir_in, 1L, "source"), class = "chk_error")
  testthat::expect_error(bag_gpkg_to_geojson(dir_in, tempdir(), 1L), class = "chk_error")
})

testthat::test_that("bag_gpkg_to_geojson rejects an input directory that does not exist", {
  testthat::expect_error(
    bag_gpkg_to_geojson(fs::path(tempdir(), "no-such-dir"), tempdir(), "source"),
    class = "chk_error"
  )
})

testthat::test_that("bag_gpkg_to_geojson aborts when the GeoPackage is absent", {
  testthat::skip_if_not_installed("sf")
  dir_in <- seed_gpkg()
  on.exit(unlink(dir_in, recursive = TRUE), add = TRUE)

  # The directory exists, so chk_dir passes and this is the function's own guard. The donor
  # had none: sf::st_layers() failed several lines later with a GDAL message.
  testthat::expect_error(
    bag_gpkg_to_geojson(dir_in, tempfile("out_"), "not-the-one"),
    "No GeoPackage at"
  )
})

testthat::test_that("bag_gpkg_to_geojson writes one geojson per layer", {
  testthat::skip_if_not_installed("sf")
  dir_in <- seed_gpkg(c("alpha", "beta"))
  dir_out <- tempfile("out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  out <- bag_gpkg_to_geojson(dir_in, dir_out, "source")

  testthat::expect_length(out, 2L)
  testthat::expect_setequal(basename(out), c("alpha.geojson", "beta.geojson"))
  testthat::expect_true(all(file.exists(out)))
})

testthat::test_that("bag_gpkg_to_geojson names each file for its layer", {
  testthat::skip_if_not_installed("sf")
  dir_in <- seed_gpkg(c("alpha"))
  dir_out <- tempfile("out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  out <- bag_gpkg_to_geojson(dir_in, dir_out, "source")

  testthat::expect_equal(basename(out), "alpha.geojson")
})

testthat::test_that("bag_gpkg_to_geojson writes readable geojson with the same feature count", {
  testthat::skip_if_not_installed("sf")
  dir_in <- seed_gpkg(c("alpha"))
  dir_out <- tempfile("out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  n_in <- nrow(sf::st_read(fs::path(dir_in, "source.gpkg"), layer = "alpha", quiet = TRUE))
  out <- bag_gpkg_to_geojson(dir_in, dir_out, "source")
  n_out <- nrow(sf::st_read(out[[1]], quiet = TRUE))

  testthat::expect_equal(n_out, n_in)
})

testthat::test_that("bag_gpkg_to_geojson creates the output directory", {
  testthat::skip_if_not_installed("sf")
  dir_in <- seed_gpkg()
  dir_out <- fs::path(tempfile("out_"), "nested")
  on.exit(unlink(c(dir_in, dirname(dir_out)), recursive = TRUE), add = TRUE)

  testthat::expect_false(dir.exists(dir_out))
  bag_gpkg_to_geojson(dir_in, dir_out, "source")
  testthat::expect_true(dir.exists(dir_out))
})

testthat::test_that("bag_gpkg_to_geojson overwrites a geojson from an earlier run", {
  testthat::skip_if_not_installed("sf")
  dir_in <- seed_gpkg(c("alpha"))
  dir_out <- tempfile("out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  bag_gpkg_to_geojson(dir_in, dir_out, "source")
  # delete_dsn = TRUE, so a second run must succeed rather than append or refuse
  testthat::expect_no_error(bag_gpkg_to_geojson(dir_in, dir_out, "source"))

  n_in <- nrow(sf::st_read(fs::path(dir_in, "source.gpkg"), layer = "alpha", quiet = TRUE))
  testthat::expect_equal(
    nrow(sf::st_read(fs::path(dir_out, "alpha.geojson"), quiet = TRUE)),
    n_in
  )
})
