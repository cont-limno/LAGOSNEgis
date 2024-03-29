
<!-- README.md is generated from README.Rmd. Please edit that file -->

# LAGOSNEgis

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://www.tidyverse.org/lifecycle/#stable)
[![CRAN
status](https://www.r-pkg.org/badges/version/LAGOSNEgis)](https://cran.r-project.org/package=LAGOSNEgis)
[![Travis build
status](https://travis-ci.org/cont-limno/LAGOSNEgis.svg?branch=master)](https://travis-ci.org/cont-limno/LAGOSNEgis)
[![DOI](https://zenodo.org/badge/106293356.svg)](https://zenodo.org/badge/latestdoi/106293356)

Extra functions to interact with the GIS module of LAGOSNE.

## Features

-   **Easy**: Convenience functions allow for straight-forward
    subsetting.

-   **Fast**: Queries are optimized for speed to avoid loading the
    entirety of massive layers.

-   **Flexible** : Custom queries can be constructed using `SQL`
    statements.

## Installation

``` r
remotes::install_github("cont-limno/LAGOSNEgis")
```

## Usage

``` r
library(LAGOSNEgis)
```

### Download data

``` r
lagosnegis_get()
```

### List available GIS layers

``` r
library(sf)
sf::st_layers(LAGOSNEgis:::lagosnegis_path())
```

### Query from a specfic layer

``` r
res_iws  <- query_gis(layer = "IWS", 
                      id_name = "lagoslakeid", ids = c(34352))
res_lake <- query_gis(layer = "LAGOS_NE_All_Lakes_4ha", 
                      id_name = "lagoslakeid", ids = 34352)
res_pnt  <- query_gis(layer = "LAGOS_NE_All_Lakes_4ha_POINTS", 
                      id_name = "lagoslakeid", ids = 34352)
```

### Query a combined watershed and lake polygon

``` r
res <- query_wbd(lagoslakeid = c(7010))
```

### Flexible queries using `SQL` statements

``` r
res <- query_gis_(query = "SELECT * FROM IWS WHERE lagoslakeid IN ('7010');")
```

## References

Soranno P., K. Cheruvelil. 2017. LAGOS-NE-GIS v1.0: A module for
LAGOS-NE, a multi-scaled geospatial and temporal database of lake
ecological context and water quality for thousands of U.S. Lakes:
2013-1925. Environmental Data Initiative.
<http://dx.doi.org/10.6073/pasta/fb4f5687339bec467ce0ed1ea0b5f0ca>.
Dataset accessed 9/26/2017.
