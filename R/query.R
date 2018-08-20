#' Query LAGOS GIS
#'
#' @param layer character layer name
#' @param id_name selection column
#' @param ids feature ids to select
#' @param crs character projection info defaults to gis_path_default()
#' @param gis_path character path to LAGOSNE GIS gpkg
#'
#' @export
#'
#' @examples \dontrun{
#'
#' # library(sf)
#' # library(gdalUtils)
#' # st_layers(gis_path_default())
#' # ogrinfo(gis_path_default(), "HU12", so = TRUE)
#'
#' res <- query_gis("IWS", "lagoslakeid", c(701"0))
#' res <- query_gis("HU12", "ZoneID", c("HU12_1"))
#' }
query_gis <- function(layer, id_name, ids, crs = albers_conic(),
                      gis_path = gis_path_default()){
  query_gis_(gis_path,
             query = paste0("SELECT * FROM ", layer,
                            " WHERE ", id_name, " IN ('",
                            paste0(ids,
                                   collapse = "', '"), "');"), crs = crs)
}

#' Raw (non-vectorized) query of LAGOS GIS
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
#' @examples \dontrun{
#' res <- query_gis_(gis_path = "/home/jose/.local/share/LAGOS-GIS/lagos-ne_gis.gpkg",
#' query = "SELECT * FROM IWS WHERE lagoslakeid IN ('7010');",
#' crs = albers_conic())
#' }
#'
query_gis_ <- function(gis_path, query, crs){

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
#' library(mapview)
#' res <- query_wbd(lagoslakeid = c(5371))
#' mapview(res)
#'
#' res <- query_wbd(lagoslakeid = c(2057, 3866, 1500, 3386, 2226, 1637, 6874, 7032, 1935, 6970, 5331))
#'
#' }
query_wbd <- function(lagoslakeid, gis_path = gis_path_default(),
                      crs = albers_conic(), utm = TRUE){

  iws <- query_gis_(gis_path,
    query = paste0("SELECT * FROM IWS WHERE lagoslakeid IN ('",
                   paste0(lagoslakeid,
                          collapse = "', '"), "');"), crs = crs)

  lake_boundary <- query_gis_(gis_path,
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
