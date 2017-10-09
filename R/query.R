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
query_gis <- function(gis_path = NA, query, crs){
  if(is.na(gis_path)){
    gis_path <- options("gis_path")$gis_path
  }
  dat <- as.data.frame(vapour_read_attributes(gis_path, sql = query),
                       stringsAsFactors = FALSE)
  dat <- dplyr::mutate(dat,
                         wkt = vapour_read_geometry_text(gis_path,
                                                       sql = query, format = "wkt"))
  sf::st_geometry(dat) <- sf::st_as_sfc(dat$wkt)
  sf::st_crs(dat) <- sf::st_crs(crs)

  sf::st_zm(dat)
}

#' Query watershed boundary for LAGOS lakes
#'
#' @importFrom sf st_union
#' @export
#' @examples \dontrun{
#' res <- query_wbd(lagoslakeid = 7429)
#' }
query_wbd <- function(lagoslakeid, crs = NA){
  if(is.na(crs)){
    crs <- "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
  }

  iws <- query_gis(query = paste0("SELECT * FROM IWS WHERE lagoslakeid=",
                                  lagoslakeid), crs = crs)
  lake_boundary <- query_gis(
    query = paste0("SELECT * FROM LAGOS_NE_All_Lakes_4ha WHERE lagoslakeid=",
                   lagoslakeid), crs = crs)

  sf::st_union(st_geometry(iws), st_geometry(lake_boundary))
}
