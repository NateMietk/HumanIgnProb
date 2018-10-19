# Download and import CONUS states
# Download will only happen once as long as the file exists
if (!exists("usa_shp")){
  usa_shp <- load_data(url = "https://www2.census.gov/geo/tiger/GENZ2016/shp/cb_2016_us_state_20m.zip",
                       dir = us_prefix,
                       layer = "cb_2016_us_state_20m",
                       outname = "usa") %>%
    sf::st_transform(p4string_ea) %>%
    dplyr::filter(!STUSPS %in% c("HI", "AK", "PR")) %>%
    dplyr::select(STATEFP, STUSPS)
  usa_shp$STUSPS <- droplevels(usa_shp$STUSPS)
}

# Download and import the Level 4 Ecoregions data
# Download will only happen once as long as the file exists
if (!exists("ecoregions_l4")){
  ecoregions_l4 <- st_read(file.path(ecoregionl4_prefix, 'us_eco_l4_no_st.shp')) %>%
    sf::st_simplify(., preserveTopology = TRUE, dTolerance = 1000)  %>%
    sf::st_transform(st_crs(usa_shp))
}

# Download and import the Level 3 Ecoregions data
# Download will only happen once as long as the file exists
if (!exists("ecoregions_l3")){
  if (!file.exists(file.path(bounds_dir, "us_eco_l3.gpkg"))) {
    
    ecoregions_l3 <- st_read(dsn = ecoregion_prefix, layer = "us_eco_l3", quiet= TRUE) %>%
      st_transform(st_crs(usa_shp)) %>%  # e.g. US National Atlas Equal Area
      dplyr::select(US_L3CODE, US_L3NAME, NA_L2CODE, NA_L2NAME, NA_L1CODE, NA_L1NAME) %>%
      st_make_valid() %>%
      st_intersection(., usa_shp)  %>%
      setNames(tolower(names(.))) %>%
      mutate(region = as.factor(if_else(na_l1name %in% c("EASTERN TEMPERATE FORESTS",
                                                         "TROPICAL WET FORESTS",
                                                         "NORTHERN FORESTS"), "East",
                                        if_else(na_l1name %in% c("NORTH AMERICAN DESERTS",
                                                                 "SOUTHERN SEMI-ARID HIGHLANDS",
                                                                 "TEMPERATE SIERRAS",
                                                                 "MEDITERRANEAN CALIFORNIA",
                                                                 "NORTHWESTERN FORESTED MOUNTAINS",
                                                                 "MARINE WEST COAST FOREST"), "West", "Central"))),
             regions = as.factor(if_else(region == "East" & stusps %in% c("FL", "GA", "AL", "MS", "LA", "AR", "TN", "NC", "SC", "TX", "OK"), "South East",
                                         if_else(region == "East" & stusps %in% c("ME", "NH", "VT", "NY", "PA", "DE", "NJ", "RI", "CT", "MI", "MD",
                                                                                  "MA", "WI", "IL", "IN", "OH", "WV", "VA", "KY", "MO", "IA", "MN"), "North East",
    
                                                                                              as.character(region))))) 
    st_write(ecoregions_l3, file.path(bounds_dir, 'us_eco_l3.gpkg'),
             driver = 'GPKG', delete_layer = TRUE)
    
    east <- ecoregions_l3 %>%
      filter(region == 'East') %>%
      st_union()
    st_write(east, file.path(bounds_dir, 'east.gpkg'),
             driver = 'GPKG', delete_layer = TRUE)  
    
    west <- ecoregions_l3 %>%
      filter(region != 'East') %>%
      st_union()
    st_write(west, file.path(bounds_dir, 'west.gpkg'),
             driver = 'GPKG', delete_layer = TRUE)
    
    system(paste0("aws s3 sync ", bounds_dir, " ", s3_proc_bounds))
    
  } else {
    ecoregions_l3 <- sf::st_read(file.path(bounds_dir, 'us_eco_l3.gpkg'))
    east <- sf::st_read(file.path(bounds_dir, 'east.gpkg'))
    west <- sf::st_read(file.path(bounds_dir, 'west.gpkg'))
  }
}
    
# Create raster mask
# 4k Fishnet
if (!exists("fishnet_4k")) {
  if (!file.exists(file.path(fishnet_path, "fishnet_4k.gpkg"))) {
    fishnet_4k <- sf::st_make_grid(usa_shp, cellsize = 4000, what = 'polygons') %>%
      sf::st_sf('geometry' = ., data.frame('fishid4k' = 1:length(.))) %>%
      sf::st_intersection(., st_union(usa_shp))
    
    sf::st_write(fishnet_4k,
                 file.path(fishnet_path, "fishnet_4k.gpkg"),
                 driver = "GPKG")
    
    system(paste0("aws s3 sync ",
                  fishnet_path, " ",
                  s3_anc_prefix, "fishnet"))
  } else {
    fishnet_4k <- sf::st_read(file.path(fishnet_path, "fishnet_4k.gpkg"))
  }
}

# Create voxel
# 4k hexagonal fishnet
# if (!exists("hexnet_4k")) {
#   if (!file.exists(file.path(fishnet_path, "hexnet_4k.gpkg"))) {
#     hex_points <- spsample(as(usa_shp, 'Spatial'), type = "hexagonal", cellsize = 4000)
#     hex_grid <- HexPoints2SpatialPolygons(hex_points, dx = 4000)
#     hexnet_4k <- st_as_sf(hex_grid) %>%
#       mutate(hexid4k = row_number()) %>%
#       st_intersection(., st_union(usa_shp)) %>%
#       st_join(., usa_shp, join = st_intersects) %>%
#       dplyr::select(hexid4k, STUSPS)
# 
#     sf::st_write(hexnet_4k,
#                  file.path(fishnet_path, "hexnet_4k.gpkg"),
#                  driver = "GPKG")
# 
#     system(paste0("aws s3 sync ",
#                   fishnet_path, " ",
#                   s3_anc_prefix, "fishnet"))
#   } else {
#     hexnet_4k <- sf::st_read(file.path(fishnet_path, "hexnet_4k.gpkg"))
# 
#   }
# }
