#' Rarefy an OTU table to an even sequencing depth
#'
#' @param otu_table Count table with taxa as rows and samples as columns.
#' @param depth Reads to keep per sample. Defaults to the smallest sample total.
#' @param num_iterations Number of subsampling draws. If > 1, counts are
#'   averaged across draws (so may be non-integer).
#' @param seed Optional random seed for reproducibility.
#'
#' @return A data frame with the same taxa as `otu_table`, every retained
#'   sample summing to `depth`. Samples with fewer than `depth` reads are dropped.
#' @export
rarefy_table <- function(otu_table,
                         depth = NULL,
                         num_iterations = 1,
                         seed = NULL) {

  if (!is.null(seed)) set.seed(seed)

  counts <- as.matrix(as.data.frame(otu_table))

  if (!is.numeric(counts) || anyNA(counts) ||
      any(counts < 0) || any(counts != round(counts))) {
    stop("`otu_table` must contain non-negative integer counts with no NAs.")
  }

  sample_sums <- colSums(counts)

  if (is.null(depth)) depth <- min(sample_sums)

  keep <- sample_sums >= depth

  if (!any(keep)) stop("No samples have at least ", depth, " reads.")

  if (any(!keep)) {
    message("Dropped ", sum(!keep), " sample(s) below depth ", depth, ": ",
            paste(colnames(counts)[!keep], collapse = ", "))
  }

  n_taxa <- nrow(counts)

  out <- vapply(which(keep), function(j) {

    # one entry per read, labelled by taxon index
    pool <- rep.int(seq_len(n_taxa), counts[, j])

    draws <- replicate(
      num_iterations,
      tabulate(pool[sample.int(length(pool), depth)], nbins = n_taxa)
    )

    rowMeans(matrix(draws, nrow = n_taxa))
  }, numeric(n_taxa))

  out <- matrix(out, nrow = n_taxa,
                dimnames = list(rownames(counts), colnames(counts)[keep]))

  as.data.frame(out)
}