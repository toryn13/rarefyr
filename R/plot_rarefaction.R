#' Plot rarefaction curves
#'
#' @param rarefaction_df Output of [rarefy_curve()], with columns
#'   `sample`, `depth`, `richness`, and (optionally) `richness_sd`.
#' @param metadata Optional data frame with a `sample` column, used to
#'   color curves by a grouping variable instead of by individual
#'   sample.
#' @param group_var Name (string) of the column in `metadata` to color
#'   by. Required if `metadata` is supplied.
#' @param show_error_ribbon Logical; if `TRUE` and `richness_sd` is
#'   present, draw a +/- 1 SD ribbon around each curve. Default `TRUE`.
#'
#' @return A ggplot object.
#'
#' @examples
#' set.seed(1)
#' otu <- matrix(rpois(20 * 6, lambda = 5), nrow = 20,
#'               dimnames = list(paste0("OTU", 1:20), paste0("S", 1:6)))
#' curve <- rarefy_curve(otu, num_iterations = 5, seed = 1)
#' plot_rarefaction(curve)
#'
#' @export
plot_rarefaction <- function(rarefaction_df,
                              metadata = NULL,
                              group_var = NULL,
                              show_error_ribbon = TRUE) {

  df <- rarefaction_df

  if (!is.null(metadata)) {
    if (is.null(group_var)) {
      stop("Supply `group_var` (a column name in `metadata`) when using `metadata`.")
    }
    if (!"sample" %in% names(metadata)) {
      stop("`metadata` must contain a `sample` column to join on.")
    }
    df <- dplyr::left_join(df, metadata, by = "sample")
    colour_var <- group_var
  } else {
    colour_var <- "sample"
  }

  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(x = .data$depth, y = .data$richness,
                 group = .data$sample, colour = .data[[colour_var]])
  ) +
    ggplot2::geom_line(linewidth = 0.7)

  if (show_error_ribbon && "richness_sd" %in% names(df)) {
    p <- p + ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$richness - .data$richness_sd,
                   ymax = .data$richness + .data$richness_sd,
                   fill = .data[[colour_var]]),
      alpha = 0.15, colour = NA
    )
  }

  p +
    ggplot2::labs(
      x = "Sequencing depth",
      y = "Observed richness",
      title = "Rarefaction curves",
      colour = colour_var,
      fill = colour_var
    ) +
    ggplot2::theme_minimal()
}
