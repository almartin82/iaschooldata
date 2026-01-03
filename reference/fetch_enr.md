# Fetch Iowa enrollment data

Downloads and processes enrollment data from the Iowa Department of
Education's Education Statistics page.

## Usage

``` r
fetch_enr(end_year, tidy = TRUE, use_cache = TRUE)
```

## Arguments

- end_year:

  A school year. Year is the end of the academic year - eg 2023-24
  school year is year '2024'. Valid values are 1947-2025, though some
  years are missing (1948, 1950, 1952, 1954, 1971, 1972).

  Note: Historical data (1947-1991) contains only grade-level
  enrollment. Modern data (1992+) includes demographics and gender
  breakdowns.

- tidy:

  If TRUE (default), returns data in long (tidy) format with subgroup
  column. If FALSE, returns wide format.

- use_cache:

  If TRUE (default), uses locally cached data when available. Set to
  FALSE to force re-download from Iowa DOE.

## Value

Data frame with enrollment data. Wide format includes columns for
district_id, school_id, names, and enrollment counts by
demographic/grade. Tidy format pivots these counts into subgroup and
grade_level columns.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 enrollment data (2023-24 school year)
enr_2024 <- fetch_enr(2024)

# Get historical data (1969-70 school year)
enr_1970 <- fetch_enr(1970)

# Get wide format
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Force fresh download (ignore cache)
enr_fresh <- fetch_enr(2024, use_cache = FALSE)

# Filter to specific district
des_moines <- enr_2024 |>
  dplyr::filter(district_id == "1350")
} # }
```
