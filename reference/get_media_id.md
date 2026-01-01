# Get media ID for enrollment data file

Returns the media ID used in Iowa DOE download URLs for each year. These
IDs are extracted from the Education Statistics page.

## Usage

``` r
get_media_id(end_year, level = "district")
```

## Arguments

- end_year:

  School year end (e.g., 2025 for 2024-25)

- level:

  Data level: "district" or "school"

## Value

Character string with media ID
