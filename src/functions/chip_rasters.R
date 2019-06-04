# Function to chip out and save rasters
chip_rasters <- function(input_tiles, var_list, out_dir) {
  
  # Set parallel environment and progress bar
  cl <- makeCluster(getOption("cl.cores", detectCores())) # 8 cores on a m5d.4xlarge instance
  pboptions(type = 'txt', use_lb = TRUE)
  
  pblapply(input_tiles, function(x, raster_list, dir){
    require(tidyverse)
    require(raster)
    require(tools)
    require(pbapply)

    tile_name <-  basename(x) %>%
      file_path_sans_ext(.)
    
    pblapply(raster_list, function(j, dir){
      
      yearly_rst <- raster::stack(j)
      
      pblapply(1:nlayers(yearly_rst), function(z, dir) {
        raster_name <- basename(j) %>%
          file_path_sans_ext()
        out_name <- paste0(dir, raster_name, '_', z, '_', tile_name, '.tif')
        
        if(!file.exists(out_name)) {
          shp_list <- as(raster::extent(raster::raster(x)), "SpatialPolygons")
          proj4string(shp_list) <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"
          
          mask_rst_tile <- yearly_rst[[z]] %>%
            crop(shp_list) %>%
            mask(shp_list)
          writeRaster(mask_rst_tile, filename = out_name)
        }
      }, dir = dir)
    }, 
    dir = dir)
  }, 
  dir = out_dir,
  raster_list = var_list,
  cl = cl)
  stopCluster(cl)
}