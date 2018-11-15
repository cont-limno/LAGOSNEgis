
<!-- README.md is generated from README.Rmd. Please edit that file -->

# LAGOSNEgis

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)[![CRAN
status](https://www.r-pkg.org/badges/version/LAGOSNEgis)](https://cran.r-project.org/package=LAGOSNEgis)[![Travis
build
status](https://travis-ci.org/jsta/LAGOSNEgis.svg?branch=master)](https://travis-ci.org/jsta/LAGOSNEgis)

Extra functions to interact with the GIS module of LAGOSNE.

## Features

  - Queries are optimized for speed using `SQL` statements rather than
    loading entire layers

  - Repeated calls to a function with the same arguments are fast
    because function outputs are cached (*memoised*)

## Installation

``` r
remotes::install_github("jsta/LAGOSNEgis")
```

## Setup

*Optional: Place data at the location returned from
`LAGOSNEgis:::gis_path_default()`*

## Usage

``` r
library(LAGOSNEgis)
```

### List available GIS layers

``` r
sf::st_layers(LAGOSNEgis:::gis_path_default()
```

| name                                       | driver | features | fields |
| :----------------------------------------- | :----- | -------: | -----: |
| HU8                                        | GPKG   |      511 |     15 |
| HU4                                        | GPKG   |       65 |     15 |
| HU12                                       | GPKG   |    20257 |     14 |
| EDU                                        | GPKG   |       91 |     12 |
| LAGOS\_NE\_Study\_Extent                   | GPKG   |        1 |      2 |
| COUNTY                                     | GPKG   |      955 |     11 |
| Stream\_Polylines                          | GPKG   |  4014384 |     18 |
| LAGOS\_NE\_All\_Lakes\_1ha                 | GPKG   |   141265 |     34 |
| LAGOS\_NE\_All\_Lakes\_4ha                 | GPKG   |    51101 |     34 |
| LAGOS\_NE\_All\_Lakes\_1ha\_POINTS         | GPKG   |   141265 |     32 |
| LAGOS\_NE\_All\_Lakes\_4ha\_POINTS         | GPKG   |    51101 |     32 |
| LAGOS\_NE\_All\_Lakes\_4ha\_Buffered\_100m | GPKG   |    51101 |     16 |
| LAGOS\_NE\_All\_Lakes\_4ha\_Buffered\_500m | GPKG   |    51101 |     16 |
| Glaciation                                 | GPKG   |        2 |      3 |
| Wetlands                                   | GPKG   |  4403964 |     14 |
| Stream\_Polygons                           | GPKG   |    31239 |     10 |
| IWS                                        | GPKG   |    51071 |     14 |
| Border\_HU12                               | GPKG   |      169 |     14 |
| Border\_IWS                                | GPKG   |      170 |     13 |
| STATE                                      | GPKG   |       17 |     11 |
| US\_Canada\_Border                         | GPKG   |        1 |      1 |
| HU2                                        | GPKG   |       22 |     15 |
| LAGOS\_NE\_NHDReachCrossReference          | GPKG   |   404414 |     12 |

### Query from a specfic layer

``` r
res_iws  <- query_gis("IWS", "lagoslakeid", c(34352))
res_lake <- query_gis("LAGOS_NE_All_Lakes_4ha", "lagoslakeid", 34352)
res_pnt  <- query_gis("LAGOS_NE_All_Lakes_4ha_POINTS", "lagoslakeid", 34352)
```

### Query a combined watershed and lake polygon

``` r
res <- query_wbd(lagoslakeid = c(7010))
```

## References

Soranno P., K. Cheruvelil. 2017. LAGOS-NE-GIS v1.0: A module for
LAGOS-NE, a multi-scaled geospatial and temporal database of lake
ecological context and water quality for thousands of U.S. Lakes:
2013-1925. Environmental Data Initiative.
<http://dx.doi.org/10.6073/pasta/fb4f5687339bec467ce0ed1ea0b5f0ca>.
Dataset accessed 9/26/2017.
