# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw Iowa DOE enrollment data into
# a clean, standardized format.
#
# Iowa Data Structure:
# - District ID: 4 digits (e.g., 0009 = Adair-Casey)
# - School ID: Building identifier within district
# - Data is reported as of October 1st (certified enrollment date)
#
# Column naming conventions in Iowa files:
# - Grade levels: PK, K, 1 through 12
# - Demographics: WHITE, BLACK/AFRICAN AMERICAN, HISPANIC, ASIAN, etc.
# - Gender: MALE, FEMALE
#
# ==============================================================================


#' Process raw Iowa enrollment data
#'
#' Transforms raw Iowa DOE data into a standardized schema combining district
#' and school data.
#'
#' @param raw_data List containing district and school data frames from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Process district data
  district_processed <- process_district_enr(raw_data$district, end_year)

  # Process school data
  school_processed <- process_school_enr(raw_data$school, end_year)

  # Create state aggregate
  state_processed <- create_state_aggregate(district_processed, end_year)

  # Combine all levels
  result <- dplyr::bind_rows(state_processed, district_processed, school_processed)

  result
}


#' Process district-level enrollment data
#'
#' @param df Raw district data frame
#' @param end_year School year end
#' @return Processed district data frame
#' @keywords internal
process_district_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    stringsAsFactors = FALSE
  )

  # District ID (Iowa uses "District Code" or "DISTRICT_CODE")
  dist_id_col <- find_col(c("^DISTRICT_CODE$", "^DISTRICT_NUMBER$", "^DISTRICT_ID$", "^DIST_NO$", "^DIST$"))
  if (!is.null(dist_id_col)) {
    result$district_id <- standardize_district_id(df[[dist_id_col]])
  } else {
    result$district_id <- NA_character_
  }

  # School ID is NA for district rows
  result$school_id <- rep(NA_character_, n_rows)

  # District name
  dist_name_col <- find_col(c("^DISTRICT_NAME$", "^DISTRICT$", "^DIST_NAME$"))
  if (!is.null(dist_name_col)) {
    result$district_name <- clean_district_name(df[[dist_name_col]])
  } else {
    result$district_name <- NA_character_
  }

  result$school_name <- rep(NA_character_, n_rows)

  # Total enrollment (Iowa uses "Total PK12", "Total K12", or "TOTAL_PK12")
  total_col <- find_col(c("^TOTAL_PK12$", "^TOTAL_K12$", "^TOTAL$", "^TOTAL_ENROLLMENT$", "^ENROLLMENT$"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  } else {
    # Try to calculate from grades
    result$row_total <- NA_integer_
  }

  # Demographics - ethnicity/race
  # Iowa column names (after standardization): WHITE_TOTAL, BLACK_OR_AFRICAN_AMERICAN_TOTAL, etc.
  demo_map <- list(
    white = c("^WHITE_TOTAL$", "^WHITE$", "^WHITE_ENROLLMENT$"),
    black = c("^BLACK_OR_AFRICAN_AMERICAN_TOTAL$", "^BLACK$", "^BLACK_AFRICAN_AMERICAN$", "^AFRICAN_AMERICAN$"),
    hispanic = c("^HISPANIC_LATINO_TOTAL$", "^HISPANIC$", "^HISPANIC_LATINO$", "^LATINO$"),
    asian = c("^ASIAN_TOTAL$", "^ASIAN$", "^ASIAN_ENROLLMENT$"),
    native_american = c("^AMERICAN_INDIAN_OR_ALASKA_NATIVE_TOTAL$", "^NATIVE_AMERICAN$", "^AMERICAN_INDIAN$", "^AMER_INDIAN$", "^AMERICAN_INDIAN_ALASKA_NATIVE$"),
    pacific_islander = c("^NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER_TOTAL$", "^PACIFIC_ISLANDER$", "^NATIVE_HAWAIIAN$", "^HAWAIIAN$", "^NATIVE_HAWAIIAN_PACIFIC_ISLANDER$"),
    multiracial = c("^TWO_OR_MORE_RACES_TOTAL$", "^MULTIRACIAL$", "^TWO_OR_MORE$", "^MULTI_RACIAL$", "^TWO_OR_MORE_RACES$")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  # Gender (Iowa uses "Total Male", "Total Female" -> TOTAL_MALE, TOTAL_FEMALE after standardization)
  male_col <- find_col(c("^TOTAL_MALE$", "^MALE$", "^MALE_ENROLLMENT$", "^MALES$"))
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  } else {
    result$male <- NA_integer_
  }

  female_col <- find_col(c("^TOTAL_FEMALE$", "^FEMALE$", "^FEMALE_ENROLLMENT$", "^FEMALES$"))
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  } else {
    result$female <- NA_integer_
  }

  # Grade levels (Iowa uses "PK", "KG", "Grade 1" etc. -> PK, KG, GRADE_1 after standardization)
  grade_map <- list(
    grade_pk = c("^PK$", "^PRE_K$", "^PREK$", "^PREKINDERGARTEN$"),
    grade_k = c("^KG$", "^K$", "^KINDERGARTEN$"),
    grade_01 = c("^GRADE_1$", "^1$", "^GR_1$", "^GR1$", "^G1$"),
    grade_02 = c("^GRADE_2$", "^2$", "^GR_2$", "^GR2$", "^G2$"),
    grade_03 = c("^GRADE_3$", "^3$", "^GR_3$", "^GR3$", "^G3$"),
    grade_04 = c("^GRADE_4$", "^4$", "^GR_4$", "^GR4$", "^G4$"),
    grade_05 = c("^GRADE_5$", "^5$", "^GR_5$", "^GR5$", "^G5$"),
    grade_06 = c("^GRADE_6$", "^6$", "^GR_6$", "^GR6$", "^G6$"),
    grade_07 = c("^GRADE_7$", "^7$", "^GR_7$", "^GR7$", "^G7$"),
    grade_08 = c("^GRADE_8$", "^8$", "^GR_8$", "^GR8$", "^G8$"),
    grade_09 = c("^GRADE_9$", "^9$", "^GR_9$", "^GR9$", "^G9$"),
    grade_10 = c("^GRADE_10$", "^10$", "^GR_10$", "^GR10$", "^G10$"),
    grade_11 = c("^GRADE_11$", "^11$", "^GR_11$", "^GR11$", "^G11$"),
    grade_12 = c("^GRADE_12$", "^12$", "^GR_12$", "^GR12$", "^G12$")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  # Calculate row_total from grades if not found
  if (all(is.na(result$row_total))) {
    grade_cols <- grep("^grade_", names(result), value = TRUE)
    if (length(grade_cols) > 0) {
      result$row_total <- rowSums(result[, grade_cols, drop = FALSE], na.rm = TRUE)
      result$row_total[result$row_total == 0] <- NA_integer_
    }
  }

  result
}


#' Process school-level enrollment data
#'
#' @param df Raw school data frame
#' @param end_year School year end
#' @return Processed school data frame
#' @keywords internal
process_school_enr <- function(df, end_year) {

  if (is.null(df) || nrow(df) == 0) {
    return(data.frame())
  }

  cols <- names(df)
  n_rows <- nrow(df)

  # Helper to find column by pattern (case-insensitive)
  find_col <- function(patterns) {
    for (pattern in patterns) {
      matched <- grep(pattern, cols, value = TRUE, ignore.case = TRUE)
      if (length(matched) > 0) return(matched[1])
    }
    NULL
  }

  # Build result dataframe
  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("School", n_rows),
    stringsAsFactors = FALSE
  )

  # District ID (Iowa uses "District Code" or "DISTRICT_CODE")
  dist_id_col <- find_col(c("^DISTRICT_CODE$", "^DISTRICT_NUMBER$", "^DISTRICT_ID$", "^DIST_NO$", "^DIST$"))
  if (!is.null(dist_id_col)) {
    result$district_id <- standardize_district_id(df[[dist_id_col]])
  } else {
    result$district_id <- NA_character_
  }

  # School ID (Iowa uses "Building Code" or similar)
  school_id_col <- find_col(c("^BUILDING_CODE$", "^SCHOOL_CODE$", "^SCHOOL_ID$", "^BUILDING_ID$", "^BLDG_ID$", "^SCHOOL_NUMBER$"))
  if (!is.null(school_id_col)) {
    result$school_id <- standardize_school_id(df[[school_id_col]])
  } else {
    result$school_id <- NA_character_
  }

  # District name
  dist_name_col <- find_col(c("^DISTRICT_NAME$", "^DISTRICT$", "^DIST_NAME$"))
  if (!is.null(dist_name_col)) {
    result$district_name <- clean_district_name(df[[dist_name_col]])
  } else {
    result$district_name <- NA_character_
  }

  # School name (Iowa uses "Building Name")
  school_name_col <- find_col(c("^BUILDING_NAME$", "^SCHOOL_NAME$", "^SCHOOL$", "^BLDG_NAME$"))
  if (!is.null(school_name_col)) {
    result$school_name <- clean_school_name(df[[school_name_col]])
  } else {
    result$school_name <- NA_character_
  }

  # Total enrollment (Iowa uses "Total PK12", "Total K12", or "TOTAL_PK12")
  total_col <- find_col(c("^TOTAL_PK12$", "^TOTAL_K12$", "^TOTAL$", "^TOTAL_ENROLLMENT$", "^ENROLLMENT$"))
  if (!is.null(total_col)) {
    result$row_total <- safe_numeric(df[[total_col]])
  } else {
    result$row_total <- NA_integer_
  }

  # Demographics - ethnicity/race
  # Iowa column names (after standardization): WHITE_TOTAL, BLACK_OR_AFRICAN_AMERICAN_TOTAL, etc.
  demo_map <- list(
    white = c("^WHITE_TOTAL$", "^WHITE$", "^WHITE_ENROLLMENT$"),
    black = c("^BLACK_OR_AFRICAN_AMERICAN_TOTAL$", "^BLACK$", "^BLACK_AFRICAN_AMERICAN$", "^AFRICAN_AMERICAN$"),
    hispanic = c("^HISPANIC_LATINO_TOTAL$", "^HISPANIC$", "^HISPANIC_LATINO$", "^LATINO$"),
    asian = c("^ASIAN_TOTAL$", "^ASIAN$", "^ASIAN_ENROLLMENT$"),
    native_american = c("^AMERICAN_INDIAN_OR_ALASKA_NATIVE_TOTAL$", "^NATIVE_AMERICAN$", "^AMERICAN_INDIAN$", "^AMER_INDIAN$", "^AMERICAN_INDIAN_ALASKA_NATIVE$"),
    pacific_islander = c("^NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER_TOTAL$", "^PACIFIC_ISLANDER$", "^NATIVE_HAWAIIAN$", "^HAWAIIAN$", "^NATIVE_HAWAIIAN_PACIFIC_ISLANDER$"),
    multiracial = c("^TWO_OR_MORE_RACES_TOTAL$", "^MULTIRACIAL$", "^TWO_OR_MORE$", "^MULTI_RACIAL$", "^TWO_OR_MORE_RACES$")
  )

  for (name in names(demo_map)) {
    col <- find_col(demo_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  # Gender (Iowa uses "Total Male", "Total Female" -> TOTAL_MALE, TOTAL_FEMALE after standardization)
  male_col <- find_col(c("^TOTAL_MALE$", "^MALE$", "^MALE_ENROLLMENT$", "^MALES$"))
  if (!is.null(male_col)) {
    result$male <- safe_numeric(df[[male_col]])
  } else {
    result$male <- NA_integer_
  }

  female_col <- find_col(c("^TOTAL_FEMALE$", "^FEMALE$", "^FEMALE_ENROLLMENT$", "^FEMALES$"))
  if (!is.null(female_col)) {
    result$female <- safe_numeric(df[[female_col]])
  } else {
    result$female <- NA_integer_
  }

  # Grade levels (Iowa uses "PK", "KG", "Grade 1" etc. -> PK, KG, GRADE_1 after standardization)
  grade_map <- list(
    grade_pk = c("^PK$", "^PRE_K$", "^PREK$", "^PREKINDERGARTEN$"),
    grade_k = c("^KG$", "^K$", "^KINDERGARTEN$"),
    grade_01 = c("^GRADE_1$", "^1$", "^GR_1$", "^GR1$", "^G1$"),
    grade_02 = c("^GRADE_2$", "^2$", "^GR_2$", "^GR2$", "^G2$"),
    grade_03 = c("^GRADE_3$", "^3$", "^GR_3$", "^GR3$", "^G3$"),
    grade_04 = c("^GRADE_4$", "^4$", "^GR_4$", "^GR4$", "^G4$"),
    grade_05 = c("^GRADE_5$", "^5$", "^GR_5$", "^GR5$", "^G5$"),
    grade_06 = c("^GRADE_6$", "^6$", "^GR_6$", "^GR6$", "^G6$"),
    grade_07 = c("^GRADE_7$", "^7$", "^GR_7$", "^GR7$", "^G7$"),
    grade_08 = c("^GRADE_8$", "^8$", "^GR_8$", "^GR8$", "^G8$"),
    grade_09 = c("^GRADE_9$", "^9$", "^GR_9$", "^GR9$", "^G9$"),
    grade_10 = c("^GRADE_10$", "^10$", "^GR_10$", "^GR10$", "^G10$"),
    grade_11 = c("^GRADE_11$", "^11$", "^GR_11$", "^GR11$", "^G11$"),
    grade_12 = c("^GRADE_12$", "^12$", "^GR_12$", "^GR12$", "^G12$")
  )

  for (name in names(grade_map)) {
    col <- find_col(grade_map[[name]])
    if (!is.null(col)) {
      result[[name]] <- safe_numeric(df[[col]])
    } else {
      result[[name]] <- NA_integer_
    }
  }

  # Calculate row_total from grades if not found
  if (all(is.na(result$row_total))) {
    grade_cols <- grep("^grade_", names(result), value = TRUE)
    if (length(grade_cols) > 0) {
      result$row_total <- rowSums(result[, grade_cols, drop = FALSE], na.rm = TRUE)
      result$row_total[result$row_total == 0] <- NA_integer_
    }
  }

  result
}


#' Create state-level aggregate from district data
#'
#' @param district_df Processed district data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(district_df, end_year) {

  if (is.null(district_df) || nrow(district_df) == 0) {
    # Return minimal state row
    return(data.frame(
      end_year = end_year,
      type = "State",
      district_id = NA_character_,
      school_id = NA_character_,
      district_name = "Iowa",
      school_name = NA_character_,
      stringsAsFactors = FALSE
    ))
  }

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(district_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    school_id = NA_character_,
    district_name = "Iowa",
    school_name = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    state_row[[col]] <- sum(district_df[[col]], na.rm = TRUE)
  }

  state_row
}
