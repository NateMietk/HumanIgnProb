census_list <- list.files(proc_gridded_census, full.names = TRUE)

if(length(census_list) != 19) {
  anthro_list <- list.files(file.path(anthro_dir, 'gridded_census'),
                            pattern = '*.tif', full.names = TRUE, recursive = TRUE)

  pboptions(type = 'txt', use_lb = TRUE)
  cl <- makeCluster(getOption("cl.cores", detectCores()/2)) # 8 cores on a m5d.4xlarge instance
  
  pblapply(anthro_list, function(x, rst_mask, masks, dir) {
    require(tidyverse)
    require(raster)
    
    names <- x %>%
      basename()
    if(!file.exists(file.path(dir, names))) {
      rst <- raster::raster(x) %>%
        raster::projectRaster(., rst_mask, method = 'bilinear') %>%
        raster::mask(masks)
      
      writeRaster(rst, file.path(dir, names))
    }
  }, 
  rst_mask = raster_mask, 
  masks = as(usa_shp, 'Spatial'),
  dir = proc_gridded_census, 
  cl = cl)
  
  stopCluster(cl)
} 

# Interpolate bachelor degree
if(length(list.files(proc_gridded_census, pattern = 'bachelordegree')) != 3) {
  usba_list <- list.files(proc_gridded_census, pattern = 'usba', full.names = TRUE)
  usba_rst <- raster::stack(usba_list[2], usba_list[1])
  usba_int <- interpolateTemporal(s = usba_rst, xin = c(1990, 2000), xout = c(1990, 2000, 2010),
                                  outdir = proc_gridded_census, prefix = 'bachelordegree', writechange = FALSE,
                                  progress = TRUE, returnstack = TRUE)
  unlink(usba_list)
}

# Interpolate high school degree
if(length(list.files(proc_gridded_census, pattern = 'highschooldegree')) != 3) {
  ushs_list <- list.files(proc_gridded_census, pattern = 'ushs', full.names = TRUE)
  ushs_rst <- raster::stack(ushs_list[2], ushs_list[1])
  ushs_int <- interpolateTemporal(s = ushs_rst, xin = c(1990, 2000), xout = c(1990, 2000, 2010),
                                  outdir = proc_gridded_census, prefix = 'highschooldegree', writechange = FALSE,
                                  progress = TRUE, returnstack = TRUE)
  unlink(ushs_list)
}

# Interpolate housing units
if(length(list.files(proc_gridded_census, pattern = 'housingunits')) != 3) {
  ushu_list <- list.files(proc_gridded_census, pattern = 'ushu', full.names = TRUE)
  ushu_rst <- raster::stack(ushu_list[3], ushu_list[1], ushu_list[2])
  ushu_int <- interpolateTemporal(s = ushu_rst, xin = c(1990, 2000, 2010), xout = c(1990, 2000, 2010),
                                  outdir = proc_gridded_census, prefix = 'housingunits', writechange = FALSE,
                                  progress = TRUE, returnstack = TRUE)
  unlink(ushu_list)
}

# Interpolate population below the poverty line
if(length(list.files(proc_gridded_census, pattern = 'poppoverty')) != 3) {
  uslowi_list <- list.files(proc_gridded_census, pattern = 'uslowi', full.names = TRUE)
  uslowi_rst <- raster::stack(uslowi_list[2], uslowi_list[1])
  uslowi_int <- interpolateTemporal(s = uslowi_rst, xin = c(1990, 2000), xout = c(1990, 2000, 2010),
                                  outdir = proc_gridded_census, prefix = 'poppoverty', writechange = FALSE,
                                  progress = TRUE, returnstack = TRUE)
  unlink(uslowi_list)
}

# Interpolate population 
if(length(list.files(proc_gridded_census, pattern = 'population')) != 3) {
  uspop_list <- list.files(proc_gridded_census, pattern = 'uspop', full.names = TRUE)
  uspop_rst <- raster::stack(uspop_list[3], uspop_list[1], uspop_list[2])
  uspop_int <- interpolateTemporal(s = uspop_rst, xin = c(1990, 2000, 2010), xout = c(1990, 2000, 2010),
                                    outdir = proc_gridded_census, prefix = 'population', writechange = FALSE,
                                    progress = TRUE, returnstack = TRUE)
  unlink(uspop_list)
}

# Interpolate poverty below 200 pct 
if(length(list.files(proc_gridded_census, pattern = 'pov200pct')) != 3) {
  uspov_list <- list.files(proc_gridded_census, pattern = 'uspov', full.names = TRUE)
  uspov_rst <- raster::stack(uspov_list[2], uspov_list[1])
  uspov_int <- interpolateTemporal(s = uspov_rst, xin = c(1990, 2000), xout = c(1990, 2000, 2010),
                                   outdir = proc_gridded_census, prefix = 'pov200pct', writechange = FALSE,
                                   progress = TRUE, returnstack = TRUE)
  unlink(uspov_list)
}

# Interpolate poverty below 50 pct 
if(length(list.files(proc_gridded_census, pattern = 'pov50pct')) != 3) {
  ussevp_list <- list.files(proc_gridded_census, pattern = 'ussevp', full.names = TRUE)
  ussevp_rst <- raster::stack(ussevp_list[2], ussevp_list[1])
  ussevp_int <- interpolateTemporal(s = ussevp_rst, xin = c(1990, 2000), xout = c(1990, 2000, 2010),
                                   outdir = proc_gridded_census, prefix = 'pov50pct', writechange = FALSE,
                                   progress = TRUE, returnstack = TRUE)
  unlink(ussevp_list)
}

# Interpolate seasonal housing units
if(length(list.files(proc_gridded_census, pattern = 'seasonalhomes')) != 3) {
  ussea_list <- list.files(proc_gridded_census, pattern = 'ussea', full.names = TRUE)
  ussea_rst <- raster::stack(ussea_list[3], ussea_list[1], ussea_list[2])
  ussea_int <- interpolateTemporal(s = ussea_rst, xin = c(1990, 2000, 2010), xout = c(1990, 2000, 2010),
                                    outdir = proc_gridded_census, prefix = 'seasonalhomes', writechange = FALSE,
                                    progress = TRUE, returnstack = TRUE)
  unlink(ussea_list)
}

census_90s_list <- list.files(proc_gridded_census, pattern = '1990', full.names = TRUE)
decade_to_monthly(census_90s_list, dir = anthro_monthly_proc_dir, dates = c(1992:1999))

census_00s_list <- list.files(proc_gridded_census, pattern = '2000', full.names = TRUE)
decade_to_monthly(census_00s_list, dir = anthro_monthly_proc_dir, dates = c(2000:2009))

census_10s_list <- list.files(proc_gridded_census, pattern = '2010', full.names = TRUE)
decade_to_monthly(census_10s_list, dir = anthro_monthly_proc_dir, dates = c(2010:2015))

system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix, ' --delete'))
