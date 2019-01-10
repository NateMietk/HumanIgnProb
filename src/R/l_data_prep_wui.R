#Import the Wildland-Urban Interface and process
if(!file.exists(file.path(wui_proc_dir, 'wui_2010.tif'))) {
  if (!file.exists(file.path(wui_proc_dir, "wui_bounds.gpkg"))) {
    # st_layers(dsn = file.path(wui_prefix, "CONUS_WUI_cp12_d.gdb"))
    
    wui <- st_read(dsn = file.path(wui_prefix, "CONUS_WUI_cp12_d.gdb"),
                   layer = "CONUS_WUI_cp12") %>%
      st_transform(st_crs(usa_shp)) %>%
      mutate(Class90 = classify_wui(WUICLASS90),
             Class00 = classify_wui(WUICLASS00),
             Class10 = classify_wui(WUICLASS10)) 
    
    st_write(wui, file.path(wui_proc_dir, "wui_bounds.gpkg"),
             driver = "GPKG",
             delete_layer = TRUE)
    system(paste0("aws s3 sync ", prefix, " ", s3_base))

  } else {
    wui <- st_read(dsn = file.path(wui_proc_dir, "wui_bounds.gpkg"))
  }
  
  gridded_wui_1990 <- fasterize::fasterize(wui, raster_mask, field = "Class90")
  
  gridded_wui_1990  <- ratify(gridded_wui_1990)
  rat <- levels(gridded_wui_1990)[[1]]
  rat$Class90 <- levels(wui$Class90)
  levels(gridded_wui_1990) <- rat
  # levels(x)
  
  writeRaster(gridded_wui_1990, file.path(wui_proc_dir, 'wui_1990.tif'), format = 'GTiff')
  
  gridded_wui_2000 <- fasterize::fasterize(wui, raster_mask, field = "Class00")
  
  gridded_wui_2000  <- ratify(gridded_wui_2000)
  rat <- levels(gridded_wui_2000)[[1]]
  rat$Class00 <- levels(wui$Class00)
  levels(gridded_wui_2000) <- rat
  
  writeRaster(gridded_wui_2000, file.path(wui_proc_dir, 'wui_2000.tif'))
  
  gridded_wui_2010 <- fasterize::fasterize(wui, raster_mask, field = "Class10")
  
  gridded_wui_2010  <- ratify(gridded_wui_2010)
  rat <- levels(gridded_wui_2010)[[1]]
  rat$Class10 <- levels(wui$Class10)
  levels(gridded_wui_2010) <- rat
  
  writeRaster(gridded_wui_2010, file.path(wui_proc_dir, 'wui_2010.tif'))
  } else {
    wui_list <- list.files(wui_proc_dir, pattern = '.tif$', full.names = TRUE)
    gridded_wui <- raster::stack(wui_list)
    
    # ID      category
    # 1  0              
    # 2  1    High Urban
    # 3  2 Interface WUI
    # 4  3  Intermix WUI
    # 5  4     Low Urban
    # 6  5     Med Urban
    # 7  6         Other
    # 8  7           VLD
    # 9  8     Wildlands
    }
  
wui_90s_list <- list.files(wui_proc_dir, pattern = '1990*.tif$', full.names = TRUE)
decade_to_monthly(wui_90s_list, dir = anthro_monthly_proc_dir, dates = c(1992:1999))

wui_00s_list <- list.files(wui_proc_dir, pattern = '1990*.tif$', full.names = TRUE)
decade_to_monthly(wui_00s_list, dir = anthro_monthly_proc_dir, dates = c(2000:2009))

wui_10s_list <- list.files(wui_proc_dir, pattern = '1990*.tif$', full.names = TRUE)
decade_to_monthly(wui_10s_list, dir = anthro_monthly_proc_dir, dates = c(2010:2015))

system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix, ' --delete'))
