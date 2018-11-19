
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

# Chip out boundaries
boundary_list <- list.files(bounds_monthly_dir, pattern = '.tif', full.names = TRUE)
chip_rasters(input_tiles = tile_list, var_list = boundary_list, out_dir = 'data/tiles/x_var/')

# Chip out terrain
terrain_list <- list.files(terrain_monthly_dir, pattern = '.tif', full.names = TRUE)
chip_rasters(input_tiles = tile_list, var_list = terrain_list, out_dir = 'data/tiles/x_var/')

# Chip out the climate
climate_mean_list <- list.files(fire_dir, pattern = '*.tif', full.names = TRUE, recursive = TRUE)
chip_rasters(input_tiles = tile_list, var_list = y_list, out_dir = 'data/tiles/x_var/')
