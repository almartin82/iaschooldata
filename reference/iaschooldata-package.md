# iaschooldata: Fetch and Process Iowa School Data

Downloads and processes school data from the Iowa Department of
Education. Provides functions for fetching enrollment data and
transforming it into tidy format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/iaschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/iaschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/iaschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/iaschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/iaschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

- [`get_available_years`](https://almartin82.github.io/iaschooldata/reference/get_available_years.md):

  Get available data years

## Cache functions

- [`cache_status`](https://almartin82.github.io/iaschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/iaschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Iowa uses district numbers as primary identifiers:

- District IDs: 4-digit codes (e.g., 0000 = state, 0009 = Adair-Casey)

- School IDs: Building-level identifiers within districts

## Data Sources

Data is sourced from the Iowa Department of Education:

- Education Statistics:
  <https://educate.iowa.gov/pk-12/data/education-statistics>

- Certified Enrollment:
  <https://educate.iowa.gov/pk-12/data/data-collections/certified-enrollment/public-schools>

## Data Availability

- Years: 1992-2025 (34 years of historical data)

- Aggregation levels: State, District, School

- Demographics: Race/ethnicity, gender

- Grade levels: PK, K, 1-12

## See also

Useful links:

- <https://almartin82.github.io/iaschooldata>

- <https://github.com/almartin82/iaschooldata>

- Report bugs at <https://github.com/almartin82/iaschooldata/issues>

## Author

**Maintainer**: Andrew Martin <almartin@gmail.com>
