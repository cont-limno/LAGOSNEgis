albers_conic <- function(){
  # Albers Equal Area Conic
  "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
}

lagosnegis_path <- function(){
  file.path(rappdirs::user_data_dir("LAGOS-GIS"), "lagos-ne_gis.gpkg")
}

lagosnegis_dir <- function(){
  rappdirs::user_data_dir("LAGOS-GIS")
}

#' @importFrom curl curl_fetch_memory
#' @importFrom stringr str_extract
get_file_names <- function(url){
  handle <- curl::new_handle(nobody = TRUE)

  headers <- curl::parse_headers(
    curl::curl_fetch_memory(url, handle)$headers)
  fname <- headers[grep("filename", headers)]

  res <- stringr::str_extract(fname, "(?<=\\=)(.*?)\\_gdb.zip")
  gsub('\\"', "", res)
}

get_if_not_exists <- function(url, destfile, overwrite){
  if(!file.exists(destfile) | overwrite){
    download.file(url, destfile, mode = "wb")
  }else{
    message(paste0("A local copy of ", url, " already exists on disk"))
  }
}

#' @importFrom sf st_transform st_crs st_is_longlat st_coordinates st_centroid
toUTM <- function(sf_object){

  if(is.na(st_crs(sf_object)$epsg)){
    sf_object <- st_transform(sf_object, crs = 4326)
  }

  if(sf::st_is_longlat(sf_object)){
    suppressWarnings(
      utm_zone <- long2UTM(st_coordinates(st_centroid(st_union(sf_object)))[1]))
    crs      <- paste0("+proj=utm +zone=", utm_zone, " +datum=WGS84")

    sf::st_transform(sf_object, crs = crs)
  }else{
    sf_object
  }
}

long2UTM <- function(long) {
  (floor((long + 180)/6) %% 60) + 1
}

has_7z <- function(){
  paths_7z <- c("7z",
                "~/usr/bin/7z",
                "C:\\PROGRA~1\\7-Zip\\7za",
                "C:\\PROGRA~1\\7-Zip\\7z.exe")
  if(!any(nchar(Sys.which(paths_7z)) > 0)){
    list(yes = FALSE, path = NA)
  }else{
    list(yes = TRUE, path = paths_7z[nchar(Sys.which(paths_7z)) > 0])
  }
}
