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

testthat::test_that("bag_gpkg_to_geojson writes WGS 84 whatever the source CRS", {
  testthat::skip_if_not_installed("sf")

  # The bundled fixture is already WGS 84, so no test built on it can reach this. BC
  # Albers is the normal CRS of a BC GeoPackage, and RFC 7946 removed the `crs` member,
  # so a projected file renders in the wrong place wherever the RFC is followed.
  src <- sf::st_transform(sf::st_read(system.file("extdata/poly.gpkg", package = "bag"),
                                      quiet = TRUE), 3005)
  dir_in <- tempfile("albers_in_")
  dir_out <- tempfile("albers_out_")
  fs::dir_create(dir_in)
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)
  sf::st_write(src, fs::path(dir_in, "albers.gpkg"), layer = "aoi", quiet = TRUE)

  out <- bag_gpkg_to_geojson(dir_in = dir_in, dir_out = dir_out, file_name_in = "albers")

  testthat::expect_true(sf::st_crs(sf::st_read(out[[1]], quiet = TRUE)) == sf::st_crs(4326))

  # And in the bytes, not only through sf -- which honours a `crs` member and so reports
  # 3005 as 3005 rather than as a defect. Degrees are bounded by 180; BC Albers metres
  # for this fixture run to millions.
  txt <- paste(readLines(out[[1]], warn = FALSE), collapse = " ")
  testthat::expect_false(grepl("EPSG::3005", txt, fixed = TRUE))
  nums <- as.numeric(regmatches(txt, gregexpr("-?[0-9]+\\.[0-9]+", txt))[[1]])
  testthat::expect_gt(length(nums), 0)
  testthat::expect_true(all(abs(nums) <= 180))
})

testthat::test_that("bag_gpkg_to_geojson leaves a WGS 84 layer alone", {
  testthat::skip_if_not_installed("sf")

  dir_in <- seed_gpkg()
  dir_out <- tempfile("wgs_out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  out <- bag_gpkg_to_geojson(dir_in = dir_in, dir_out = dir_out, file_name_in = "source")
  testthat::expect_true(sf::st_crs(sf::st_read(out[[1]], quiet = TRUE)) == sf::st_crs(4326))
})

# A GeoPackage layer with no spatial reference does NOT read back as a missing CRS: the
# format reserves srs_id -1 ("undefined Cartesian") and 0 ("undefined geographic"), and
# GDAL resolves both into real CRS objects. The first cannot be transformed at all; the
# second transforms silently, taking the coordinates for WGS 84. Both are refused.
seed_unreferenced <- function(srs_id = -1L) {
  d <- sf::st_as_sf(
    data.frame(id = 1:2, x = c(1, 2), y = c(1, 2)),
    coords = c("x", "y"), crs = NA
  )
  dir_in <- tempfile("nocrs_")
  fs::dir_create(dir_in)
  path <- fs::path(dir_in, "source.gpkg")
  suppressWarnings(sf::st_write(d, path, layer = "zzz_nocrs", quiet = TRUE))
  if (srs_id == 0L) {
    con <- DBI::dbConnect(RSQLite::SQLite(), path)
    on.exit(DBI::dbDisconnect(con), add = TRUE)
    DBI::dbExecute(con, "UPDATE gpkg_geometry_columns SET srs_id = 0")
    DBI::dbExecute(con, "UPDATE gpkg_contents SET srs_id = 0")
  }
  dir_in
}

testthat::test_that("bag_gpkg_to_geojson refuses a layer whose CRS is undefined Cartesian", {
  testthat::skip_if_not_installed("sf")

  dir_in <- seed_unreferenced(-1L)
  dir_out <- tempfile("nocrs_out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  # sf's own writer produces this case, and is.na() on the CRS it reads back is FALSE.
  crs_back <- sf::st_crs(sf::st_read(fs::path(dir_in, "source.gpkg"), quiet = TRUE))
  testthat::expect_false(is.na(crs_back))

  testthat::expect_error(
    bag_gpkg_to_geojson(dir_in = dir_in, dir_out = dir_out, file_name_in = "source"),
    "no usable CRS"
  )
})

testthat::test_that("bag_gpkg_to_geojson refuses a layer whose CRS is undefined geographic", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("RSQLite")
  testthat::skip_if_not_installed("DBI")

  dir_in <- seed_unreferenced(0L)
  dir_out <- tempfile("nocrs0_out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  # This one TRANSFORMS without error -- GDAL takes it for WGS 84 -- so a check that only
  # tried the transform would let it through and write coordinates on an assumption.
  testthat::expect_error(
    bag_gpkg_to_geojson(dir_in = dir_in, dir_out = dir_out, file_name_in = "source"),
    "no usable CRS"
  )
})

testthat::test_that("bag_gpkg_to_geojson writes nothing when one of several layers is unreferenced", {
  testthat::skip_if_not_installed("sf")

  # The refusal is up front, so a GeoPackage converts whole or not at all. Before this,
  # the loop aborted part way and left the layers it had already reached on disk.
  dir_in <- seed_unreferenced(-1L)
  dir_out <- tempfile("partial_out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)
  good <- sf::st_read(system.file("extdata/poly.gpkg", package = "bag"), quiet = TRUE)
  sf::st_write(good, fs::path(dir_in, "source.gpkg"), layer = "aaa_good", quiet = TRUE)

  testthat::expect_error(
    bag_gpkg_to_geojson(dir_in = dir_in, dir_out = dir_out, file_name_in = "source"),
    "no usable CRS"
  )
  testthat::expect_length(list.files(dir_out, pattern = "[.]geojson$"), 0L)
})
