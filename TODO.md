# TODO

## pkgdown Build Issues

### Network Connectivity Issue (2026-01-01)

The pkgdown build is failing due to network timeout errors when
attempting to reach CRAN servers:

    Error in `httr2::req_perform(req)`:
    ! Failed to perform HTTP request.
    Caused by error in `curl::curl_fetch_memory()`:
    ! Timeout was reached [cloud.r-project.org]:
    Connection timed out after 10002 milliseconds

**Root cause**: pkgdown attempts to check CRAN for package metadata
during sidebar generation (`pkgdown:::cran_link()`). When network
connectivity is unavailable or slow, this causes the build to fail.

**Resolution options**: 1. Wait for network connectivity to be restored
and retry 2. Run the build in an environment with reliable internet
access 3. The GitHub Actions CI/CD workflow should work correctly as
GitHub runners have reliable connectivity

**Note**: This is a transient infrastructure issue, not a code problem.
No vignettes exist in this package.
