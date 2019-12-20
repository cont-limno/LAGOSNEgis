albers_conic <- function(){
  # Albers Equal Area Conic
  "+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"
}

#' Get the path to LAGOSNEgis data
#'
#' @export
lagosnegis_path <- function(){
  file.path(rappdirs::user_data_dir("LAGOS-GIS"), "LAGOSNE_GIS_Data_v1.0.gdb")
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

#' Gets a file from a github repo, using the Data API blob endpoint
#'
#' This avoids the 1MB limit of the content API and uses [gh::gh] to deal with
#' authorization and such.  See https://developer.github.com/v3/git/blobs/ and https://gist.github.com/noamross/73944d85cad545ae89efaa4d90b049db
#' @param url the URL of the file to download via API, of the form
#'   `:owner/:repo/blob/:path
#' @param ref the reference of a commit: a branch name, tag, or commit SHA
#' @param owner,repo,path alternate way to specify the file.  These will
#'   override values in `url`
#' @param to_disk,destfile write file to disk (default=TRUE)?  If so, use the
#'   name in `destfile`, or the original filename by default
#' @param .token,.api_url,.method,.limit,.send_headers arguments passed on to
#'   [gh::gh]
#' @importFrom gh gh
#' @importFrom stringi stri_match_all_regex
#' @importFrom purrr %||% keep
#' @importFrom base64enc  base64decode
#' @export
#' @return Either the local path of the downloaded file (default), or a raw
#'   vector
gh_file <- function(url = NULL, ref=NULL,
                    owner = NULL, repo = NULL, path = NULL,
                    to_disk=TRUE, destfile=NULL,
                    .token = NULL, .api_url= NULL, .method="GET",
                    .limit = NULL, .send_headers = NULL) {
  if (!is.null(url)) {
    matches <- stringi::stri_match_all_regex(
      url,
      "(github\\.com/)?([^\\/]+)/([^\\/]+)/[^\\/]+/([^\\/]+)/([^\\?]+)"
    )
    owner <- owner %||% matches[[1]][3]
    repo <- repo %||% matches[[1]][4]
    ref <- ref %||% matches[[1]][5]
    path <- path %||% matches[[1]][6]
    pathfile <- basename(path)
  }
  pathdir <- dirname(path)
  if(length(grep("/", path)) == 0){
    pathdir <- NULL
  }

  dir_contents <- gh(
    "/repos/:owner/:repo/contents/",
    owner = owner, repo = repo
  )

  file_sha <- keep(dir_contents, ~ .$path == path)[[1]]$sha
  blob <- gh(
    "/repos/:owner/:repo/git/blobs/:sha",
    owner = owner, repo = repo, sha = file_sha,
    .token = NULL, .api_url = NULL, .method = "GET",
    .limit = NULL, .send_headers = NULL
  )
  raw <- base64decode(blob[["content"]])
  if (to_disk) {
    destfile <- destfile %||% pathfile
    writeBin(raw, con = destfile)
    return(destfile)
  } else {
    return(raw)
  }
}
