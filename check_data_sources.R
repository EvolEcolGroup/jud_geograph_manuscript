check_data_sources <- function(path=NULL){
  if (is.null(path)){
    path = getwd()
  }
  if(!file.exists(file.path(path,"/data/data_sources.csv"))){
    stop("data_sources.csv can not be found; are you in the root directory of your repository?")
  }
  
  data_sources <- read.csv (file.path(path,"/data/data_sources.csv"))
  # check that there are two columsn with correct names
  if (!all(c("directory","source") %in% names(data_sources))){
    "data_sources.csv does not include the two mandatory columns: 'directory' and 'sources'"
  }
  if (any(is.na(data_sources$source), is.na(data_sources$url))){
    stop("in data_sources.csv, some sources/url are have been left blank; \n",
         "all entries should be filled in, use 'local' in both source and url for dirs in which files that are synchronised with git")
  }
  raw_dirs <- list.dirs(file.path(path,"data/raw"), full.names = FALSE, recursive=FALSE)
  raw_dirs <- paste0("/data/raw/",raw_dirs)
  intermediate_dirs <- list.dirs(file.path(path,"data/intermediate"), full.names = FALSE, recursive=FALSE)
  if (length(intermediate_dirs)>0){
    intermediate_dirs <- paste0("/data/intermediate/",intermediate_dirs)
  }
  if (!all(c(raw_dirs,intermediate_dirs) %in% data_sources$directory)){
    stop("some directories are not listed in data_sources.csv")
  }
  return(TRUE)
}

check_data_sources()