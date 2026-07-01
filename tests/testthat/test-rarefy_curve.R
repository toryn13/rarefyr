test_that("rarefy_curve returns expected columns and no crash on names bug", {
  set.seed(42)
  otu <- matrix(rpois(15 * 4, lambda = 8), nrow = 15,
                dimnames = list(paste0("OTU", 1:15), paste0("S", 1:4)))

  curve <- rarefy_curve(otu, num_iterations = 3, step = 10, seed = 42)

  expect_s3_class(curve, "data.frame")
  expect_true(all(c("sample", "depth", "richness", "richness_sd") %in% names(curve)))
  expect_true(all(curve$richness >= 1))
  expect_true(all(curve$richness <= nrow(otu)))
})

test_that("samples below max_depth are dropped with a warning", {
  otu <- matrix(c(10, 10, 10, 10,   # sample A: depth 40
                  1, 1, 1, 1),      # sample B: depth 4 (shallow)
                nrow = 4,
                dimnames = list(paste0("OTU", 1:4), c("A", "B")))

  expect_warning(
    curve <- rarefy_curve(otu, max_depth = 40, num_iterations = 2, step = 5),
    "Excluding sample"
  )
  expect_true(all(curve$sample == "A"))
})

test_that("zero-count samples are dropped with a warning", {
  otu <- matrix(c(5, 5, 5, 0, 0, 0), nrow = 3,
                dimnames = list(paste0("OTU", 1:3), c("A", "B")))

  expect_warning(
    curve <- rarefy_curve(otu, num_iterations = 2, step = 5),
    "zero total counts"
  )
  expect_true(all(curve$sample == "A"))
})
