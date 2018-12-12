.onLoad <- function(lib, pkg){
  if(!has_7z()){
    warning("The 7-zip program is needed to unpack LAGOSNEgis downloads (http://www.7-zip.org/).")
  }
}
