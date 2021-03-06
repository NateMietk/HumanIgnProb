
final_list <- list.files(cumsum_ztrax_dir, full.names = TRUE)

if(length(final_list) != 37){
  rst_list <- list.files(raw_ztrax_dir, pattern = '.gpkg$', full.names = TRUE)
  
  for(i in rst_list) {
  
    shp <- sf::st_read(i) %>%
      filter(built_class == 'Residential') %>%
      filter(YearBuilt != 0) %>%
      mutate(YearBuilt = ifelse(YearBuilt < 1980, 1980, YearBuilt))
    
    state_name <- basename(i) %>%
      stringr::str_extract_all(.,"\\(?[0-9,]+\\)?")
    
    cl <- makeCluster(6)
    registerDoParallel(cl)
    
    foreach(j = unique(shp$YearBuilt), .packages = c('tidyverse', 'sf', 'raster')) %dopar% {
  
      filter_shp <- shp %>%
        filter(YearBuilt == j)
  
      ras_template <- raster_mask
      
      rst_tmp <- raster::rasterize(filter_shp, ras_template, fun = 'count', field = 'built_class')
      
      names(rst_tmp) <- j
      raster::writeRaster(rst_tmp, file.path(stacked_ztrax_rst_dir, paste0('ztrax_count_', state_name, '_', j, '.tif')), 
                          format = "GTiff", overwrite = TRUE)
    }
    stopCluster(cl)
    system(paste0("aws s3 sync ", anthro_dir, " ", s3_proc_anthro))
   }
  
  
  for(j in 1980:2016) {
    rst_list <- list.files(stacked_ztrax_rst_dir, pattern = paste0(j, '.tif'), full.names = TRUE)
    
    out_rst <- raster::stack(rst_list)
    out_rst <- calc(out_rst, sum, na.rm =TRUE) %>%
      mask(as(usa_shp, 'Spatial'))
    
    raster::writeRaster(out_rst, file.path(count_ztrax_dir, paste0('ztrax_count_', j, '.tif')),
                        format = "GTiff", overwrite = TRUE)
    system(paste0("aws s3 sync ", anthro_dir, " ", s3_proc_anthro))
  }
  
  rst_list <- list.files(count_ztrax_dir, full.names = TRUE)
  rsts <- lapply(rst_list, raster)
  rsts <- Reduce("+", rsts, accumulate = TRUE)
  
  lapply(seq_along(rsts), function(x) {
    name <- gsub("count", "cumsum", rst_list[x])
    
    writeRaster(rsts[[x]], name, datatype = 'GTiff')
  })
  system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix))
  
} else {
  ztrax_grid <- raster::stack(final_list)
}

ztrax_list <- list.files(cumsum_ztrax_dir, pattern = '.tif$', full.names = TRUE)
create_monthy_repeats(time = rep(1992:2015), var_list = ztrax_list, 
                      out_dir = anthro_monthly_proc_dir)
system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix, ' --delete'))