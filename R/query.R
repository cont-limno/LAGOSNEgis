#' Query LAGOS GIS
#'
#' @param layer character layer name
#' @param id_name selection column
#' @param ids feature ids to select
#' @param crs character projection info defaults to lagosnegis_path()
#' @param gis_path character path to LAGOSNE GIS gpkg
#'
#' @importFrom sf st_geometry st_geometry_type st_cast
#' @importFrom memoise memoise
#' @export
#'
#' @examples \dontrun{
#'
#' library(sf)
#' st_layers(lagosnegis_path())
#'
#' library(gdalUtils)
#' ogrinfo(lagosnegis_path(), "HU12", so = TRUE)
#'
#' library(mapview)
#' res_iws  <- query_gis("IWS", "lagoslakeid", c(34352))
#' res_lake <- query_gis("LAGOS_NE_All_Lakes_4ha", "lagoslakeid", 34352)
#' res_pnt  <- query_gis("LAGOS_NE_All_Lakes_4ha_POINTS", "lagoslakeid", 34352)
#' mapview(res_iws) + mapview(res_lake) + mapview(res_pnt)
#'
#' res <- query_gis("IWS", "lagoslakeid", c(7010))
#' res <- query_gis("HU12", "ZoneID", c("HU12_1"))
#' res <- query_gis("HU8", "ZoneID", c("HU8_100"))
#' res <- query_gis("HU4", "ZoneID", c("HU4_5"))
#' }
query_gis <- memoise::memoise(function(layer, id_name, ids, crs = albers_conic(),
                      gis_path = lagosnegis_path()){
  res <- query_gis_(gis_path,
             query = paste0("SELECT * FROM ", layer,
                            " WHERE ", id_name, " IN ('",
                            paste0(ids,
                                   collapse = "', '"), "');"), crs = crs)

  # sort items by ids
  res <- res[match(ids, data.frame(res[,id_name])[,id_name]),]

  if(any(unique(sf::st_geometry_type(sf::st_geometry(res))) == "MULTISURFACE")){
    res <- sf::st_cast(res, "MULTIPOLYGON")
  }

  res
})

#' Raw (non-vectorized) query of LAGOS GIS
#'
#' @param gis_path file path
#' @param query SQL string
#' @param crs coordinate reference system string or epsg code
#'
#' @importFrom vapour vapour_read_geometry_text vapour_read_attributes
#' @importFrom dplyr mutate select
#' @importFrom sf st_as_sfc st_crs st_geometry st_zm
#' @importFrom rlang .data
#'
#' @export
#'
#' @examples \dontrun{#'
#' res <- query_gis_(gis_path = "/home/jose/.local/share/LAGOS-GIS/lagos-ne_gis.gpkg",
#' query = "SELECT * FROM IWS WHERE lagoslakeid IN ('7010');",
#' crs = LAGOSextra:::albers_conic())
#' }
#'
query_gis_ <- function(gis_path = lagosnegis_path(), query, crs = albers_conic()){

  # error if extent is not NA and query is defined?

  # investigate specific layers
  # library(sf)
  # library(vapour)
  # crs <- LAGOSextra:::albers_conic()
  # gis_path <- "/home/jose/.local/share/LAGOS-GIS/lagos-ne_gis.gpkg"
  # st_layers(gis_path)
  # query <- "SELECT * FROM HU4 LIMIT 1"
  # as.data.frame(vapour_read_attributes(gis_path, sql = query),
  #                      stringsAsFactors = FALSE)

  # investigate extent argument
  # e <- as.numeric(st_bbox(dat))[c(1, 3, 2, 4)]
  # wkt <- vapour_read_geometry_text(gis_path, extent = e, sql = "SELECT * FROM IWS")
  # need to be able to set extent on vapour_read_attributes

  ###
  dat <- as.data.frame(vapour_read_attributes(gis_path, sql = query),
                       stringsAsFactors = FALSE)
  dat <- dplyr::mutate(dat,
                         wkt = vapour_read_geometry_text(gis_path,
                                                       sql = query, textformat = "wkt"))
  sf::st_geometry(dat) <- sf::st_as_sfc(dat$wkt)
  dat                  <- dplyr::select(dat, -.data$wkt)
  sf::st_crs(dat)      <- sf::st_crs(crs)

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
#' @importFrom memoise memoise
#' @importFrom nhdR toUTM
#' @export
#' @examples \dontrun{
#' library(mapview)
#' res <- query_wbd(lagoslakeid = c(7010))
#' res <- query_wbd(lagoslakeid = c(7010, 34352))
#' res <- query_wbd(lagoslakeid = c(34352))
#' mapview(res)
#'
#' res <- query_wbd(lagoslakeid = c(2057, 3866, 1500, 3386, 2226,
#' 1637, 6874, 7032, 1935, 6970, 5331, 34352))
#' res <- res[res$lagoslakeid == 34352,]
#' mapview::mapview(res)
#'
#' }
query_wbd <- memoise::memoise(function(lagoslakeid, gis_path = lagosnegis_path(),
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
})
