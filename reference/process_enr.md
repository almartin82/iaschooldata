# Process raw Iowa enrollment data

Transforms raw Iowa DOE data into a standardized schema combining
district and school data.

## Usage

``` r
process_enr(raw_data, end_year)
```

## Arguments

- raw_data:

  List containing district and school data frames from get_raw_enr

- end_year:

  School year end

## Value

Processed data frame with standardized columns
