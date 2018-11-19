create_monthy_repeats <- function(time, var_list, out_dir) {
  # Set parallel environment and progress bar
  cl <- makeCluster(getOption("cl.cores", detectCores())) # 8 cores on a m5d.4xlarge instance
  pboptions(type = 'txt', use_lb = TRUE)
  
  pblapply(time, function(j, dir, raster_list){
    require(tidyverse)
    require(raster)
    require(tools)
    require(pbapply)
    
    pblapply(raster_list, function(x, k) {
      n <- 12
      
      grid_name <-  basename(x) %>%
        file_path_sans_ext()
      out_name <- paste0(k, '/', grid_name, '_', j, '.tif')
      
      if(!file.exists(out_name)) {
        monthly_grid <- raster::stack(replicate(n, raster::raster(x)))
        writeRaster(monthly_grid, filename = out_name)
      }
    }, 
    k = dir)
  }, 
  raster_list = var_list,
  dir = out_dir,
  cl = cl)
  
  stopCluster(cl)
}
