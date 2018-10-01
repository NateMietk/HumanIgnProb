
## Create distnace rasters -----
if (!exists("ras_mask")) {
  if (!file.exists(file.path(ancillary_dir, "ras_mask/ras_mask.tif"))) {
    if (!exists("fishnet_4k")) {
      fishnet_4k <- st_read(file.path(fishnet_path, "fishnet_4k.gpkg"))
    }
    ras_mask <- fishnet_4k %>%
      st_transform(p4string_ed)
    ras_mask <- raster(as(ras_mask, "Spatial"), res = 4000)
  }
}

# Calculate distance to power lines
if (!file.exists(file.path(transportation_dist_dir, "dis_transmission_lines.tif"))) {
  tl_ed <- tl %>%
    st_transform(p4string_ed)
  
  sfInit(parallel = TRUE, cpus = ncor)
  sfExport(list = c("ncor", "usa_ed", "tl_ed", "ras_mask"))
  tl_rst <- sfLapply(1:ncor, shp_rst, y = tl_ed, lvl = "bool_tl", j = ras_mask)
  sfStop()
  dis_transmission_lines <- combine_rst(tl_rst)
  writeRaster(dis_transmission_lines, filename = file.path(transportation_dist_dir, paste0("dis_transmission_lines", ".tif")),
              format = "GTiff", overwrite=TRUE)
} else {
  dis_transmission_lines <- raster(filename = file.path(transportation_dist_dir, paste0("dis_transmission_lines", ".tif")))
}


# Calculate distance to railroads
if (!file.exists(file.path(transportation_dist_dir, "dis_railroads.tif"))) {
  
  rail_rds_ed <- rail_rds %>%
    st_transform(p4string_ed)
  
  sfInit(parallel = TRUE, cpus = ncor)
  
  sfExport(list = c("ncor", "usa_shp", "rail_rds_ed", "ras_mask"))
  rail_rst <- sfLapply(1:ncor, shp_rst, y = rail_rds_ed, lvl = "bool_rrds", j = ras_mask)
  sfStop()
  dis_railroads <- combine_rst(rail_rst)
  writeRaster(dis_railroads, filename = file.path(transportation_dist_dir, paste0("dis_railroads", ".tif")),
              format = "GTiff")
} else {
  dis_railroads <- raster(filename = file.path(transportation_dist_dir, paste0("dis_railroads", ".tif")))
}


# Calculate distance to primary roads
if (!file.exists(file.path(transportation_dist_dir, "dis_primary_rds.tif"))) {
  
  primary_rds_ed <- primary_rds %>%
    st_transform(p4string_ed)
  
  sfInit(parallel = TRUE, cpus = ncor)
  sfExport(list = c("ncor", "usa_shp", "primary_rds_ed", "ras_mask"))
  prds_rst <- sfLapply(1:ncor, shp_rst, y = primary_rds_ed, lvl = "bool_prds", j = ras_mask)
  sfStop()
  dis_primary_rds <- combine_rst(prds_rst)
  writeRaster(dis_primary_rds, filename = file.path(transportation_dist_dir, paste0("dis_primary_rds", ".tif")),
              format = "GTiff", overwrite=TRUE)
} else {
  dis_primary_rds <- raster(filename = file.path(transportation_dist_dir, paste0("dis_primary_rds", ".tif")))
}

# Calculate distance to secondary roads
if (!file.exists(file.path(transportation_dist_dir, "dis_secondary_rds.tif"))) {
  
  secondary_rds_ed <- secondary_rds %>%
    st_transform(p4string_ed)
  
  sfInit(parallel = TRUE, cpus = ncor)
  sfExport(list = c("ncor", "usa_shp", "secondary_rds_ed", "ras_mask"))
  srds_rst <- sfLapply(1:ncor, shp_rst, y = secondary_rds_ed, lvl = "bool_srds", j = ras_mask)
  sfStop()
  dis_secondary_rds <- combine_rst(srds_rst)
  writeRaster(dis_secondary_rds, filename = file.path(transportation_dist_dir, paste0("dis_secondary_rds", ".tif")),
              format = "GTiff", overwrite=TRUE)
} else {
  dis_secondary_rds <- raster(filename = file.path(transportation_dist_dir, paste0("dis_secondary_rds", ".tif")))
}

# Calculate distance to tertiary roads
if (!file.exists(file.path(transportation_dist_dir, "dis_tertiary_rds.tif"))) {
  
  tertiary_rds_ed <- tertiary_rds %>%
    st_transform(p4string_ed)
  
  sfInit(parallel = TRUE, cpus = ncor)
  sfExport(list = c("ncor", "usa_shp", "tertiary_rds_ed", "ras_mask"))
  srds_rst <- sfLapply(1:ncor, shp_rst, y = tertiary_rds_ed, lvl = "bool_srds", j = ras_mask)
  sfStop()
  dis_tertiary_rds <- combine_rst(srds_rst)
  writeRaster(dis_tertiary_rds, filename = file.path(transportation_dist_dir, paste0("dis_tertiary_rds", ".tif")),
              format = "GTiff", overwrite=TRUE)
} else {
  dis_tertiary_rds <- raster(filename = file.path(transportation_dist_dir, paste0("dis_tertiary_rds", ".tif")))
}

## Create distance from ignition point -----

transportation_inputs <- list('rail_rds', 'tl', 'primary_rds', 'secondary_rds', 'tertiary_rds')

distance_to_fire_list <- lapply(transportation_inputs, 
                                FUN = function(x) { 
                                  
                                  lines <- get(x) %>%
                                    mutate(line_ids = row_number())
                                  
                                  line_coords <- st_coordinates(lines)
                                  fire_coords <- st_coordinates(fpa_clean)
                                  
                                  line_df <- as_tibble(line_coords) %>%
                                    mutate(vertex_ids = row_number())
                                  
                                  # compute KNN between fires and urban poly vertices
                                  nearest_neighbors <- as_tibble(bind_cols(nabor::knn(data = line_coords[, c('X', 'Y')],
                                                                                      fire_coords,
                                                                                      k = 1))) %>%
                                    mutate(fpa_id = as.data.frame(fpa_clean)$fpa_id,
                                           vertex_ids = nn.idx,
                                           closest_centroid = as.numeric(nn.dists)) %>%
                                    left_join(., line_df, by = 'vertex_ids') %>%
                                    mutate(line_ids = L1) %>%
                                    dplyr::select(fpa_id, vertex_ids, line_ids, closest_centroid) %>%
                                    left_join(., lines, by = 'line_ids') %>%
                                    st_as_sf(sf_column_name = "geom") %>%
                                    arrange(desc(fpa_id)) 
                                  
                                  distance_to_fire <- fpa_clean %>%
                                    arrange(desc(fpa_id)) %>%
                                    mutate(
                                      !!paste0('distance_to_', x) := st_distance(
                                        st_geometry(nearest_neighbors),
                                        st_geometry(.), by_element = TRUE)) %>%
                                    dplyr::select(fpa_id, !!paste0('distance_to_', x))
                                  
                                  write_rds(distance_to_fire,
                                            file.path(
                                              transportation_dist_dir,
                                              paste0('distance_fpa_', x, '.rds')
                                            ))
                                  system(paste0('aws s3 sync ', transportation_dist_dir, ' ', s3_proc_prefix))
                                } 
)

distance_to_fire <- distance_to_fire_list %>%
  bind_cols() %>%
  dplyr::select(fpa_id, distance_to_rail_rds, distance_to_tl, distance_to_primary_rds, distance_to_secondary_rds, distance_to_tertiary_rds, shape)

st_write(distance_to_fire,
         file.path(
           anthro_extract,
           paste0('distance_fpa_to_transportation', '.gpkg')
         ))
system(paste0('aws s3 sync ', summary_dir, ' ', s3_proc_extractions))