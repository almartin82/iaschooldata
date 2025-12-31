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
# - District level: 1991-92 through 2024-25
# - School (building) level: 1991-92 through 2024-25
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
    "2023" = "6009",
    "2022" = "7648",
    "2021" = "9175",
    "2020" = "9176",
    "2019" = "9177",
    "2018" = "9178",
    "2017" = "3391",
    "2016" = "2971",
    "2015" = "2622",
    "2014" = "2243",
    "2013" = "1990",
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
    "1996" = "1358",
    "1995" = "1359",
    "1994" = "1360",
    "1993" = "9136",
    "1992" = "9137"
  )

  # Media IDs for "Iowa Public School PreK-12 Enrollment by Building"
  school_ids <- c(
    "2025" = "10910",
    "2024" = "9344",
    "2023" = "6010",
    "2022" = "7649",
    "2021" = "9179",
    "2020" = "9180",
    "2019" = "9181",
    "2018" = "9182",
    "2017" = "3392",
    "2016" = "2972",
    "2015" = "2623",
    "2014" = "2244",
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

  # Download district-level data
  message("  Downloading district data...")
  district_data <- download_iowa_excel(end_year, "district")

  # Download school-level data
  message("  Downloading school data...")
  school_data <- download_iowa_excel(end_year, "school")

  list(
    district = district_data,
    school = school_data
  )
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

  temp_file <- tempfile(fileext = ".xlsx")

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
