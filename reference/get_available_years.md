# Get available years for Iowa enrollment data

Returns the years for which enrollment data is available. Iowa has
historical data from 1946-47 and modern data through 2024-25.

## Usage

``` r
get_available_years(include_missing = FALSE)
```

## Arguments

- include_missing:

  If FALSE (default), returns only years with data. If TRUE, returns
  full range from min to max year.

## Value

Integer vector of available years

## Details

Note: Not all years have data available. Missing years include:

- 1948 (1947-48)

- 1950 (1949-50)

- 1952 (1951-52)

- 1954 (1953-54)

- 1971 (1970-71)

- 1972 (1971-72)

## Examples

``` r
get_available_years()
#>  [1] 1947 1949 1951 1953 1955 1956 1957 1958 1959 1960 1961 1962 1963 1964 1965
#> [16] 1966 1967 1968 1969 1970 1973 1974 1975 1976 1977 1978 1979 1980 1981 1982
#> [31] 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997
#> [46] 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012
#> [61] 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024
get_available_years(include_missing = TRUE)
#>  [1] 1947 1948 1949 1950 1951 1952 1953 1954 1955 1956 1957 1958 1959 1960 1961
#> [16] 1962 1963 1964 1965 1966 1967 1968 1969 1970 1971 1972 1973 1974 1975 1976
#> [31] 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991
#> [46] 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006
#> [61] 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021
#> [76] 2022 2023 2024
```
