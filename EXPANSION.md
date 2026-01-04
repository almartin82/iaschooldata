# Iowa School Data Expansion Research

**Last Updated:** 2026-01-04 **Theme Researched:** Graduation Rates

## Data Sources Found

### Source 1: Four-Year Cohort Graduation Rates by District

- **URL Pattern:**
  `https://educate.iowa.gov/media/{media_id}/download?inline`
- **HTTP Status:** 200 (verified)
- **Format:** Excel (.xlsx)
- **Years Available:** 2019, 2020, 2021, 2022, 2023, 2024
- **Access:** Direct download, no authentication required
- **Update Frequency:** Annual (typically released in spring)

**Media IDs (District-level):** \| Class Year \| Media ID \| Status \|
\|————\|———-\|——–\| \| 2024 \| 11180 \| HTTP 200 \| \| 2023 \| 9887 \|
HTTP 200 \| \| 2022 \| 9888 \| HTTP 200 \| \| 2021 \| 9889 \| HTTP 200
\| \| 2020 \| 10323 \| HTTP 200 \| \| 2019 \| 10324 \| HTTP 200 \|

### Source 2: Four-Year Cohort Graduation Rates by School

- **URL Pattern:**
  `https://educate.iowa.gov/media/{media_id}/download?inline`
- **HTTP Status:** 200 (verified)
- **Format:** Excel (.xlsx)
- **Years Available:** 2019, 2020, 2021, 2022, 2023, 2024
- **Access:** Direct download

**Media IDs (School-level):** \| Class Year \| Media ID \| Status \|
\|————\|———-\|——–\| \| 2024 \| 11181 \| HTTP 200 \| \| 2023 \| 9890 \|
HTTP 200 \| \| 2022 \| 9891 \| HTTP 200 \| \| 2021 \| 9892 \| HTTP 200
\| \| 2020 \| 10325 \| HTTP 200 \| \| 2019 \| 10326 \| HTTP 200 \|

### Source 3: Combined Graduation & Dropout Rates

- **URL Pattern:**
  `https://educate.iowa.gov/media/{media_id}/download?inline`
- **HTTP Status:** 200 (verified)
- **Format:** Excel (.xlsx)
- **Years Available:** 2020, 2021, 2022, 2023, 2024
- **Access:** Direct download
- **Notes:** Includes 4-year grad rate, 5-year grad rate, and dropout
  rates

**Media IDs:** \| Class Year \| Media ID \| Content \|
\|————\|———-\|———\| \| 2024 \| 11182 \| Class 2024 4-yr, Class 2023
5-yr, 2023-24 Dropout \| \| 2023 \| 9893 \| Class 2023 4-yr, Class 2022
5-yr, 2022-23 Dropout \| \| 2022 \| 9894 \| Class 2022 4-yr, Class 2021
5-yr, 2021-22 Dropout \| \| 2021 \| 10327 \| Class 2021 4-yr, Class 2020
5-yr, 2020-21 Dropout \| \| 2020 \| 10328 \| Class 2020 4-yr, Class 2019
5-yr, 2019-20 Dropout \|

### Source 4: Dropout Rates by District (Historical)

- **URL Pattern:**
  `https://educate.iowa.gov/media/{media_id}/download?inline`
- **HTTP Status:** 200 (verified for 2023-24)
- **Format:** Excel (.xlsx)
- **Years Available:** 1991-92 through 2023-24 (33 years)
- **Access:** Direct download

**Sample Media IDs:** \| Year \| Media ID \| \|——\|———-\| \| 2023-24 \|
11184 \| \| 2022-23 \| 9896 \|

## Schema Analysis

### Column Structure (Multi-row Header)

Files have 3-4 header rows that need to be skipped: - Row 1: Title
(e.g., “Iowa Public School District Class of 2024…”) - Row 2: Notes (for
corrected data) or blank - Row 3: Subgroup names (Overall, IEP, FRL, EL,
race categories, gender) - Row 4: Column headers (County, AEA Code,
etc., Numerator, Denominator, Rate)

### Column Names by Year

**2024 (47 columns, skip=3):**

    County, AEA Code, AEA Name, District Code, District Name,
    [Overall: Numerator, Denominator, Rate],
    [Students with Disabilities (IEP): Numerator, Denominator, Rate],
    [Low Socio-Economic Status (FRL): Numerator, Denominator, Rate],
    [English Learners (EL): Numerator, Denominator, Rate],
    [American Indian or Alaska Native: Numerator, Denominator, Rate],
    [Asian: Numerator, Denominator, Rate],
    [Black or African American: Numerator, Denominator, Rate],
    [Hispanic/Latino: Numerator, Denominator, Rate],
    [Native Hawaiian or Other Pacific Islander: Numerator, Denominator, Rate],
    [Two or More Races: Numerator, Denominator, Rate],
    [White: Numerator, Denominator, Rate],
    [Female: Numerator, Denominator, Rate],
    [Male: Numerator, Denominator, Rate],
    [Non-Binary: Numerator, Denominator, Rate]  <-- NEW in 2024

**2019-2023 (44 columns, skip=4):** Same as 2024 but WITHOUT Non-Binary
category. Extra note row about data corrections.

**School-level files (49 columns for 2024):** Same subgroups but adds:
`School Code`, `School Name` after District Name.

### Schema Changes Noted

- **2024:** Added Non-Binary gender category (3 extra columns)
- **2019-2023:** Data corrected in spring 2024 (mobile student dropout
  issue)
- **Pre-2019:** Data removed pending evaluation per DOE note

### ID System

- **District Code:** 4-digit string (e.g., “0009”, “1737”, “9999”)
- **School Code:** Additional identifier for school-level data
- **AEA Code:** 2-digit Area Education Agency code
- **County:** 2-digit FIPS code
- **State Summary:** District Code “9999” contains state totals

### Known Data Issues

- `*` used for suppressed values (small N privacy protection)
- Data for classes 2019-2023 were corrected in spring 2024
- Data for class of 2018 and earlier removed pending evaluation
- Non-Binary data largely suppressed (small N) in most districts

## Time Series Heuristics

### State Totals

| Class Year | Cohort Size | Graduates | 4-Year Rate |
|------------|-------------|-----------|-------------|
| 2024       | 38,699      | 34,159    | 88.3%       |
| 2020       | 36,845      | 32,853    | 89.2%       |
| 2019       | 36,628      | 32,337    | 88.3%       |

**Note:** Totals above are from State Summary row (District Code 9999).
District-level sums are approximately double (includes both reporting
levels).

### Expected Ranges

- **State 4-year graduation rate:** 85% - 92%
- **State cohort size:** 35,000 - 40,000 students
- **District count:** 300-310 districts
- **Year-over-year change:** Should be \< 3% for state rate

### Major Entities (verify exist in all years)

| District Code | District Name | 2024 Cohort |
|---------------|---------------|-------------|
| 9999          | State Summary | 38,699      |
| 1737          | Des Moines    | 2,369       |
| 1053          | Cedar Rapids  | 1,166       |
| 3141          | Iowa City     | 1,157       |
| 1611          | Davenport     | 1,124       |

## Recommended Implementation

### Priority: HIGH

- Graduation rates are a key accountability metric
- Data is clean and well-structured
- Direct download access (no scraping needed)

### Complexity: MEDIUM

- Multi-row header parsing required
- Schema changes across years (Non-Binary addition)
- Multiple data levels (district, school, combined)

### Estimated Files to Modify: 5-6

1.  `R/get_raw_graduation.R` - new file for raw data download
2.  `R/process_graduation.R` - new file for processing
3.  `R/tidy_graduation.R` - new file for tidying
4.  `R/fetch_graduation.R` - new file for main API
5.  `R/utils.R` - add graduation year validation
6.  `tests/testthat/test-pipeline-live-graduation.R` - new test file

### Implementation Steps:

1.  Create `get_media_id_graduation()` function with media ID mapping
2.  Create `get_raw_grad()` to download and parse Excel files
3.  Handle multi-row header parsing (detect subgroup row, then column
    names)
4.  Create `process_grad()` to standardize column names across years
5.  Create `tidy_grad()` to pivot to long format with subgroup column
6.  Create `fetch_grad()` as main user-facing function
7.  Add caching support
8.  Write comprehensive tests

### Subgroups to Extract:

- Overall
- Students with Disabilities (IEP)
- Low Socio-Economic Status (FRL)
- English Learners (EL)
- American Indian or Alaska Native
- Asian
- Black or African American
- Hispanic/Latino
- Native Hawaiian or Other Pacific Islander
- Two or More Races
- White
- Female
- Male
- Non-Binary (2024+)

## Test Requirements

### Raw Data Fidelity Tests Needed:

- **2024 State Summary:** Overall Rate = 88.26585%, Cohort = 38,699
- **2024 Des Moines:** Overall Rate = 71.38%, Cohort = 2,369
- **2024 Iowa City:** Overall Rate = 90.67%, Cohort = 1,157
- **2020 State Summary:** Verify corrected data matches raw file

### Data Quality Checks:

- No negative values
- Rates between 0 and 100
- Numerator \<= Denominator
- State total matches sum of districts (approximately)
- Major entities exist in all years
- All subgroups have state-level data (except Non-Binary pre-2024)

### Pipeline Tests:

1.  URL availability (HTTP 200) for all media IDs
2.  File download (verify actual Excel, not HTML error)
3.  File parsing (readxl succeeds)
4.  Column structure (expected columns exist)
5.  Year filtering works
6.  Aggregation (state = sum of districts)
7.  Data quality (no Inf/NaN)
8.  Output fidelity (tidy matches raw)

## Additional Notes

### Dropout Rate Data

Separate dropout rate files are available back to 1991-92, providing: -
Grades 7-12 dropout rates - Same subgroup breakdowns as graduation
data - Could be implemented as `fetch_dropout()` function

### Five-Year Graduation Rates

Available in the combined files, tracking students who graduate within 5
years: - Extends the 4-year cohort tracking - Same methodology, longer
timeframe - Class of 2023 5-year rate available in 2024 file

### Graduate Intentions Data

Separate data available on post-graduation plans: - Years: 2001-02
through 2024-25 - Could be future expansion: `fetch_grad_intentions()`
