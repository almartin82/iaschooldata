# ==============================================================================
# Utility Functions
# ==============================================================================

#' @importFrom rlang .data
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
#' Iowa has enrollment data from 1946-47, though not all years have data:
#' - 1946-47, 1948-49 (no 1947-48)
#' - 1950-51 to 1969-70 (missing 1951-52, 1953-54)
#' - 1972-73 to present (missing 1970-71, 1971-72)
#'
#' @return Integer representing earliest available year
#' @keywords internal
get_min_year <- function() {
  1947L
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
#' Returns the years for which enrollment data is available.
#' Iowa has historical data from 1946-47 and modern data through 2024-25.
#'
#' Note: Not all years have data available. Missing years include:
#' - 1948 (1947-48)
#' - 1950 (1949-50)
#' - 1952 (1951-52)
#' - 1954 (1953-54)
#' - 1971 (1970-71)
#' - 1972 (1971-72)
#'
#' @param include_missing If FALSE (default), returns only years with data.
#'   If TRUE, returns full range from min to max year.
#' @return Integer vector of available years
#' @export
#' @examples
#' get_available_years()
#' get_available_years(include_missing = TRUE)
get_available_years <- function(include_missing = FALSE) {
  if (include_missing) {
    get_min_year():get_max_year()
  } else {
    # Years with actual data
    historical_years <- c(
      1947, 1949,  # 1946-47, 1948-49
      1951, 1953, 1955:1970,  # 1950-51 to 1969-70 (gaps in 1952, 1954)
      1973:get_max_year()  # 1972-73 to present (gap in 1971-72)
    )
    historical_years
  }
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

  # Check if this year has data available
  available <- get_available_years(include_missing = FALSE)
  if (!(end_year %in% available)) {
    stop(paste0(
      "No data available for year ", end_year, ".\n",
      "This year is in a gap in the historical data.\n",
      "Missing years: 1948, 1950, 1952, 1954, 1971, 1972"
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
