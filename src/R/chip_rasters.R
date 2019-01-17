
# Create tiles 256x256 with 64 pixel overlap
# The naming convention has a prefix of 't' for tile before the tile number
if(length(list.files('data/tiles/chip_256xy_64o', pattern = '*.tif', full.names = TRUE, recursive = TRUE)) != 150) {
  tiling(raster_mask, tilesize = 256, overlapping = 64, 
       asfiles = TRUE, tilename = "t", tiles_folder = 'data/tiles/chip_256xy_64o') 
  tile_list <- list.files('data/tiles/chip_256xy_64o', pattern = '*.tif', full.names = TRUE, recursive = TRUE)
} else {
  tile_list <- list.files('data/tiles/chip_256xy_64o', pattern = '*.tif', full.names = TRUE, recursive = TRUE)
}
 
# Chip out the dependent variables (y)
y_list <- list.files(fire_dir, pattern = '*.tif', full.names = TRUE, recursive = TRUE)
chip_rasters(input_tiles = tile_list, var_list = y_list, out_dir = 'data/tiles/y_var/')
system(paste0("aws s3 sync data/tiles s3://earthlab-modeling-human-ignitions/tiles"))

# Chip out boundaries
boundary_list <- list.files(bounds_monthly_dir, pattern = '.tif', full.names = TRUE)
chip_rasters(input_tiles = tile_list, var_list = boundary_list, out_dir = 'data/tiles/x_var/')
system(paste0("aws s3 sync data/tiles s3://earthlab-modeling-human-ignitions/tiles"))

# Chip out terrain
terrain_list <- list.files(terrain_monthly_dir, pattern = '.tif', full.names = TRUE)
chip_rasters(input_tiles = tile_list, var_list = terrain_list, out_dir = 'data/tiles/x_var/')
system(paste0("aws s3 sync data/tiles s3://earthlab-modeling-human-ignitions/tiles"))

# Chip out transportation
transportation_list <- list.files(transport_monthly_proc_dir, pattern = '.tif', full.names = TRUE)
chip_rasters(input_tiles = tile_list, var_list = transportation_list, out_dir = 'data/tiles/x_var/')
system(paste0("aws s3 sync data/tiles s3://earthlab-modeling-human-ignitions/tiles"))

# Chip out anthro
anthro_list <- list.files(anthro_monthly_proc_dir, pattern = '.tif', full.names = TRUE)
chip_rasters(input_tiles = tile_list, var_list = anthro_list, out_dir = 'data/tiles/x_var/')
system(paste0("aws s3 sync data/tiles s3://earthlab-modeling-human-ignitions/tiles"))

# Use this to parse out the dates interested within the climate folders
year_pattern <- paste0(rep(1992:2015), sep = '|', collapse="") %>%
  str_sub(., 1, str_length(.)-1)

# Chip out the climate - mean
climate_list <- list.files(file.path(proc_climate_dir, 'mean'), pattern = c(year_pattern), full.names = TRUE, recursive = TRUE)
chip_rasters(input_tiles = tile_list, var_list = climate_list, out_dir = 'data/tiles/x_var/')
system(paste0("aws s3 sync data/tiles s3://earthlab-modeling-human-ignitions/tiles"))

# Chip out the climate - numdays95th
climate_list <- list.files(file.path(proc_climate_dir, 'numdays95th'), pattern = c(year_pattern), full.names = TRUE, recursive = TRUE)
chip_rasters(input_tiles = tile_list, var_list = climate_list, out_dir = 'data/tiles/x_var/')
system(paste0("aws s3 sync data/tiles s3://earthlab-modeling-human-ignitions/tiles"))

# Chip out the climate - 95th
climate_list <- list.files(file.path(proc_climate_dir, '95th'), pattern = c(year_pattern), full.names = TRUE, recursive = TRUE)
chip_rasters(input_tiles = tile_list, var_list = climate_list, out_dir = 'data/tiles/x_var/')
system(paste0("aws s3 sync data/tiles s3://earthlab-modeling-human-ignitions/tiles"))
