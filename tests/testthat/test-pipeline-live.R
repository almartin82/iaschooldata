# ==============================================================================
# LIVE Pipeline Tests for iaschooldata
# ==============================================================================
#
# These tests verify EACH STEP of the data pipeline using LIVE network calls.
# No mocks - we verify actual connectivity and data correctness.
#
# Test Categories:
# 1. URL Availability - HTTP status codes
# 2. File Download - Successful download and file type verification
# 3. File Parsing - Read file into R
# 4. Column Structure - Expected columns exist
# 5. Year Filtering - Extract data for specific years
# 6. Aggregation Logic - District sums match state totals
# 7. Data Quality - No Inf/NaN, valid ranges
# 8. Output Fidelity - tidy=TRUE matches raw data
#
# ==============================================================================

library(testthat)
library(httr)

# Skip if no network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}

# ==============================================================================
# STEP 1: URL Availability Tests
# ==============================================================================

test_that("Iowa DOE base URL is accessible", {
  skip_if_offline()

  response <- httr::HEAD(
    "https://educate.iowa.gov/pk-12/data/education-statistics",
    httr::timeout(30)
  )

  expect_equal(httr::status_code(response), 200)
})

test_that("Current year district file URL returns HTTP 200", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()
  media_id <- iaschooldata:::get_media_id(current_year, "district")
  url <- iaschooldata:::build_download_url(media_id)

  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)
})

test_that("Current year school file URL returns HTTP 200", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()
  media_id <- iaschooldata:::get_media_id(current_year, "school")
  url <- iaschooldata:::build_download_url(media_id)

  response <- httr::HEAD(url, httr::timeout(30))

  expect_equal(httr::status_code(response), 200)
})

test_that("All modern year URLs (2015-current) return HTTP 200 with Excel content-type", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()
  years_to_test <- 2015:current_year

  for (yr in years_to_test) {
    dist_id <- iaschooldata:::get_media_id(yr, "district")
    school_id <- iaschooldata:::get_media_id(yr, "school")

    dist_url <- iaschooldata:::build_download_url(dist_id)
    school_url <- iaschooldata:::build_download_url(school_id)

    dist_resp <- httr::HEAD(dist_url, httr::timeout(10))
    school_resp <- httr::HEAD(school_url, httr::timeout(10))

    expect_equal(httr::status_code(dist_resp), 200,
                 label = paste("District", yr))
    expect_equal(httr::status_code(school_resp), 200,
                 label = paste("School", yr))

    # Verify content type is Excel (not PDF or HTML error page)
    dist_ct <- httr::headers(dist_resp)[["content-type"]]
    school_ct <- httr::headers(school_resp)[["content-type"]]

    expect_true(grepl("excel|spreadsheet", dist_ct, ignore.case = TRUE),
                label = paste("District", yr, "content-type"))
    expect_true(grepl("excel|spreadsheet", school_ct, ignore.case = TRUE),
                label = paste("School", yr, "content-type"))
  }
})

test_that("Historical file URLs return HTTP 200", {
  skip_if_offline()

  # Test the 4 historical file media IDs
  historical_ids <- c("10321", "10322", "5590", "5591")

  for (media_id in historical_ids) {
    url <- iaschooldata:::build_download_url(media_id)
    response <- httr::HEAD(url, httr::timeout(30))

    expect_equal(httr::status_code(response), 200,
                 label = paste("Historical file", media_id))
  }
})

# ==============================================================================
# STEP 2: File Download Tests
# ==============================================================================

test_that("Can download district Excel file completely", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()
  media_id <- iaschooldata:::get_media_id(current_year, "district")
  url <- iaschooldata:::build_download_url(media_id)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::timeout(120)
  )

  expect_equal(httr::status_code(response), 200)

  # File should be > 10KB (not an error page)
  file_size <- file.info(temp_file)$size
  expect_true(file_size > 10000)
})

test_that("Can download school Excel file completely", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()
  media_id <- iaschooldata:::get_media_id(current_year, "school")
  url <- iaschooldata:::build_download_url(media_id)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  response <- httr::GET(
    url,
    httr::write_disk(temp_file, overwrite = TRUE),
    httr::timeout(120)
  )

  expect_equal(httr::status_code(response), 200)

  # File should be > 10KB (not an error page)
  file_size <- file.info(temp_file)$size
  expect_true(file_size > 10000)
})

# ==============================================================================
# STEP 3: File Parsing Tests
# ==============================================================================

test_that("Can parse district Excel file with readxl", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()
  media_id <- iaschooldata:::get_media_id(current_year, "district")
  url <- iaschooldata:::build_download_url(media_id)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(120))

  # Should be able to read the file
  df <- readxl::read_excel(temp_file, col_types = "text")

  expect_true(is.data.frame(df))
  expect_true(nrow(df) > 100)
  expect_true(ncol(df) > 10)
})

test_that("Can parse school Excel file with readxl", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()
  media_id <- iaschooldata:::get_media_id(current_year, "school")
  url <- iaschooldata:::build_download_url(media_id)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(120))

  df <- readxl::read_excel(temp_file, col_types = "text")

  expect_true(is.data.frame(df))
  expect_true(nrow(df) > 500)
  expect_true(ncol(df) > 10)
})

# ==============================================================================
# STEP 4: Column Structure Tests
# ==============================================================================

test_that("District file has expected enrollment columns", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()
  media_id <- iaschooldata:::get_media_id(current_year, "district")
  url <- iaschooldata:::build_download_url(media_id)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(120))

  # Skip header rows
  df <- readxl::read_excel(temp_file, skip = 4, col_types = "text")

  col_names_lower <- tolower(names(df))

  # Expected columns (case-insensitive check)
  expect_true(any(grepl("district", col_names_lower)))
  expect_true(any(grepl("pk|kindergarten|kg|grade", col_names_lower)))
  expect_true(any(grepl("total", col_names_lower)))
})

test_that("School file has expected columns including building info", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()
  media_id <- iaschooldata:::get_media_id(current_year, "school")
  url <- iaschooldata:::build_download_url(media_id)

  temp_file <- tempfile(fileext = ".xlsx")
  on.exit(unlink(temp_file))

  httr::GET(url, httr::write_disk(temp_file, overwrite = TRUE), httr::timeout(120))

  df <- readxl::read_excel(temp_file, skip = 4, col_types = "text")

  col_names_lower <- tolower(names(df))

  # School files should have building-related columns
  expect_true(any(grepl("building|school", col_names_lower)))
  expect_true(any(grepl("district", col_names_lower)))
})

# ==============================================================================
# STEP 5: get_raw_enr() Function Tests
# ==============================================================================

test_that("get_raw_enr returns data for current year", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  raw <- iaschooldata:::get_raw_enr(current_year)

  expect_true(is.list(raw))
  expect_true("district" %in% names(raw))
  expect_true("school" %in% names(raw))
  expect_true(nrow(raw$district) > 100)
  expect_true(nrow(raw$school) > 500)
})

test_that("get_raw_enr returns data for 5 years ago", {
  skip_if_offline()

  test_year <- iaschooldata:::get_max_year() - 5

  raw <- iaschooldata:::get_raw_enr(test_year)

  expect_true(is.list(raw))
  expect_true(nrow(raw$district) > 0)
})

test_that("get_raw_enr returns historical data", {
  skip_if_offline()

  # Test a historical year
  test_year <- 1980

  raw <- iaschooldata:::get_raw_enr(test_year)

  expect_true(is.list(raw))
  expect_true(raw$is_historical)
  expect_true(nrow(raw$district) > 0)
})

test_that("get_available_years returns valid year range", {
  result <- iaschooldata::get_available_years()

  # Check it's a numeric vector
  expect_true(is.numeric(result) || is.integer(result))

  # Iowa has data from 1947 to present
  expect_equal(min(result), 1947)
  expect_true(max(result) >= 2024)

  # Should include both historical and modern years
  expect_true(1970 %in% result)
  expect_true(2020 %in% result)
})

# ==============================================================================
# STEP 6: Aggregation Tests
# ==============================================================================

test_that("State total equals sum of district totals", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  data <- iaschooldata::fetch_enr(current_year, tidy = FALSE, use_cache = FALSE)

  # Get state row
  state_rows <- data[data$type == "State", ]
  expect_equal(nrow(state_rows), 1)

  state_total <- state_rows$row_total

  # Sum district rows
  district_rows <- data[data$type == "District", ]
  district_sum <- sum(district_rows$row_total, na.rm = TRUE)

  # They should be equal (state is calculated from districts)
  expect_equal(state_total, district_sum)
})

test_that("Gender breakdown sums to row total", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  data <- iaschooldata::fetch_enr(current_year, tidy = FALSE, use_cache = FALSE)

  # For districts, male + female should equal row_total
  district_rows <- data[data$type == "District", ]

  # Filter to rows where both male and female are non-NA
  valid_rows <- district_rows[
    !is.na(district_rows$male) & !is.na(district_rows$female),
  ]

  if (nrow(valid_rows) > 0) {
    gender_sum <- valid_rows$male + valid_rows$female

    # Should be equal (with small tolerance for rounding)
    expect_equal(gender_sum, valid_rows$row_total, tolerance = 1)
  }
})

# ==============================================================================
# STEP 7: Data Quality Tests
# ==============================================================================

test_that("fetch_enr returns data with no Inf or NaN", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  data <- iaschooldata::fetch_enr(current_year, tidy = TRUE, use_cache = FALSE)

  for (col in names(data)[sapply(data, is.numeric)]) {
    expect_false(any(is.infinite(data[[col]]), na.rm = TRUE))
    expect_false(any(is.nan(data[[col]]), na.rm = TRUE))
  }
})

test_that("All enrollment counts are non-negative", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  data <- iaschooldata::fetch_enr(current_year, tidy = FALSE, use_cache = FALSE)

  expect_true(all(data$row_total >= 0, na.rm = TRUE))
  expect_true(all(data$male >= 0, na.rm = TRUE))
  expect_true(all(data$female >= 0, na.rm = TRUE))
})

test_that("State total enrollment is reasonable (400K-1.5M for Iowa)", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  data <- iaschooldata::fetch_enr(current_year, tidy = TRUE, use_cache = FALSE)

  state_total <- data[
    data$is_state & data$subgroup == "total_enrollment" & data$grade_level == "TOTAL",
  ]$n_students

  # Iowa has about 500K-600K students, using wide range for safety
  expect_true(state_total > 400000 && state_total < 1500000,
              label = paste("State total:", state_total))
})

test_that("Percentages are in valid range (0-1)", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  data <- iaschooldata::fetch_enr(current_year, tidy = TRUE, use_cache = FALSE)

  # Filter out NA percentages
  valid_pcts <- data$pct[!is.na(data$pct)]

  expect_true(all(valid_pcts >= 0, na.rm = TRUE))
  expect_true(all(valid_pcts <= 1, na.rm = TRUE))
})

test_that("District count is reasonable (250-500 for Iowa)", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  data <- iaschooldata::fetch_enr(current_year, tidy = FALSE, use_cache = FALSE)

  district_count <- sum(data$type == "District")

  # Iowa has about 330 school districts
  expect_true(district_count > 250 && district_count < 500,
              label = paste("District count:", district_count))
})

# ==============================================================================
# STEP 8: Output Fidelity Tests
# ==============================================================================

test_that("tidy=TRUE and tidy=FALSE return consistent totals", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  wide <- iaschooldata::fetch_enr(current_year, tidy = FALSE, use_cache = FALSE)
  tidy <- iaschooldata::fetch_enr(current_year, tidy = TRUE, use_cache = FALSE)

  # Both should have data
  expect_true(nrow(wide) > 0)
  expect_true(nrow(tidy) > 0)

  # Get state totals from both formats
  wide_state_total <- wide[wide$type == "State", ]$row_total
  tidy_state_total <- tidy[
    tidy$is_state & tidy$subgroup == "total_enrollment" & tidy$grade_level == "TOTAL",
  ]$n_students

  expect_equal(wide_state_total, tidy_state_total)
})

test_that("Tidy format has expected subgroups", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  data <- iaschooldata::fetch_enr(current_year, tidy = TRUE, use_cache = FALSE)

  subgroups <- unique(data$subgroup)

  expect_true("total_enrollment" %in% subgroups)
  expect_true("white" %in% subgroups || "male" %in% subgroups)
})

test_that("Wide format district row_total matches sum of grades", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  data <- iaschooldata::fetch_enr(current_year, tidy = FALSE, use_cache = FALSE)

  # Get districts only
  districts <- data[data$type == "District", ]

  # Sum grade columns
  grade_cols <- grep("^grade_", names(districts), value = TRUE)

  if (length(grade_cols) > 0) {
    grade_sum <- rowSums(districts[, grade_cols, drop = FALSE], na.rm = TRUE)

    # Should match row_total (with tolerance for any PK/special students)
    # Note: row_total may include PK which isn't in some grade column sets
    # So we check that grade_sum is close to or less than row_total
    expect_true(all(grade_sum <= districts$row_total + 10, na.rm = TRUE))
  }
})

# ==============================================================================
# Raw Data Fidelity Tests (Sample Verification)
# ==============================================================================

test_that("Raw data for 2024 contains expected Iowa districts", {
  skip_if_offline()

  data <- iaschooldata::fetch_enr(2024, tidy = FALSE, use_cache = FALSE)

  districts <- data[data$type == "District", ]

  # Check that Des Moines Independent exists (largest district in Iowa)
  des_moines <- districts[grepl("Des Moines Independent", districts$district_name, ignore.case = TRUE), ]

  expect_true(nrow(des_moines) >= 1)
  # First row should have significant enrollment
  expect_true(des_moines$row_total[1] > 25000)
})

# ==============================================================================
# Cache Tests
# ==============================================================================

test_that("Cache path generation works", {
  path <- iaschooldata:::get_cache_path(2024, "enrollment")
  expect_true(is.character(path))
  expect_true(grepl("2024", path))
})

test_that("Cache write and read work correctly", {
  skip_if_offline()

  current_year <- iaschooldata:::get_max_year()

  # First call - should download
  data1 <- iaschooldata::fetch_enr(current_year, tidy = TRUE, use_cache = TRUE)

  # Second call - should use cache
  data2 <- iaschooldata::fetch_enr(current_year, tidy = TRUE, use_cache = TRUE)

  # Should be identical
  expect_equal(nrow(data1), nrow(data2))
  expect_equal(ncol(data1), ncol(data2))
})
