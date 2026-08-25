#' Process VSEARCH .stats files and extract read retention for a chosen MaxEE level
#'
#' Reads all \code{.stats} files in a directory, parses read-length retention
#' tables produced by VSEARCH, and extracts counts for a chosen MaxEE level.
#' Handles VSEARCH's irregular spacing inside the parenthetical percentages
#' (e.g. \code{"376( 94.5%)"}) via regex rather than whitespace splitting.
#'
#' @param directory Character. Path to directory containing \code{.stats} files.
#' @param maxEE_level Character. One of \code{"MaxEE0.5"}, \code{"MaxEE1"}, \code{"MaxEE2"}.
#' @param output_csv Character. Output CSV filename (written inside \code{directory}).
#'   Default \code{"maxEE_summary.csv"}.
#'
#' @return A data.frame with columns \code{Length}, the selected MaxEE level, and \code{File}.
#'
#' @importFrom utils write.csv
#' @export
process_stats <- function(directory, maxEE_level, output_csv = "maxEE_summary.csv") {

  valid_levels <- c("MaxEE0.5", "MaxEE1", "MaxEE2")
  if (!maxEE_level %in% valid_levels) {
    stop(sprintf("maxEE_level must be one of %s",
                  paste(valid_levels, collapse = ", ")))
  }

  files <- list.files(directory, pattern = "\\.stats$", full.names = FALSE)

  if (length(files) == 0) {
    stop("No .stats files found")
  }

  row_pattern <- paste0(
    "^\\s*(\\d+)\\s+",
    "(\\d+)\\(\\s*[\\d.]+%\\)\\s+",
    "(\\d+)\\(\\s*[\\d.]+%\\)\\s+",
    "(\\d+)\\(\\s*[\\d.]+%\\)\\s*$"
  )

  dfs <- list()

  for (filename in files) {
    filepath <- file.path(directory, filename)
    lines <- readLines(filepath, warn = FALSE)

    matches <- regmatches(lines, regexec(row_pattern, lines, perl = TRUE))
    matches <- matches[lengths(matches) == 5]

    if (length(matches) == 0) {
      next
    }

    df <- do.call(rbind, lapply(matches, function(m) {
      data.frame(
        Length     = as.integer(m[2]),
        `MaxEE0.5` = as.integer(m[3]),
        MaxEE1     = as.integer(m[4]),
        MaxEE2     = as.integer(m[5]),
        check.names = FALSE
      )
    }))

    df$File <- filename
    dfs[[length(dfs) + 1]] <- df[, c("Length", maxEE_level, "File")]
  }

  if (length(dfs) == 0) {
    stop("No .stats files found")
  }

  maxEE_summary <- do.call(rbind, dfs)
  rownames(maxEE_summary) <- NULL

  if (maxEE_level == "MaxEE2") {
    max_by_file <- tapply(maxEE_summary[[maxEE_level]], maxEE_summary$File, max)
    min_by_file <- tapply(maxEE_summary[[maxEE_level]], maxEE_summary$File, min)
    saturation <- all(max_by_file == min_by_file)

    if (saturation) {
      warning("MaxEE2 may cause issues.")
    }
  }

  write.csv(maxEE_summary, file.path(directory, output_csv), row.names = FALSE)

  maxEE_summary
}
