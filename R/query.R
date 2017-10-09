#' Query LAGOS GIS
#'
#' @param gis_path file path
#' @param query SQL string
#' @param crs coordinate reference system string or epsg code
#'
#' @importFrom vapour vapour_read_geometry_text vapour_read_attributes
#' @importFrom dplyr mutate
#' @importFrom sf st_as_sfc st_crs st_geometry st_zm
#'
#' @export
#'
query_gis <- function(gis_path, query, crs){
  dat <- as.data.frame(vapour_read_attributes(gis_path, sql = query),
                       stringsAsFactors = FALSE)
  dat <- dplyr::mutate(dat,
                         wkt = vapour_read_geometry_text(gis_path,
                                                       sql = query, format = "wkt"))
  sf::st_geometry(dat) <- sf::st_as_sfc(dat$wkt)
  sf::st_crs(dat) <- sf::st_crs(crs)

  sf::st_zm(dat)
}
