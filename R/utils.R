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
