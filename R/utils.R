# ==============================================================================
# Utility Functions
# ==============================================================================

#' Pipe operator
#'
#' See \code{dplyr::\link[dplyr:reexports]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL


#' Convert to numeric, handling suppression markers
#'
#' Iowa uses various markers for suppressed data (*, <10, N/A, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  # Handle NULL or empty input
  if (is.null(x) || length(x) == 0) {
    return(numeric(0))
  }

  # Convert to character if needed
  x <- as.character(x)

  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)

  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<10", "N/A", "NA", "", "NULL")] <- NA_character_

  # Handle any remaining non-numeric patterns
  x[grepl("^<", x)] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Get the minimum available year
#'
#' Iowa has enrollment data by grade, race, ethnicity, and gender from 1991-92.
#'
#' @return Integer representing earliest available year
#' @keywords internal
get_min_year <- function() {
  1992L
}


#' Get the maximum available year
#'
#' @return Integer representing most recent available year
#' @keywords internal
get_max_year <- function() {
  2025L
}


#' Get available years for Iowa enrollment data
#'
#' Returns the range of years for which enrollment data is available.
#' Iowa has data from 1991-92 (end_year = 1992) through 2024-25 (end_year = 2025).
#'
#' @return Integer vector of available years
#' @export
#' @examples
#' get_available_years()
get_available_years <- function() {
  get_min_year():get_max_year()
}


#' Validate year parameter
#'
#' @param end_year Year to validate
#' @return TRUE if valid, throws error if not
#' @keywords internal
validate_year <- function(end_year) {
  min_year <- get_min_year()
  max_year <- get_max_year()

  if (!is.numeric(end_year) || length(end_year) != 1) {
    stop("end_year must be a single numeric value")
  }

  if (end_year < min_year || end_year > max_year) {
    stop(paste0(
      "end_year must be between ", min_year, " and ", max_year, ".\n",
      "You provided: ", end_year, "\n",
      "Available years: ", min_year, "-", max_year
    ))
  }

  TRUE
}


#' Clean district name
#'
#' Standardizes district names by trimming whitespace and
#' handling common formatting issues.
#'
#' @param x Character vector of names
#' @return Cleaned character vector
#' @keywords internal
clean_district_name <- function(x) {
  if (is.null(x)) return(NA_character_)
  x <- trimws(x)
  x[x == ""] <- NA_character_
  x
}


#' Clean school name
#'
#' Standardizes school names by trimming whitespace and
#' handling common formatting issues.
#'
#' @param x Character vector of names
#' @return Cleaned character vector
#' @keywords internal
clean_school_name <- function(x) {
  if (is.null(x)) return(NA_character_)
  x <- trimws(x)
  x[x == ""] <- NA_character_
  x
}


#' Standardize district ID
#'
#' Ensures district IDs are formatted consistently as 4-digit strings.
#'
#' @param x Character or numeric vector of IDs
#' @return Character vector of standardized IDs
#' @keywords internal
standardize_district_id <- function(x) {
  if (is.null(x)) return(NA_character_)

  # Convert to character
  x <- as.character(x)

  # Remove any whitespace
  x <- trimws(x)

  # Pad with leading zeros to 4 digits
  x <- sprintf("%04s", x)

  # Replace malformed entries with NA
  x[!grepl("^[0-9]{4}$", x)] <- NA_character_

  x
}


#' Standardize school ID
#'
#' Ensures school IDs are formatted consistently.
#'
#' @param x Character or numeric vector of IDs
#' @return Character vector of standardized IDs
#' @keywords internal
standardize_school_id <- function(x) {
  if (is.null(x)) return(NA_character_)

  # Convert to character
  x <- as.character(x)

  # Remove any whitespace
  x <- trimws(x)

  # Replace empty entries with NA
  x[x == ""] <- NA_character_

  x
}
