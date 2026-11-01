# Needs GDAL on the PATH, because the function shells out to ogr2ogr.

seed_multi <- function(layers = c("alpha", "beta", "gamma")) {
  src <- system.file("extdata/poly.gpkg", package = "bag")
  d <- sf::st_read(src, quiet = TRUE)
  path <- tempfile(fileext = ".gpkg")
  for (nm in layers) {
    sf::st_write(d, path, layer = nm, quiet = TRUE, append = FALSE)
  }
  path
}

testthat::test_that("bag_u_rm_gpkg_layers validates its arguments", {
  testthat::skip_if_not_installed("sf")
  path <- seed_multi()
  on.exit(unlink(path), add = TRUE)

  testthat::expect_error(bag_u_rm_gpkg_layers(1L, "alpha"), class = "chk_error")
  testthat::expect_error(bag_u_rm_gpkg_layers(path, 1L), class = "chk_error")
  testthat::expect_error(
    bag_u_rm_gpkg_layers(tempfile(fileext = ".gpkg"), "alpha"),
    class = "chk_error"
  )
})

testthat::test_that("bag_u_rm_gpkg_layers aborts on a layer that is not there", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if(!nzchar(Sys.which("ogr2ogr")), "ogr2ogr not on the PATH")
  path <- seed_multi()
  on.exit(unlink(path), add = TRUE)

  testthat::expect_error(bag_u_rm_gpkg_layers(path, "delta"), "delta")
})

testthat::test_that("bag_u_rm_gpkg_layers names every missing layer in one abort", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if(!nzchar(Sys.which("ogr2ogr")), "ogr2ogr not on the PATH")
  path <- seed_multi()
  on.exit(unlink(path), add = TRUE)

  # The donor aborted on the first missing layer inside a loop, so a caller fixing a typo
  # found the next one only on the next run.
  err <- testthat::expect_error(bag_u_rm_gpkg_layers(path, c("delta", "epsilon")))
  testthat::expect_match(conditionMessage(err), "delta")
  testthat::expect_match(conditionMessage(err), "epsilon")
})

testthat::test_that("bag_u_rm_gpkg_layers leaves the file untouched when a layer is missing", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if(!nzchar(Sys.which("ogr2ogr")), "ogr2ogr not on the PATH")
  path <- seed_multi()
  on.exit(unlink(path), add = TRUE)

  before <- sort(sf::st_layers(path)$name)
  try(bag_u_rm_gpkg_layers(path, "delta"), silent = TRUE)
  testthat::expect_equal(sort(sf::st_layers(path)$name), before)
})

testthat::test_that("bag_u_rm_gpkg_layers removes the named layer and keeps the rest", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if(!nzchar(Sys.which("ogr2ogr")), "ogr2ogr not on the PATH")
  path <- seed_multi()
  on.exit(unlink(path), add = TRUE)

  bag_u_rm_gpkg_layers(path, "beta")

  testthat::expect_setequal(sf::st_layers(path)$name, c("alpha", "gamma"))
})

testthat::test_that("bag_u_rm_gpkg_layers removes several layers at once", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if(!nzchar(Sys.which("ogr2ogr")), "ogr2ogr not on the PATH")
  path <- seed_multi()
  on.exit(unlink(path), add = TRUE)

  bag_u_rm_gpkg_layers(path, c("alpha", "beta"))

  testthat::expect_setequal(sf::st_layers(path)$name, "gamma")
})

testthat::test_that("bag_u_rm_gpkg_layers keeps the surviving layers' features", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if(!nzchar(Sys.which("ogr2ogr")), "ogr2ogr not on the PATH")
  path <- seed_multi()
  on.exit(unlink(path), add = TRUE)

  n_before <- nrow(sf::st_read(path, layer = "alpha", quiet = TRUE))
  bag_u_rm_gpkg_layers(path, "beta")
  n_after <- nrow(sf::st_read(path, layer = "alpha", quiet = TRUE))

  # The rebuild must not quietly truncate what it keeps.
  testthat::expect_equal(n_after, n_before)
})

testthat::test_that("bag_u_rm_gpkg_layers refuses to remove every layer", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if(!nzchar(Sys.which("ogr2ogr")), "ogr2ogr not on the PATH")
  path <- seed_multi(c("alpha", "beta"))
  on.exit(unlink(path), add = TRUE)

  testthat::expect_error(
    bag_u_rm_gpkg_layers(path, c("alpha", "beta")),
    "every layer"
  )
  # and the file is still intact
  testthat::expect_setequal(sf::st_layers(path)$name, c("alpha", "beta"))
})

testthat::test_that("bag_u_rm_gpkg_layers refuses when a SQLite sidecar is present", {
  testthat::skip_if_not_installed("sf")
  path <- seed_multi()
  wal <- paste0(path, "-wal")
  file.create(wal)
  on.exit(unlink(c(path, wal)), add = TRUE)

  # A GeoPackage is a SQLite database, so the main file alone is not the database while a
  # write ahead log sits beside it -- replacing it would lose whatever the log held.
  testthat::expect_error(bag_u_rm_gpkg_layers(path, "beta"), "sidecar")
})

testthat::test_that("bag_u_rm_gpkg_layers aborts, and does not overwrite, when ogr2ogr fails", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("mockery")
  path <- seed_multi()
  on.exit(unlink(path), add = TRUE)

  before <- sort(sf::st_layers(path)$name)

  f <- bag_u_rm_gpkg_layers
  mockery::stub(f, "system2", function(...) 1L)

  # The donor called system2(stdout = TRUE), which only WARNS on a non-zero exit, and then
  # copied the temp file over the original regardless -- so a failed layer copy silently
  # produced a GeoPackage missing layers nobody asked to remove.
  testthat::expect_error(f(path, "beta"), "failed with status")
  testthat::expect_equal(sort(sf::st_layers(path)$name), before)
})

testthat::test_that("bag_u_rm_gpkg_layers aborts when the rebuild is incomplete", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("mockery")
  path <- seed_multi()
  on.exit(unlink(path), add = TRUE)

  before <- sort(sf::st_layers(path)$name)

  # ogr2ogr "succeeds" but writes nothing. Without the completeness check the original
  # would be replaced by an empty file.
  f <- bag_u_rm_gpkg_layers
  mockery::stub(f, "system2", function(...) 0L)

  testthat::expect_error(f(path, "beta"), "does not hold the layers")
  testthat::expect_equal(sort(sf::st_layers(path)$name), before)
})
