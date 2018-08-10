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
query_gis <- function(gis_path = gis_path(), query, crs){

  dat <- as.data.frame(vapour_read_attributes(gis_path, sql = query),
                       stringsAsFactors = FALSE)
  dat <- dplyr::mutate(dat,
                         wkt = vapour_read_geometry_text(gis_path,
                                                       sql = query, textformat = "wkt"))
  sf::st_geometry(dat) <- sf::st_as_sfc(dat$wkt)
  sf::st_crs(dat) <- sf::st_crs(crs)

  sf::st_zm(dat)
}

#' Query watershed boundary for LAGOS lakes
#'
#' @param lagoslakeid numeric
#' @param gis_path file.path to LAGOSNE GIS gpkg
#' @param crs projection string or epsg code
#' @param utm logical convert crs to utm
#'
#' @importFrom sf st_union st_geometry<-
#' @export
#' @examples \dontrun{
#' library(sf)
#' res <- query_wbd(lagoslakeid = c(5371, 4559))
#' plot(res)
#' }
query_wbd <- function(lagoslakeid, gis_path = gis_path(), crs = albers_conic(),
                      utm = TRUE){

  iws <- query_gis(gis_path,
    query = paste0("SELECT * FROM IWS WHERE lagoslakeid IN ('",
                   paste0(lagoslakeid,
                          collapse = "', '"), "');"), crs = crs)
  lake_boundary <- query_gis(gis_path,
    query = paste0("SELECT * FROM LAGOS_NE_All_Lakes_4ha WHERE lagoslakeid IN ('",
                   paste0(lagoslakeid,
                          collapse = "', '"), "');"), crs = crs)

  res <- lapply(seq_len(nrow(iws)), function(x) {
    st_geometry(st_union(st_geometry(iws)[x],
                         st_geometry(lake_boundary)[x]))})

  res <- do.call(c, res)
  st_geometry(iws) <- res

  if(utm){
    nhdR::toUTM(iws)
  }else{
    iws
  }
}
