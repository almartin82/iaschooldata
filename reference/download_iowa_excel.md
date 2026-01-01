# Download and read Iowa DOE Excel file

Downloads an Excel file from Iowa DOE and reads it into a data frame.
Iowa files have header rows that need to be detected and skipped.

## Usage

``` r
download_iowa_excel(end_year, level)
```

## Arguments

- end_year:

  School year end

- level:

  Data level: "district" or "school"

## Value

Data frame with enrollment data
