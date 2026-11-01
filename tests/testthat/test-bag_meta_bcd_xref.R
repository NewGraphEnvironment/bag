# bcdata::bcdc_search() is mocked — no test in this package touches the network.
#
# mockery::stub() rather than testthat::local_mocked_bindings(), for the reason recorded in
# test-bag_bcdata.R: the function calls bcdata:: fully qualified, and rebinding in the
# bcdata namespace does not intercept a `::` call.

# One catalogue package, shaped like a bcdc_search() element. `wms_rows` says which rows of
# resource_df carry the wms resource, so a fixture can put it anywhere — the function takes
# the row index from the UNFILTERED resource_df, which is the part worth pinning.
fake_pkg <- function(id, notes, formats, object_names) {
  list(
    id = id,
    notes = notes,
    resource_df = data.frame(
      format = formats,
      id = paste0("ds-", seq_along(formats)),
      url = paste0("https://example.com/", seq_along(formats)),
      stringsAsFactors = FALSE
    ),
    resources = lapply(object_names, function(nm) list(object_name = nm))
  )
}

fake_search <- function() {
  list(
    # wms first
    `pkg-a` = fake_pkg("id-a", "Package A notes", c("wms", "csv"), c("WHSE_A.LAYER_A", "ignored")),
    # wms second — the row index must follow the unfiltered resource_df
    `pkg-b` = fake_pkg("id-b", "Package B notes", c("csv", "wms"), c("ignored", "WHSE_B.LAYER_B")),
    # two wms resources — triggers the multi-resource warning
    `pkg-c` = fake_pkg("id-c", "Package C notes", c("wms", "wms"), c("WHSE_C.ONE", "WHSE_C.TWO")),
    # excluded by default
    `bc-web-map-library` = fake_pkg("id-x", "Excluded", "wms", "WHSE_X.NOPE")
  )
}

stub_search <- function(f, value = fake_search()) {
  mockery::stub(f, "bcdata::bcdc_search", function(...) value)
  f
}

testthat::test_that("bag_meta_bcd_xref validates pkg_exclude", {
  testthat::expect_error(bag_meta_bcd_xref(pkg_exclude = 1L), class = "chk_error")
})

testthat::test_that("bag_meta_bcd_xref returns the documented columns", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_search(bag_meta_bcd_xref)
  out <- suppressMessages(f())

  testthat::expect_named(
    out,
    c("object_name", "package_name", "url_browser", "description",
      "id_package", "id_dataset", "url_download")
  )
})

testthat::test_that("bag_meta_bcd_xref keeps only wms resources and drops pkg_exclude", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_search(bag_meta_bcd_xref)
  out <- suppressMessages(f())

  # pkg-a 1, pkg-b 1, pkg-c 2, and bc-web-map-library excluded
  testthat::expect_equal(nrow(out), 4L)
  testthat::expect_false("bc-web-map-library" %in% out$package_name)
  testthat::expect_setequal(unique(out$package_name), c("pkg-a", "pkg-b", "pkg-c"))
})

testthat::test_that("bag_meta_bcd_xref honours a caller-supplied pkg_exclude", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_search(bag_meta_bcd_xref)
  out <- suppressMessages(f(pkg_exclude = c("pkg-a", "pkg-c")))

  # the default exclusion is replaced, not added to, so bc-web-map-library returns
  testthat::expect_setequal(unique(out$package_name), c("pkg-b", "bc-web-map-library"))
})

testthat::test_that("bag_meta_bcd_xref pairs each wms resource with its own object name", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_search(bag_meta_bcd_xref)
  out <- suppressMessages(f())

  # pkg-c publishes TWO wms resources. Joining on package_name alone gave 2 x 2 = 4 rows
  # for it, and half of those paired one resource's object_name with the other's dataset
  # id. Pin the pairing, not just the count: a row-count assertion alone passes against a
  # join that returns the right number of wrong rows.
  c_rows <- out[out$package_name == "pkg-c", ]
  testthat::expect_equal(nrow(c_rows), 2L)
  testthat::expect_setequal(c_rows$object_name, c("whse_c.one", "whse_c.two"))
  testthat::expect_equal(c_rows$object_name[c_rows$id_dataset == "ds-1"], "whse_c.one")
  testthat::expect_equal(c_rows$object_name[c_rows$id_dataset == "ds-2"], "whse_c.two")
})

testthat::test_that("bag_meta_bcd_xref joins without a many-to-many relationship", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_search(bag_meta_bcd_xref)

  # dplyr warns on an unexpected many-to-many join. That warning was the tell for the
  # defect above, so assert it does not fire.
  testthat::expect_no_warning(suppressMessages(f()))
})

testthat::test_that("bag_meta_bcd_xref takes the object name from the unfiltered row index", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_search(bag_meta_bcd_xref)
  out <- suppressMessages(f())

  # pkg-b's wms resource is the SECOND row of resource_df, so its object name must come
  # from resources[[2]]. Taking the index after the format filter would give "ignored".
  testthat::expect_equal(out$object_name[out$package_name == "pkg-b"], "whse_b.layer_b")
})

testthat::test_that("bag_meta_bcd_xref lower-cases the object name", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_search(bag_meta_bcd_xref)
  out <- suppressMessages(f())

  testthat::expect_equal(out$object_name, tolower(out$object_name))
  testthat::expect_true("whse_a.layer_a" %in% out$object_name)
})

testthat::test_that("bag_meta_bcd_xref builds url_browser from the package id", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_search(bag_meta_bcd_xref)
  out <- suppressMessages(f())

  testthat::expect_equal(
    out$url_browser[out$package_name == "pkg-a"],
    "https://catalogue.data.gov.bc.ca/dataset/id-a"
  )
  testthat::expect_equal(out$id_package[out$package_name == "pkg-a"], "id-a")
  testthat::expect_equal(out$description[out$package_name == "pkg-a"], "Package A notes")
})

testthat::test_that("bag_meta_bcd_xref carries url_download and id_dataset through", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_search(bag_meta_bcd_xref)
  out <- suppressMessages(f())

  # pkg-b's wms row is the second, so its id and url are the second of each
  testthat::expect_equal(out$id_dataset[out$package_name == "pkg-b"], "ds-2")
  testthat::expect_equal(out$url_download[out$package_name == "pkg-b"], "https://example.com/2")
})

testthat::test_that("bag_meta_bcd_xref warns when a package publishes several wms resources", {
  testthat::skip_if_not_installed("mockery")

  f <- stub_search(bag_meta_bcd_xref)

  testthat::expect_message(f(), "pkg-c")
})

testthat::test_that("bag_meta_bcd_xref stays quiet when no package has several wms resources", {
  testthat::skip_if_not_installed("mockery")

  one <- list(`pkg-a` = fake_pkg("id-a", "A", c("wms", "csv"), c("WHSE_A.LAYER_A", "x")))
  f <- stub_search(bag_meta_bcd_xref, one)

  # Guard against the warning firing unconditionally: the test above would pass either way.
  testthat::expect_silent(f())
})

testthat::test_that("bag_meta_bcd_xref flags a package with no resource_df", {
  testthat::skip_if_not_installed("mockery")

  broken <- fake_search()
  broken[["pkg-a"]]$resource_df <- NULL
  f <- stub_search(bag_meta_bcd_xref, broken)

  testthat::expect_message(try(f(), silent = TRUE), "resource_df")
})
