#' Extract the summary line from VSEARCH .stats files
#'
#' Reads the first line of each \code{.stats} file in a directory
#' (e.g. \code{"254834 reads, max len 439, avg 405.7"}) and returns the
#' values as a data frame, one row per file.
#'
#' @param directory Character. Path to directory containing \code{.stats} files.
#' @param output_csv Character or NULL. If given, a CSV of the result is written
#'   inside \code{directory}. Default \code{NULL} (no file written).
#'
#' @return A data.frame with columns \code{File}, \code{Reads}, \code{MaxLen}, \code{AvgLen}.
#'
#' @importFrom utils write.csv
#' @export
extract_stats_header <- function(directory, output_csv = NULL) {

  files <- list.files(directory, pattern = "\\.stats$", full.names = FALSE)
  if (length(files) == 0) {
    stop("No .stats files found in ", directory)
  }

  header_pattern <- "^\\s*(\\d+)\\s+reads,\\s+max len\\s+(\\d+),\\s+avg\\s+([\\d.]+)\\s*$"

  rows <- lapply(files, function(filename) {
    lines <- readLines(file.path(directory, filename), n = 10, warn = FALSE)
    m <- regmatches(lines, regexec(header_pattern, lines, perl = TRUE))
    m <- m[lengths(m) == 4]

    if (length(m) == 0) {
      warning("No summary line found in ", filename)
      return(NULL)
    }

    data.frame(
      File   = filename,
      Reads  = as.integer(m[[1]][2]),
      MaxLen = as.integer(m[[1]][3]),
      AvgLen = as.numeric(m[[1]][4]),
      stringsAsFactors = FALSE
    )
  })

  header_summary <- do.call(rbind, rows)

  if (is.null(header_summary)) {
    stop("No summary lines could be parsed from any .stats file")
  }
  rownames(header_summary) <- NULL

  if (!is.null(output_csv)) {
    write.csv(header_summary, file.path(directory, output_csv), row.names = FALSE)
  }

  header_summary
}
