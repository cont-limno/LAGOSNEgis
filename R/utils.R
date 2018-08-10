albers_conic <- function(){
  # Albers Equal Area Conic
  "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
}

gis_path_default <- function(){
  path.expand("~/.local/share/LAGOS-GIS/lagos-ne_gis.gpkg")
}
