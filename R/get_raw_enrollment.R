# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from the
# Iowa Department of Education.
#
# Data is available from:
# https://educate.iowa.gov/pk-12/data/education-statistics
#
# Iowa provides Excel files with enrollment by grade, race, ethnicity, and gender.
# Data availability:
# - Modern data (1992-2025): District and school level with demographics
# - Historical data (1947-1991): District level only, grade enrollment only
#   - 1946-47, 1948-49 (media 10321)
#   - 1950-51 to 1969-70 (media 10322)
#   - 1972-73 to 1985-86 (media 5590)
#   - 1986-87 to 1991-92 (media 5591)
#
# URL pattern: https://educate.iowa.gov/media/{media_id}/download?inline
#
# ==============================================================================

#' Base URL for Iowa Department of Education data files
#'
#' @keywords internal
iowa_base_url <- function() {
  "https://educate.iowa.gov/media/"
}


#' Check if year is in historical range
#'
#' Historical data (1947-1991) has a different format than modern data.
#'
#' @param end_year School year end
#' @return TRUE if year is in historical range
#' @keywords internal
is_historical_year <- function(end_year) {
  end_year >= 1947 && end_year <= 1991
}


#' Get historical file info for a given year
#'
#' Returns the media ID and year format for historical enrollment files.
#' Historical files contain multiple years of data.
#'
#' @param end_year School year end (e.g., 1970 for 1969-70)
#' @return List with media_id and school_year_format
#' @keywords internal
get_historical_file_info <- function(end_year) {
  # Map end years to their source files
  # Media ID 10321: 1946-47, 1948-49 (years 1947, 1949)
  # Media ID 10322: 1950-51 to 1969-70 (years 1951, 1953, 1955-1970)
  # Media ID 5590: 1972-73 to 1985-86 (years 1973-1986)
  # Media ID 5591: 1986-87 to 1991-92 (years 1987-1992)

  if (end_year %in% c(1947, 1949)) {
    list(
      media_id = "10321",
      skip_rows = 6,
      year_col = "School Year",
      district_id_col = NULL,  # No district IDs in this file
      has_special_ed = FALSE
    )
  } else if (end_year >= 1951 && end_year <= 1970) {
    list(
      media_id = "10322",
      skip_rows = 5,
      year_col = "School Year",
      district_id_col = "District Number",
      has_special_ed = FALSE
    )
  } else if (end_year >= 1973 && end_year <= 1986) {
    list(
      media_id = "5590",
      skip_rows = 6,
      year_col = "Year",
      district_id_col = "District Code",
      has_special_ed = TRUE
    )
  } else if (end_year >= 1987 && end_year <= 1991) {
    list(
      media_id = "5591",
      skip_rows = 7,
      year_col = "Year",
      district_id_col = "District Code",
      has_special_ed = TRUE
    )
  } else {
    stop(paste("Year", end_year, "is not in historical range (1947-1991) or data is not available"))
  }
}


#' Get media ID for enrollment data file
#'
#' Returns the media ID used in Iowa DOE download URLs for each year.
#' These IDs are extracted from the Education Statistics page.
#'
#' @param end_year School year end (e.g., 2025 for 2024-25)
#' @param level Data level: "district" or "school"
#' @return Character string with media ID
#' @keywords internal
get_media_id <- function(end_year, level = "district") {

  # Media IDs for "Iowa Public School PreK-12 Enrollment by District"
  # (enrollment by grade, race, ethnicity, gender)
  district_ids <- c(
    "2025" = "10909",
    "2024" = "9343",
    "2023" = "6027",
    "2022" = "7630",
    "2021" = "6898",
    "2020" = "5286",
    "2019" = "4688",
    "2018" = "4094",
    "2017" = "3390",
    "2016" = "2842",
    "2015" = "2646",
    "2014" = "2263",
    "2013" = "1546",
    "2012" = "1342",
    "2011" = "1343",
    "2010" = "1344",
    "2009" = "1345",
    "2008" = "1346",
    "2007" = "1347",
    "2006" = "1348",
    "2005" = "1349",
    "2004" = "1350",
    "2003" = "1351",
    "2002" = "1352",
    "2001" = "1353",
    "2000" = "1354",
    "1999" = "1355",
    "1998" = "1356",
    "1997" = "1357",
    "1996" = "1557",
    "1995" = "1359",
    "1994" = "1360",
    "1993" = "9136",
    "1992" = "9137"
  )

  # Media IDs for "Iowa Public School PreK-12 Enrollment by Building"
  school_ids <- c(
    "2025" = "10910",
    "2024" = "9344",
    "2023" = "6028",
    "2022" = "7631",
    "2021" = "6899",
    "2020" = "5285",
    "2019" = "4687",
    "2018" = "4093",
    "2017" = "3391",
    "2016" = "2843",
    "2015" = "2645",
    "2014" = "2262",
    "2013" = "1552",
    "2012" = "1551",
    "2011" = "1550",
    "2010" = "1549",
    "2009" = "1548",
    "2008" = "1547",
    "2007" = "1546",
    "2006" = "1545",
    "2005" = "1544",
    "2004" = "1543",
    "2003" = "1542",
    "2002" = "1541",
    "2001" = "1540",
    "2000" = "1539",
    "1999" = "1538",
    "1998" = "1537",
    "1997" = "1536",
    "1996" = "1535",
    "1995" = "1534",
    "1994" = "1556",
    "1993" = "1554",
    "1992" = "1553"
  )

  year_key <- as.character(end_year)

  if (level == "district") {
    id <- district_ids[year_key]
  } else if (level == "school") {
    id <- school_ids[year_key]
  } else {
    stop("level must be 'district' or 'school'")
  }

  if (is.na(id)) {
    stop(paste("No media ID found for year", end_year, "level", level))
  }

  id
}


#' Build download URL for Iowa DOE data
#'
#' @param media_id Media ID from get_media_id()
#' @return Full download URL
#' @keywords internal
build_download_url <- function(media_id) {
  paste0(iowa_base_url(), media_id, "/download?inline")
}


#' Download raw enrollment data from Iowa DOE
#'
#' Downloads district and school enrollment data from Iowa Department of
#' Education's Education Statistics page.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return List with district and school data frames
#' @keywords internal
get_raw_enr <- function(end_year) {

  # Validate year
  validate_year(end_year)

  message(paste("Downloading Iowa enrollment data for", end_year, "..."))

  # Check if this is a historical year
  if (is_historical_year(end_year)) {
    # Historical data is district-level only
    message("  Downloading historical district data...")
    district_data <- download_historical_excel(end_year)

    list(
      district = district_data,
      school = data.frame(),  # No school-level data for historical years
      is_historical = TRUE
    )
  } else {
    # Modern data - download both district and school
    message("  Downloading district data...")
    district_data <- download_iowa_excel(end_year, "district")

    message("  Downloading school data...")
    school_data <- download_iowa_excel(end_year, "school")

    list(
      district = district_data,
      school = school_data,
      is_historical = FALSE
    )
  }
}


#' Download and read Iowa DOE Excel file
#'
#' Downloads an Excel file from Iowa DOE and reads it into a data frame.
#' Iowa files have header rows that need to be detected and skipped.
#'
#' @param end_year School year end
#' @param level Data level: "district" or "school"
#' @return Data frame with enrollment data
#' @keywords internal
download_iowa_excel <- function(end_year, level) {

  media_id <- get_media_id(end_year, level)
  url <- build_download_url(media_id)

  # First do HEAD request to detect file format from Content-Disposition
  head_response <- httr::HEAD(url, httr::timeout(30))
  content_disp <- httr::headers(head_response)[["content-disposition"]]

  # Detect extension from filename in header, default to xlsx
  file_ext <- if (!is.null(content_disp) && grepl("\\.xls\"", content_disp)) ".xls" else ".xlsx"
  temp_file <- tempfile(fileext = file_ext)

  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(300)
    )

    if (httr::http_error(response)) {
      warning(paste("Failed to download", level, "data for", end_year,
                    "- HTTP error:", httr::status_code(response)))
      return(data.frame())
    }

    # Check file size
    file_info <- file.info(temp_file)
    if (file_info$size < 1000) {
      warning(paste("Downloaded file appears too small for", level, "data"))
      return(data.frame())
    }

    # Read Excel file - detect header row
    # Iowa files have title rows at top, need to find actual headers
    df_raw <- readxl::read_excel(
      temp_file,
      col_names = FALSE,
      col_types = "text"
    )

    # Find header row (look for "District" or "AEA" in first column)
    header_row <- which(grepl("AEA|District|County", df_raw[[1]], ignore.case = TRUE) &
                        !grepl("Source|Note|Enrollment", df_raw[[1]], ignore.case = TRUE))[1]

    if (is.na(header_row)) {
      # Fallback: assume header is in row 5 (common pattern)
      header_row <- 5
    }

    # Re-read with proper header
    df <- readxl::read_excel(
      temp_file,
      skip = header_row - 1,
      col_types = "text"
    )

    # Standardize column names (uppercase, no spaces)
    names(df) <- toupper(gsub("[^A-Za-z0-9_]", "_", names(df)))
    names(df) <- gsub("_+", "_", names(df))
    names(df) <- gsub("_$", "", names(df))
    names(df) <- gsub("^_", "", names(df))

    # Remove any rows that are all NA or empty
    df <- df[rowSums(!is.na(df) & df != "") > 0, ]

    # Add metadata
    df$end_year <- end_year
    df$level <- level

    df

  }, error = function(e) {
    warning(paste("Failed to download", level, "data for", end_year, "-", e$message))
    return(data.frame())
  })
}


#' Download and read historical Iowa DOE Excel file
#'
#' Downloads a historical Excel file from Iowa DOE and extracts data for the
#' specified year. Historical files contain multiple years of data.
#'
#' @param end_year School year end (1947-1991)
#' @return Data frame with enrollment data for the specified year
#' @keywords internal
download_historical_excel <- function(end_year) {

  file_info <- get_historical_file_info(end_year)
  url <- build_download_url(file_info$media_id)

  temp_file <- tempfile(fileext = ".xlsx")

  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_file, overwrite = TRUE),
      httr::timeout(300)
    )

    if (httr::http_error(response)) {
      warning(paste("Failed to download historical data for", end_year,
                    "- HTTP error:", httr::status_code(response)))
      return(data.frame())
    }

    # Check file size
    file_info_fs <- file.info(temp_file)
    if (file_info_fs$size < 1000) {
      warning(paste("Downloaded file appears too small for historical data"))
      return(data.frame())
    }

    # Read Excel file with proper skip rows
    df <- readxl::read_excel(
      temp_file,
      skip = file_info$skip_rows,
      col_types = "text"
    )

    # Build the school year string to filter on
    # Format varies: "1946-47", "1950-1951", "1972-1973"
    year_str_short <- paste0(end_year - 1, "-", substr(as.character(end_year), 3, 4))
    year_str_long <- paste0(end_year - 1, "-", end_year)

    # Filter to just the requested year
    year_col <- file_info$year_col
    df <- df[df[[year_col]] %in% c(year_str_short, year_str_long), ]

    if (nrow(df) == 0) {
      warning(paste("No data found for year", end_year,
                    "- looking for", year_str_short, "or", year_str_long))
      return(data.frame())
    }

    # Standardize column names (uppercase, no spaces)
    names(df) <- toupper(gsub("[^A-Za-z0-9_]", "_", names(df)))
    names(df) <- gsub("_+", "_", names(df))
    names(df) <- gsub("_$", "", names(df))
    names(df) <- gsub("^_", "", names(df))

    # Remove any rows that are all NA or empty
    df <- df[rowSums(!is.na(df) & df != "") > 0, ]

    # Add metadata
    df$end_year <- end_year
    df$level <- "district"
    df$is_historical <- TRUE

    df

  }, error = function(e) {
    warning(paste("Failed to download historical data for", end_year, "-", e$message))
    return(data.frame())
  })
}


#' Get path for raw file cache
#'
#' @param end_year School year end
#' @param level Data level
#' @return Path to raw cache file
#' @keywords internal
get_raw_cache_path <- function(end_year, level) {
  cache_dir <- file.path(
    rappdirs::user_cache_dir("iaschooldata"),
    "raw"
  )
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  file.path(cache_dir, paste0(level, "_", end_year, ".xlsx"))
}
