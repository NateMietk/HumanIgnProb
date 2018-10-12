rasterize_shapefile <- function(shp, out_rst, 
                                dir_rst = transportation_processed_dir, 
                                ras_template = raster::raster(file.path(terrain_dir, "elevation.tif"))) {
  if(!file.exists(file.path(dir_rst, out_rst))) {
    
    pspSl <- as.psp(as(shp, 'Spatial'))
    rastered <- raster::raster(pixellate(pspSl, eps=1000))
    crs(rastered) <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"
    
    rastered <- projectRaster(from = rastered, to = ras_template, method = 'bilinear')
    
    writeRaster(rastered, filename= file.path(dir_rst, out_rst), format="GTiff")
    return(rastered)
  } else {
    rastered <- raster(file.path(dir_rst, out_rst))
    return(rastered)
  }
}
get_density <- function(dir_pro = transportation_processed_dir, 
                        dir_den = transportation_density_dir,
                        out_pro, out_den) {
  
  if(!file.exists(file.path(dir_den, out_den))) {
    
    rst_den <- raster::raster(file.path(dir_pro, out_pro))
    rst_den <- rst_den/1000
    writeRaster(rst_den, filename= file.path(dir_den, out_den), format="GTiff")
    return(rst_den)
  } else {
    rst_den <- raster::raster(file.path(dir_den, out_den))
    return(rst_den)
  }
}
get_distance <- function(dir_rst = transportation_processed_dir, 
                         dir_dis = transportation_dist_dir, 
                         out_dis, out_rst) {
  
  if(!file.exists(file.path(dir_dis, out_dis))) {
    rst_dist <- raster::raster(file.path(dir_rst, out_rst))
    reclass_m <- matrix(c(-Inf, 0, NA, 0, Inf, 1), ncol = 3, byrow = TRUE)
    
    rst_dist <- raster::reclassify(rst_dist, reclass_m) 
    rst_dist <- raster::distance(rst_dist)
    endCluster()
    
    writeRaster(rst_dist, filename= file.path(dir_dis, out_dis), format="GTiff")
    return(rst_dist)
  } else {
    rst_dist <- raster::raster(file.path(dir_dis, out_dis))
    return(rst_dist)
  }
}

if (!file.exists(file.path(transportation_density_dir, "railroad_distance.tif"))) {
  
  rasterize_shapefile(shp = rail_rds, out_rst = 'railroad.tif')
  railroad_density <- get_density(out_pro = 'railroad.tif', out_den = 'railroad_density.tif')
  railroad_distance <- get_distance(out_rst = 'railroad.tif', out_dis = 'railroad_distance.tif')
  
  system(paste0("aws s3 sync ",  processed_dir, " ", s3_proc_prefix))
  
} else {
  railroad_density <- raster(file.path(transportation_density_dir, "railroad_density.tif"))
  railroad_distance <- raster(file.path(transportation_dist_dir, "railroad_distance.tif"))
}

if (!file.exists(file.path(transportation_density_dir, "transmission_lines_distance.tif"))) {
  
  rasterize_shapefile(shp = tl, out_rst = 'transmission_lines.tif')
  transmission_lines_density <- get_density(out_pro = 'transmission_lines.tif', out_den = 'transmission_lines_density.tif')
  transmission_lines_distance <- get_distance(out_rst = 'transmission_lines.tif', out_dis = 'transmission_lines_distance.tif')
  
  system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix))
  
} else {
  transmission_lines_density <- raster(file.path(transportation_density_dir, "transmission_lines_density.tif"))
  transmission_lines_distance <- raster(file.path(transportation_dist_dir, "transmission_lines_distance.tif"))
}

if (!file.exists(file.path(transportation_density_dir, "primary_rds_distance.tif"))) {
  
  rasterize_shapefile(shp = primary_rds, out_rst = 'primary_rds.tif')
  primary_rds_density <- get_density(out_pro = 'primary_rds.tif', out_den = 'primary_rds_density.tif')
  primary_rds_distance <- get_distance(out_rst = 'primary_rds.tif', out_dis = 'primary_rds_distance.tif')
  
  system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix))
  
} else {
  primary_rds_density <- raster(file.path(transportation_density_dir, "primary_rds_density.tif")) 
  primary_rds_distance <- raster(file.path(transportation_dist_dir, "primary_rds_distance.tif")) 
}

if (!file.exists(file.path(transportation_density_dir, "secondary_rds_distance.tif"))) {
  
  rasterize_shapefile(shp = secondary_rds, out_rst = 'secondary_rds.tif')
  secondary_rds_density <- get_density(out_pro = 'secondary_rds.tif', out_den = 'secondary_rds_density.tif')
  secondary_rds_distance <- get_distance(out_rst = 'secondary_rds.tif', out_dis = 'secondary_rds_distance.tif')
  
  system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix))
  
} else {
  secondary_rds_density <- raster(file.path(transportation_density_dir, "secondary_rds_density.tif"))
  secondary_rds_distance <- raster(file.path(transportation_dist_dir, "secondary_rds_distance.tif"))
}

if (!file.exists(file.path(transportation_density_dir, "tertiary_rds_distance.tif"))) {

  rasterize_shapefile(shp = tertiary_rds, out_rst = 'tertiary_rds.tif')
  tertiary_rds_density <- get_density(out_pro = 'tertiary_rds.tif', out_den = 'tertiary_rds_density.tif')
  tertiary_rds_distance <- get_distance(out_rst = 'tertiary_rds.tif', out_dis = 'tertiary_rds_distance.tif')
  
}  else {
  tertiary_rds_density <- raster(file.path(transportation_density_dir, "tertiary_rds_density.tif"))
}

