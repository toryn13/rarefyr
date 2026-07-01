#' Compute rarefaction curves for an OTU/ASV table
#'
#' Subsamples each sample in an OTU/ASV count table to a series of
#' sequencing depths and records the mean (and SD) observed richness
#' across repeated resamples. Useful for checking whether sequencing
#' depth was sufficient to capture community diversity.
#'
#' @param otu_table A matrix or data frame of counts with taxa/OTUs as
#'   rows and samples as columns. Row names should be OTU/taxon IDs.
#' @param max_depth Maximum sequencing depth to rarefy to. Defaults to
#'   the minimum total count across samples (i.e. the depth common to
#'   all samples). Samples with fewer total counts than `max_depth`
#'   are excluded (with a warning).
#' @param step Number of depth points to compute along the curve.
#'   Default 50.
#' @param num_iterations Number of resampling iterations per depth.
#'   Higher values give smoother curves at the cost of speed.
#'   Default 10.
#' @param seed Optional integer seed for reproducibility.
#'
#' @return A tibble with columns `sample`, `depth`, `richness` (mean
#'   observed richness across iterations) and `richness_sd` (standard
#'   deviation across iterations).
#'
#' @details
#' At each depth, `num_iterations` subsamples are drawn using
#' `stats::rmultinom()`, which resamples reads *with* replacement in
#' proportion to each OTU's relative abundance. This matches the
#' classic rarefaction resampling model (equivalent to drawing reads
#' one at a time and counting uniques, but computed directly via the
#' multinomial distribution for speed). It is a close approximation to
#' the exact (without-replacement / hypergeometric) rarefaction used by
#' e.g. `vegan::rarefy()`; for most teaching and QC purposes the two are
#' indistinguishable.
#'
#' @examples
#' set.seed(1)
#' otu <- matrix(rpois(20 * 6, lambda = 5), nrow = 20,
#'               dimnames = list(paste0("OTU", 1:20), paste0("S", 1:6)))
#' curve <- rarefy_curve(otu, num_iterations = 5, seed = 1)
#' head(curve)
#'
#' @export
rarefy_curve <- function(otu_table,
                          max_depth = NULL,
                          step = 50,
                          num_iterations = 10,
                          seed = NULL) {

  if (!is.null(seed)) set.seed(seed)

  otu_table <- as.data.frame(otu_table)

  if (nrow(otu_table) == 0 || ncol(otu_table) == 0) {
    stop("otu_table is empty.")
  }

  otu_ids <- rownames(otu_table)
  if (is.null(otu_ids)) {
    warning("otu_table has no row names (OTU/taxon IDs); using generic IDs.")
    otu_ids <- paste0("OTU", seq_len(nrow(otu_table)))
  }

  sample_sums <- colSums(otu_table)

  if (any(sample_sums == 0)) {
    zero_samples <- names(sample_sums)[sample_sums == 0]
    warning("Dropping sample(s) with zero total counts: ",
            paste(zero_samples, collapse = ", "))
    keep <- sample_sums > 0
    otu_table <- otu_table[, keep, drop = FALSE]
    sample_sums <- sample_sums[keep]
  }

  if (ncol(otu_table) == 0) {
    stop("No samples remain after removing zero-count samples.")
  }

  if (is.null(max_depth)) {
    max_depth <- min(sample_sums)
  }

  too_shallow <- names(sample_sums)[sample_sums < max_depth]
  if (length(too_shallow) > 0) {
    warning("Excluding sample(s) with fewer than max_depth (", max_depth,
            ") total counts: ", paste(too_shallow, collapse = ", "))
  }

  n_points <- max(1, min(step, max_depth))
  depths <- unique(round(seq(1, max_depth, length.out = n_points)))

  results <- lapply(colnames(otu_table), function(sample_name) {

    depth_total <- sample_sums[[sample_name]]
    if (depth_total < max_depth) return(NULL)

    counts <- otu_table[[sample_name]]
    names(counts) <- otu_ids
    counts <- counts[counts > 0]

    per_depth <- lapply(depths, function(d) {
      richness_vals <- vapply(seq_len(num_iterations), function(i) {
        drawn <- stats::rmultinom(1, size = d, prob = counts)[, 1]
        sum(drawn > 0)
      }, numeric(1))

      tibble::tibble(
        sample = sample_name,
        depth = d,
        richness = mean(richness_vals),
        richness_sd = stats::sd(richness_vals)
      )
    })

    dplyr::bind_rows(per_depth)
  })

  dplyr::bind_rows(results)
}
