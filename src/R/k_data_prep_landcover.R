# https://landcover-modeling.cr.usgs.gov/projects.php

# List all decadal tiffs from the FORE-SCE gridded landcover products
anthro_list <- list.files(file.path(raw_prefix, 'fore-sce'),
                          pattern = '*.tif',
                          full.names = TRUE,
                          recursive = TRUE)
elevation <- raster::raster(file.path(processed_dir, 'terrain', "elevation.tif"))

pboptions(type = 'txt', use_lb = TRUE)
cl <- makeCluster(getOption("cl.cores", 2)) # 16 cores on a m5d.4xlarge instance

pblapply(anthro_list, function(x, raster_mask, masks, dir) {
  require(tidyverse)
  require(raster)
  
  names <- x %>%
    basename() %>%
    tolower()
  
  if(!file.exists(file.path(dir, names))) {
    rst <- raster::raster(x) %>%
      raster::aggregate(., fact = 4, fun = modal, na.rm = TRUE) %>%
      raster::projectRaster(., raster_mask, method = 'ngb') %>%
      raster::mask(masks)
    
    writeRaster(rst, file.path(dir, names))
    }
  }, 
  raster_mask = elevation, 
  masks = as(usa_shp, 'Spatial'),
  dir = proc_landcover, 
  cl = cl)

stopCluster(cl)