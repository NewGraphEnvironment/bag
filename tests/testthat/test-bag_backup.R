make_file <- function(contents = "x") {
  dir_in <- fs::path(tempfile("in_"))
  fs::dir_create(dir_in)
  writeLines(contents, fs::path(dir_in, "background_layers.gpkg"))
  dir_in
}

testthat::test_that("bag_backup validates its arguments", {
  dir_in <- make_file()
  on.exit(unlink(dir_in, recursive = TRUE), add = TRUE)

  testthat::expect_error(
    bag_backup(1L, "background_layers.gpkg", tempdir()),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_backup(dir_in, 1L, tempdir()),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_backup(dir_in, "background_layers.gpkg", 1L),
    class = "chk_error"
  )
  testthat::expect_error(
    bag_backup(dir_in, "background_layers.gpkg", tempdir(), stamp = 1L),
    class = "chk_error"
  )
})

testthat::test_that("bag_backup rejects a file that does not exist", {
  dir_in <- make_file()
  on.exit(unlink(dir_in, recursive = TRUE), add = TRUE)

  testthat::expect_error(
    bag_backup(dir_in, "not-here.gpkg", tempfile("out_")),
    class = "chk_error"
  )
})

testthat::test_that("bag_backup copies the file and returns its path", {
  dir_in <- make_file("hello")
  dir_out <- tempfile("out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  out <- bag_backup(dir_in, "background_layers.gpkg", dir_out, stamp = "202610311200")

  testthat::expect_true(file.exists(out))
  testthat::expect_equal(readLines(out), "hello")
  testthat::expect_equal(basename(out), "background_layers_202610311200.gpkg")
})

testthat::test_that("bag_backup creates the output directory", {
  dir_in <- make_file()
  dir_out <- fs::path(tempfile("out_"), "nested", "deeper")
  on.exit(unlink(c(dir_in, dirname(dirname(dir_out))), recursive = TRUE), add = TRUE)

  testthat::expect_false(dir.exists(dir_out))
  bag_backup(dir_in, "background_layers.gpkg", dir_out, stamp = "s")
  testthat::expect_true(dir.exists(dir_out))
})

testthat::test_that("bag_backup keeps the extension and appends the stamp before it", {
  dir_in <- make_file()
  dir_out <- tempfile("out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  out <- bag_backup(dir_in, "background_layers.gpkg", dir_out, stamp = "abc")

  testthat::expect_equal(fs::path_ext(out), "gpkg")
  testthat::expect_match(basename(out), "^background_layers_abc\\.gpkg$")
})

testthat::test_that("bag_backup appends nothing when stamp is NULL", {
  dir_in <- make_file()
  dir_out <- tempfile("out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  out <- bag_backup(dir_in, "background_layers.gpkg", dir_out, stamp = NULL)

  testthat::expect_equal(basename(out), "background_layers.gpkg")
})

testthat::test_that("bag_backup defaults the stamp to a timestamp", {
  dir_in <- make_file()
  dir_out <- tempfile("out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  out <- bag_backup(dir_in, "background_layers.gpkg", dir_out)

  testthat::expect_match(basename(out), "^background_layers_[0-9]{12}\\.gpkg$")
})

testthat::test_that("bag_backup refuses to overwrite an existing backup", {
  dir_in <- make_file()
  dir_out <- tempfile("out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  bag_backup(dir_in, "background_layers.gpkg", dir_out, stamp = NULL)

  # fs::file_copy() would error on its own; this says why, which matters because with
  # stamp = NULL every second run lands here.
  testthat::expect_error(
    bag_backup(dir_in, "background_layers.gpkg", dir_out, stamp = NULL),
    "already exists"
  )
})

testthat::test_that("bag_backup leaves the source file in place", {
  dir_in <- make_file("original")
  dir_out <- tempfile("out_")
  on.exit(unlink(c(dir_in, dir_out), recursive = TRUE), add = TRUE)

  bag_backup(dir_in, "background_layers.gpkg", dir_out, stamp = "s")

  # a backup, not a move
  testthat::expect_true(file.exists(fs::path(dir_in, "background_layers.gpkg")))
  testthat::expect_equal(readLines(fs::path(dir_in, "background_layers.gpkg")), "original")
})
