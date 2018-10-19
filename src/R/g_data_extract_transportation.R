
## Create distance and density extractions from ignition point -----

transportation_inputs <- list('railroad', 'transmission_lines', 'primary_rds', 'secondary_rds', 'tertiary_rds')

fpa_slim <- fpa_clean %>%
  dplyr::select(fpa_id)

rst_list1 <- list.files(transportation_dist_dir, pattern = '.tif$', full.names = TRUE)
rst_list2 <- list.files(transportation_density_dir, pattern = '.tif$', full.names = TRUE)
rst_list <- append(rst_list1, rst_list2)

rst <- raster::stack(rst_list) %>%
  mask(usa_shp)

transportation_df <- raster::extract(rst, as(fpa_slim, 'Spatial'), sp=TRUE) %>%
  st_as_sf()

st_write(transportation_df, file.path(summary_dir, 'fpa_transportation_extract.gpkg'))
