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
#' library(sf)
#' st_layers(gis_path_default())
#'
#' library(gdalUtils)
#' ogrinfo(gis_path_default(), "HU12", so = TRUE)
#'
#' library(mapview)
#' res_iws <- query_gis("IWS", "lagoslakeid", c(34352))
#' res_lake <- query_gis("LAGOS_NE_All_Lakes_4ha", "lagoslakeid", 34352)
#' mapview(res_iws) + mapview(res_lake)
#'
#' res <- query_gis("IWS", "lagoslakeid", c(7010))
#' res <- query_gis("HU12", "ZoneID", c("HU12_1"))
#' }
query_gis <- function(layer, id_name, ids, crs = albers_conic(),
                      gis_path = gis_path_default()){
  res <- query_gis_(gis_path,
             query = paste0("SELECT * FROM ", layer,
                            " WHERE ", id_name, " IN ('",
                            paste0(ids,
                                   collapse = "', '"), "');"), crs = crs)

  # sort items by ids
  res <- res[match(ids, data.frame(res[,id_name])[,id_name]),]
  res
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
#' @importFrom sf st_union st_geometry<- st_crs<- st_buffer
#' @export
#' @examples \dontrun{
#' library(mapview)
#' res <- query_wbd(lagoslakeid = c(7010))
#' res <- query_wbd(lagoslakeid = c(7010, 34352))
#' res <- query_wbd(lagoslakeid = c(34352))
#' mapview(res)
#'
#' res <- query_wbd(lagoslakeid = c(2057, 3866, 1500, 3386, 2226, 1637, 6874, 7032, 1935, 6970, 5331, 34352))
#' res <- res[res$lagoslakeid == 34352,]
#' mapview::mapview(res)
#'
#' }
query_wbd <- function(lagoslakeid, gis_path = gis_path_default(),
                      crs = albers_conic(), utm = FALSE){

  iws           <- query_gis("IWS", "lagoslakeid", lagoslakeid)
  lake_boundary <- query_gis("LAGOS_NE_All_Lakes_4ha", "lagoslakeid", lagoslakeid)

  res <- lapply(seq_len(nrow(iws)), function(x) {
          iws_dissolve  <- st_buffer(do.call(c, st_geometry(iws)[x]), 0)
          lake_dissolve <- st_buffer(do.call(c, st_geometry(lake_boundary)[x]), 0.001)

          st_geometry(st_union(iws_dissolve, lake_dissolve))
          })

  res <- do.call(c, res)
  st_crs(res) <- crs
  st_geometry(iws) <- res

  if(utm){
    nhdR::toUTM(iws)
  }else{
    iws
  }
}
