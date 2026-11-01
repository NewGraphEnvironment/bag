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

testthat::test_that("bag_gpkg_refresh refuses a GeoPackage with more than one layer", {
  testthat::skip_if_not_installed("sf")

  # st_read() with no `layer` silently takes the first, and the write-back deletes the
  # whole file -- so without this guard a second layer was destroyed. Measured before the
  # guard: `sites` + `aoi` came back as one layer, `aoi` gone.
  path <- seed_point_gpkg()
  on.exit(unlink(dirname(path), recursive = TRUE), add = TRUE)
  aoi <- sf::st_as_sf(sf::st_sfc(
    sf::st_polygon(list(cbind(c(-129, -118, -118, -129, -129), c(54, 54, 55, 55, 54)))),
    crs = 4326
  ))
  sf::st_write(aoi, path, layer = "aoi", quiet = TRUE)
  testthat::expect_length(sf::st_layers(path)$name, 2L)

  testthat::expect_error(
    bag_gpkg_refresh(path_gpkg = path, write_to_csv = FALSE, write_to_rdata = FALSE),
    "exactly one spatial layer"
  )

  # and nothing was written on the way to the abort
  testthat::expect_setequal(sf::st_layers(path)$name, c("form_fiss_site_2026", "aoi"))
})

testthat::test_that("bag_gpkg_refresh keeps the layer's name when writing back", {
  testthat::skip_if_not_installed("sf")

  # st_write() names the layer after the file's base name unless told otherwise, so a
  # layer called `sites` came back as `form_fiss_site_2026` and every QGIS project or
  # Mergin form naming it broke. seed_point_gpkg()'s own layer name already equals the
  # basename, so the rename is invisible to every other test here.
  path <- seed_point_gpkg()
  on.exit(unlink(dirname(path), recursive = TRUE), add = TRUE)
  d <- sf::st_read(path, quiet = TRUE)
  unlink(path)
  sf::st_write(d, path, layer = "sites", quiet = TRUE)
  testthat::expect_equal(sf::st_layers(path)$name, "sites")

  suppressWarnings(bag_gpkg_refresh(
    path_gpkg = path,
    write_back_to_path = TRUE,
    write_to_csv = FALSE,
    write_to_rdata = FALSE
  ))

  testthat::expect_equal(sf::st_layers(path)$name, "sites")
})

testthat::test_that("bag_gpkg_refresh handles a point layer with no features", {
  testthat::skip_if_not_installed("sf")

  # A freshly created, not-yet-filled field form. sf reads its geometry as sfc_GEOMETRY,
  # and with update_utm on, the UTM step then has no zones to loop over.
  path <- fs::path(tempfile("emptyform_"), "form_fiss_site_2026.gpkg")
  fs::dir_create(dirname(path))
  on.exit(unlink(dirname(path), recursive = TRUE), add = TRUE)
  d <- sf::st_read(seed_point_gpkg(), quiet = TRUE)
  sf::st_write(d[0, ], path, quiet = TRUE)

  out <- suppressWarnings(bag_gpkg_refresh(
    path_gpkg = path,
    write_to_csv = FALSE,
    write_to_rdata = FALSE,
    return_object = TRUE
  ))

  testthat::expect_s3_class(out, "sf")
  testthat::expect_equal(nrow(out), 0L)
  testthat::expect_true(all(c("easting", "northing", "utm_zone") %in% names(out)))
})

testthat::test_that("bag_gpkg_refresh handles a GeoPackage named after one of its own locals", {
  testthat::skip_if_not_installed("sf")

  # The .RData block assign()ed into the function's own frame, so `dat.gpkg` rebound and
  # then rm()'d the working object and the call died at return(dat), while
  # `obj_name.gpkg` handed save() an sf object where it wanted a name. Both aborted after
  # write_back_to_path had already rewritten the file.
  src <- seed_point_gpkg()
  on.exit(unlink(dirname(src), recursive = TRUE), add = TRUE)
  d <- sf::st_read(src, quiet = TRUE)

  for (nm in c("dat", "obj_name", "layer_name", "path_gpkg")) {
    dir <- tempfile("collide_")
    fs::dir_create(dir)
    path <- fs::path(dir, paste0(nm, ".gpkg"))
    sf::st_write(d, path, layer = nm, quiet = TRUE)

    out <- suppressWarnings(bag_gpkg_refresh(
      path_gpkg = path,
      dir_backup = fs::path(dir, "backup"),
      write_to_csv = FALSE,
      write_to_rdata = TRUE,
      return_object = TRUE
    ))

    testthat::expect_s3_class(out, "sf")
    testthat::expect_true(fs::file_exists(fs::path(dir, "backup", paste0(nm, ".RData"))))
    unlink(dir, recursive = TRUE)
  }
})

testthat::test_that("bag_gpkg_refresh accepts a form carrying a QGIS style table", {
  testthat::skip_if_not_installed("sf")
  testthat::skip_if_not_installed("RSQLite")
  testthat::skip_if_not_installed("DBI")

  # st_layers() lists QGIS's `layer_styles` support table, so counting every layer
  # refused a styled Mergin field form -- the documented use case -- by any argument
  # combination. Support tables carry no geometry type, which is the discriminator.
  path <- seed_point_gpkg()
  on.exit(unlink(dirname(path), recursive = TRUE), add = TRUE)
  con <- DBI::dbConnect(RSQLite::SQLite(), path)
  DBI::dbExecute(
    con,
    "CREATE TABLE layer_styles (id INTEGER PRIMARY KEY, f_table_name TEXT, styleqml TEXT)"
  )
  DBI::dbExecute(
    con,
    "INSERT INTO layer_styles (f_table_name, styleqml) VALUES ('sites', '<qgis/>')"
  )
  DBI::dbDisconnect(con)
  testthat::expect_length(sf::st_layers(path)$name, 2L)

  out <- suppressWarnings(bag_gpkg_refresh(
    path_gpkg = path,
    write_back_to_path = TRUE,
    write_to_csv = FALSE,
    write_to_rdata = FALSE,
    return_object = TRUE
  ))

  testthat::expect_s3_class(out, "sf")

  # and the style survived the write-back: delete_dsn would have taken the whole file
  con <- DBI::dbConnect(RSQLite::SQLite(), path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  testthat::expect_equal(
    DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM layer_styles")$n,
    1L
  )
})

testthat::test_that("bag_gpkg_refresh refuses a layer whose CRS is undefined", {
  testthat::skip_if_not_installed("sf")

  # The sibling over the same container, bag_gpkg_to_geojson(), checks this; this one
  # did not, so an srs_id of 0 had its coordinates taken for WGS 84 and a UTM zone
  # derived from numbers that are not degrees, while -1 aborted out of GDAL naming
  # neither the layer nor the CRS.
  path <- fs::path(tempfile("nocrs_refresh_"), "sites.gpkg")
  fs::dir_create(dirname(path))
  on.exit(unlink(dirname(path), recursive = TRUE), add = TRUE)
  d <- sf::st_as_sf(
    data.frame(site = c("a", "b"), x = c(1, 2), y = c(1, 2)),
    coords = c("x", "y"), crs = NA
  )
  suppressWarnings(sf::st_write(d, path, layer = "sites", quiet = TRUE))

  testthat::expect_error(
    bag_gpkg_refresh(path_gpkg = path, write_to_csv = FALSE, write_to_rdata = FALSE),
    "no usable CRS"
  )
})
