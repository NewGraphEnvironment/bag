# sf::st_read() and sf::st_write() are mocked. Real .gpx files are created so the directory
# listing is genuine — that is the part with a defect worth pinning.

gpx_dir <- function(files = c("a.gpx", "b.gpx", "notes.txt", "weird_gpx.csv")) {
  d <- tempfile("gpx_")
  fs::dir_create(d)
  for (f in files) file.create(fs::path(d, f))
  d
}

# `time` present: a waypoint layer. `time` absent: a track layer, whose name is the
# timestamp the unit minted.
fake_points <- function(times = c("2026-01-02 10:00:00", "2026-06-02 10:00:00"),
                        with_time = TRUE) {
  n <- length(times)
  d <- data.frame(name = times, stringsAsFactors = FALSE)
  if (with_time) d$time <- as.POSIXct(times, tz = "UTC")
  sf::st_sf(
    d,
    geometry = sf::st_sfc(
      lapply(seq_len(n), function(i) sf::st_point(c(-127 + i / 100, 54 + i / 100))),
      crs = 4326
    )
  )
}

stub_io <- function(f, layer = fake_points(), on_read = NULL, on_write = NULL) {
  mockery::stub(f, "sf::st_read", function(dsn, ...) {
    if (!is.null(on_read)) on_read(dsn)
    layer
  })
  mockery::stub(f, "sf::st_write", function(obj, dsn, ...) {
    if (!is.null(on_write)) on_write(obj, dsn)
    invisible(obj)
  })
  f
}

testthat::test_that("bag_gpx_import validates its arguments", {
  d <- gpx_dir()
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  testthat::expect_error(
    bag_gpx_import(dir_out = 1L, layer_output_name = "x", gpkg_name = "g"),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_gpx_import(dir_out = tempfile(), layer_output_name = 1L, gpkg_name = "g"),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_gpx_import(dir_out = tempfile(), layer_output_name = "x", gpkg_name = 1L),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_gpx_import(dir_out = tempfile(), layer_output_name = "x", gpkg_name = "g", dates_view = "yes"),
    class = "chk_error"
  )
})

testthat::test_that("bag_gpx_import rejects an unknown gpx_layer_type", {
  testthat::expect_error(
    bag_gpx_import(
      dir_out = tempfile(), layer_output_name = "x", gpkg_name = "g",
      gpx_layer_type = "routes"
    ),
    "gpx_layer_type"
  )
})

testthat::test_that("bag_gpx_import rejects a time bound it cannot parse", {
  testthat::expect_error(
    bag_gpx_import(
      dir_out = tempfile(), layer_output_name = "x", gpkg_name = "g",
      time_start = "not-a-date"
    ),
    "not a date or time"
  )
})

testthat::test_that("bag_gpx_import reads only .gpx files from the waypoint directory", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir()
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  seen <- character()
  f <- stub_io(bag_gpx_import, on_read = function(dsn) seen <<- c(seen, basename(dsn)))

  f(
    dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
    layer_output_name = "2026_ai", gpkg_name = "gps_2026",
    gpx_layer_type = "waypoints"
  )

  # The donor used list.files(pattern = ".gpx"), an unanchored regex, so "weird_gpx.csv"
  # was read as GPX too.
  testthat::expect_setequal(seen, c("a.gpx", "b.gpx"))
})

testthat::test_that("bag_gpx_import reads only .gpx files from the track directories", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir()
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  seen <- character()
  f <- stub_io(bag_gpx_import, on_read = function(dsn) seen <<- c(seen, basename(dsn)))

  f(
    dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
    layer_output_name = "2026_ai", gpkg_name = "gps_2026",
    gpx_layer_type = "tracks"
  )

  # The donor passed `pattern` and `full.names` to fs::dir_ls(), which takes neither, so
  # they were absorbed silently and EVERY file in the directory was read. Measured: four
  # files in, four read.
  testthat::expect_setequal(seen, c("a.gpx", "b.gpx"))
})

testthat::test_that("bag_gpx_import prefixes every feature name with layer_output_name", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir(c("a.gpx"))
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  written <- NULL
  f <- stub_io(bag_gpx_import, on_write = function(obj, dsn) written <<- obj)

  f(
    dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
    layer_output_name = "2026_ai", gpkg_name = "gps_2026",
    gpx_layer_type = "waypoints"
  )

  testthat::expect_true(all(grepl("^2026_ai_", written$name)))
  testthat::expect_true("name_old" %in% names(written))
})

testthat::test_that("bag_gpx_import applies the time bounds as UTC", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir(c("a.gpx"))
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  # Two points, one either side of 2026-03-01.
  layer <- fake_points(c("2026-01-02 10:00:00", "2026-06-02 10:00:00"))

  written <- NULL
  f <- stub_io(bag_gpx_import, layer = layer, on_write = function(obj, dsn) written <<- obj)

  f(
    dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
    layer_output_name = "x", gpkg_name = "g",
    time_start = "2026-03-01",
    gpx_layer_type = "waypoints"
  )

  testthat::expect_equal(nrow(written), 1L)
  testthat::expect_match(written$name, "2026-06-02")
})

testthat::test_that("bag_gpx_import's UTC bound does not move with the machine zone", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir(c("a.gpx"))
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  # The point sits 04:00 UTC on the boundary day, INSIDE the eight-hour offset between UTC
  # and Pacific time. Parsed as UTC, "2026-03-01" is 00:00Z and the point is kept. Coerced
  # in a Pacific machine's zone -- which is what the donor's bare string comparison did --
  # the bound becomes 08:00Z and the point is dropped. The months-apart fixture in the test
  # above cannot tell those two apart; this one can.
  layer <- fake_points("2026-03-01 04:00:00")

  written <- NULL
  f <- stub_io(bag_gpx_import, layer = layer, on_write = function(obj, dsn) written <<- obj)

  testthat::skip_if_not_installed("withr")
  withr::with_envvar(c(TZ = "America/Vancouver"), {
    f(
      dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
      layer_output_name = "x", gpkg_name = "g",
      time_start = "2026-03-01",
      gpx_layer_type = "waypoints"
    )
  })

  testthat::expect_equal(nrow(written), 1L)
})

testthat::test_that("bag_gpx_import reads a bound given as a full timestamp", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir(c("a.gpx"))
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  layer <- fake_points(c("2026-01-02 08:00:00", "2026-01-02 18:00:00"))

  written <- NULL
  f <- stub_io(bag_gpx_import, layer = layer, on_write = function(obj, dsn) written <<- obj)

  f(
    dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
    layer_output_name = "x", gpkg_name = "g",
    time_start = "2026-01-02 12:00:00",
    gpx_layer_type = "waypoints"
  )

  testthat::expect_equal(nrow(written), 1L)
  testthat::expect_match(written$name, "18:00:00")
})

testthat::test_that("bag_gpx_import applies no bound when time_start and time_end are NULL", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir(c("a.gpx"))
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  written <- NULL
  f <- stub_io(bag_gpx_import, on_write = function(obj, dsn) written <<- obj)

  f(
    dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
    layer_output_name = "x", gpkg_name = "g",
    gpx_layer_type = "waypoints"
  )

  # Guard against the filter being applied unconditionally with a NULL bound.
  testthat::expect_equal(nrow(written), 2L)
})

testthat::test_that("bag_gpx_import derives time from the name when the layer has none", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir(c("a.gpx"))
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  layer <- fake_points(c("2026-01-02 10:00:00", "2026-06-02 10:00:00"), with_time = FALSE)

  written <- NULL
  f <- stub_io(bag_gpx_import, layer = layer, on_write = function(obj, dsn) written <<- obj)

  f(
    dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
    layer_output_name = "x", gpkg_name = "g",
    time_start = "2026-03-01",
    gpx_layer_type = "tracks"
  )

  testthat::expect_equal(nrow(written), 1L)
})

testthat::test_that("bag_gpx_import writes nothing when dates_view is TRUE", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir(c("a.gpx"))
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  wrote <- FALSE
  f <- stub_io(bag_gpx_import, on_write = function(obj, dsn) wrote <<- TRUE)

  testthat::expect_output(
    f(
      dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
      layer_output_name = "x", gpkg_name = "g",
      dates_view = TRUE, gpx_layer_type = "waypoints"
    ),
    "2026"
  )

  testthat::expect_false(wrote)
})

testthat::test_that("bag_gpx_import says so, and writes nothing, when there are no gpx files", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir(c("notes.txt"))
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  wrote <- FALSE
  f <- stub_io(bag_gpx_import, on_write = function(obj, dsn) wrote <<- TRUE)

  testthat::expect_message(
    f(
      dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
      layer_output_name = "x", gpkg_name = "g",
      gpx_layer_type = "waypoints"
    ),
    "No GPX files"
  )
  testthat::expect_false(wrote)
})

testthat::test_that("bag_gpx_import writes both a gpx and a gpkg per layer", {
  testthat::skip_if_not_installed("mockery")
  testthat::skip_if_not_installed("sf")

  d <- gpx_dir(c("a.gpx"))
  out <- tempfile("out_")
  on.exit(unlink(c(d, out), recursive = TRUE), add = TRUE)

  dests <- character()
  f <- stub_io(bag_gpx_import, on_write = function(obj, dsn) dests <<- c(dests, basename(dsn)))

  f(
    dir_gpx_waypoints = d, dir_gpx_tracks = d, dir_out = out,
    layer_output_name = "2026_ai", gpkg_name = "gps_2026",
    gpx_layer_type = "waypoints"
  )

  testthat::expect_setequal(dests, c("gps_waypoints_2026_ai.gpx", "gps_2026.gpkg"))
})

testthat::test_that("bag_gpx_import reports nothing-found for a track directory that does not exist", {
  testthat::skip_if_not_installed("sf")

  # The track defaults are two Garmin mount subdirectories. A unit that has never
  # archived has no Archive/, and an unmounted unit has neither, so fs::dir_ls() aborted
  # [ENOENT] before the function's own "nothing written" branch could run. Every other
  # test here passes a directory that exists.
  d_out <- tempfile("gpxout_")
  on.exit(unlink(d_out, recursive = TRUE), add = TRUE)

  testthat::expect_message(
    bag_gpx_import(
      dir_gpx_waypoints = gpx_dir(files = character()),
      dir_gpx_tracks = c("/no/such/dir/Archive", "/no/such/dir/Current"),
      dir_out = d_out,
      layer_output_name = "x",
      gpkg_name = "g",
      gpx_layer_type = "tracks"
    ),
    "No GPX files found"
  )
})
