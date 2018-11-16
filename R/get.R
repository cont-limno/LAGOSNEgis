#' Get LAGOSNEgis data
#'
#' Get data from the GIS module of LAGOSNE
#'
#' @export
#' @importFrom utils unzip download.file
#' @importFrom gdalUtils ogr2ogr
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
  outpath <- file.path(dest_folder, "lagos-ne_gis.gpkg")
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
                   function(i) get_if_not_exists(files[i], file_paths[i], overwrite)))

  dir.create(dest_folder, showWarnings = FALSE)
  unzip(file_paths, exdir = dest_folder)

  message("LAGOSNEgis downloaded. Now converting to gpkg ...")

  inpath <- file.path(dest_folder,
                      gsub("_gdb", ".gdb",
       stringr::str_extract(as.character(file_names), "(^.*)(?=\\.zip)")))
  gdalUtils::ogr2ogr(inpath, outpath)

  return(invisible(outpath))
}

