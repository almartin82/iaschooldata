#' iaschooldata: Fetch and Process Iowa School Data
#'
#' Downloads and processes school data from the Iowa Department of Education.
#' Provides functions for fetching enrollment data and transforming it into
#' tidy format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#'   \item{\code{\link{get_available_years}}}{Get available data years}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Iowa uses district numbers as primary identifiers:
#' \itemize{
#'   \item District IDs: 4-digit codes (e.g., 0000 = state, 0009 = Adair-Casey)
#'   \item School IDs: Building-level identifiers within districts
#' }
#'
#' @section Data Sources:
#' Data is sourced from the Iowa Department of Education:
#' \itemize{
#'   \item Education Statistics: \url{https://educate.iowa.gov/pk-12/data/education-statistics}
#'   \item Certified Enrollment: \url{https://educate.iowa.gov/pk-12/data/data-collections/certified-enrollment/public-schools}
#' }
#'
#' @section Data Availability:
#' \itemize{
#'   \item Years: 1992-2025 (34 years of historical data)
#'   \item Aggregation levels: State, District, School
#'   \item Demographics: Race/ethnicity, gender
#'   \item Grade levels: PK, K, 1-12
#' }
#'
#' @docType package
#' @name iaschooldata-package
#' @aliases iaschooldata
#' @keywords internal
"_PACKAGE"
