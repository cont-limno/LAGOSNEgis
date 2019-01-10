#' Get LAGOSNEgis data
#'
#' Get data from the GIS module of LAGOSNE
#'
#' @export
#' @importFrom utils unzip download.file
#' @importFrom gdalUtilities ogr2ogr
#' @param dest_folder file.path defaults to lagosnegis_path()
#' @param overwrite logical
#' @references Soranno P., K. Cheruvelil. 2017. LAGOS-NE-GIS v1.0: A module for
#'  LAGOS-NE, a multi-scaled geospatial and temporal database of lake
#'  ecological context and water quality for thousands of U.S. Lakes:
#'  2013-1925. Environmental Data Initiative.
#'  http://dx.doi.org/10.6073/pasta/fb4f5687339bec467ce0ed1ea0b5f0ca.
#'  Dataset accessed 9/26/2017.
#'
#' @examples \dontrun{
#' lagosnegis_get()
#' }
lagosnegis_get <- function(dest_folder = lagosnegis_dir(), overwrite = FALSE){
  # dest_folder <- LAGOSNEgis:::lagosnegis_path()
  outpath <- file.path(dest_folder, "lagos-ne_gis.gpkg")
  dest_gdb <- file.path(dest_folder, "LAGOS_NE_GIS_Data_v1.0.gdb")

  if(file.exists(outpath) & !overwrite){
    warning("LAGOSNEgis data already exists on the local machine.
  Re-download if neccessary using the 'overwrite` argument.'")
    return(invisible("LAGOS is the best"))
  }

  edi_baseurl   <- "https://portal.edirepository.org/nis/dataviewer?packageid="
  pasta_baseurl <- "http://pasta.lternet.edu/package/data/eml/edi/"
  edi_url       <- paste0(edi_baseurl, c("edi.98.1"))
  pasta_url     <- paste0(pasta_baseurl, "98/1")

  files      <- suppressWarnings(paste0(edi_url, "&entityid=",
                                        readLines(pasta_url)))
  # file_names <- sapply(files, get_file_names)
  # file_ind <- as.numeric(which(!is.na(file_names)))
  files      <- files[20] # files[file_ind]
  file_names <- "LAGOSNE_GIS_Data_v1.0_gdb.zip" # file_names[file_ind]

  local_dir   <- file.path(tempdir())
  dir.create(local_dir, showWarnings = FALSE)
  file_paths  <- file.path(local_dir, file_names)

  invisible(lapply(seq_len(length(files)),
                   function(i) get_if_not_exists(files[i], file_paths[i],
                                                 overwrite)))

  message("LAGOSNEgis downloaded. Now converting to gpkg ...")
  dir.create(dest_folder, showWarnings = FALSE)
  unlink(dest_gdb, recursive = TRUE)
  system(paste0(has_7z()$path, " e ", file_paths, " -o",
                dest_gdb))

  unlink(outpath, recursive = TRUE)
  gdalUtilities::ogr2ogr(dest_gdb, outpath, dim = 2,
                         overwrite = TRUE,
                         nlt = "PROMOTE_TO_MULTI", f = "GPKG")

  gdalUtilities::ogr2ogr(dest_gdb, outpath, dim = 2,
                         sql = "select *, cast(Shape_Area as numeric(30,5)) as Shape_Area from IWS",
                         dialect = "ogrsql", overwrite = TRUE, f = "GPKG")

  # gdalUtils::ogrinfo(lagosnegis_path(), so = TRUE, sql = 'select * from IWS limit 1')
  # gdalUtils::ogrinfo(lagosnegis_path())

  return(invisible(outpath))
}

get_xwalk <- function(){
  t_file <- tempfile(fileext = ".csv")
  gh_file(owner = "cont-limno", repo = "LAGOS_Lake_Link",
          path = "LAGOS_Lake_Link_v0.csv",
          destfile = t_file)

  xwalk <- read.csv(t_file,
                    stringsAsFactors = FALSE)
  saveRDS(xwalk, file.path(lagosnegis_dir(), "xwalk.rds"))
}

#' Load cross walk table between LAGOSNE and NHD
#'
#' @importFrom utils read.csv
#' @export
#' @examples \dontrun{
#' xwalk <- load_xwalk()
#' }
load_xwalk <- memoise::memoise(function(){
  xwalk_path <- file.path(lagosnegis_dir(), "xwalk.rds")
  if(!file.exists(xwalk_path)){
    get_xwalk()
  }
  readRDS(xwalk_path)
})
