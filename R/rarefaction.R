rarefy_curve <- function(otu_table,
                         max_depth = NULL,
                         num_iterations = 10,
                         seed = NULL) {

  if (!is.null(seed)) set.seed(seed)

  otu_table <- as.data.frame(otu_table)

  sample_sums <- colSums(otu_table)

  if (is.null(max_depth)) {
    max_depth <- min(sample_sums)
  }

  depths <- unique(round(seq(1, max_depth, length.out = 50)))

  out <- lapply(colnames(otu_table), function(sample_name) {

    sample_data <- otu_table[[sample_name]]
    sample_depth <- sum(sample_data)

    if (sample_depth < max_depth) return(NULL)

    tibble_depths <- lapply(depths, function(depth) {

      richness_vals <- replicate(
        num_iterations,
        {
          subsampled <- sample(
            names(sample_data),
            size = depth,
            prob = sample_data / sample_depth,
            replace = TRUE
          )
          length(unique(subsampled))
        }
      )

      tibble::tibble(
        sample = sample_name,
        depth = depth,
        richness = mean(richness_vals)
      )
    })

    dplyr::bind_rows(tibble_depths)
  })

  dplyr::bind_rows(out)
}