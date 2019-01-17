decade_to_monthly <- function(list, dir, dates) {
  cl <- makeCluster(getOption("cl.cores", detectCores())) # 8 cores on a m5d.4xlarge instance
  pboptions(type = 'txt', use_lb = TRUE)
  
  pblapply(list, function(x, out_dir, date_range) {
    require(tidyverse)
    require(raster)
    name <- x %>%
      basename() %>%
      str_split('_') %>%
      unlist()
    name <- name[1]
    
    for(i in date_range) {
      if(!file.exists(file.path(out_dir, paste0(name, '.tif')))) {
        monthly_grid <- raster::stack(replicate(12, raster::raster(x)))
        writeRaster(monthly_grid, filename = file.path(out_dir, paste0(name, '_', i, '.tif')))
      }
    }
  }, 
  date_range = dates,
  out_dir = dir,
  cl = cl)
}
