
if (!file.exists(file.path(transportation_density_dir, "railroad_density.gpkg"))) {
  
  railroad_fish <- rail_rds %>%
    dplyr::select(LINEARID) %>%
    st_join(., fishnet_4k, join = st_intersects) %>%
    dplyr::select(LINEARID, fishid4k)
  
  unique_fishid <- unique(railroad_fish$fishid4k)
  
  pboptions(type = 'txt', use_lb = TRUE)
  cl <- makeCluster(getOption("cl.cores", detectCores()))
  
  railroad_density <- pblapply(unique_fishid,
                               FUN = get_density,
                               grids = fishnet_4k,
                               lines = railroad_fish,
                               cl = cl)
  stopCluster(cl)
  
  railroad_density_all <- do.call(rbind, railroad_density)
  
  st_write(railroad_density_all, file.path(transportation_density_dir, "railroad_density.gpkg"),
           delete_layer = TRUE)
  
  system(paste0("aws s3 sync ",  processed_dir, " ", s3_proc_prefix))
  
} else {
  railroad_density <- st_read(file.path(transportation_density_dir, "railroad_density.gpkg"))
}

if (!file.exists(file.path(transportation_density_dir, "transmission_lines_density.gpkg"))) {
  
  transmission_lines_fish <- tl %>%
    dplyr::select(OBJECTID) %>%
    st_join(., fishnet_4k, join = st_intersects) %>%
    dplyr::select(OBJECTID, fishid4k)
  
  unique_fishid <- unique(transmission_lines_fish$fishid4k)
  
  pboptions(type = 'txt', use_lb = TRUE)
  cl <- makeCluster(getOption('cl.cores', parallel::detectCores()))
  
  transmission_lines_density <- pblapply(unique_fishid,
                                         FUN = get_density,
                                         grids = fishnet_4k,
                                         lines = transmission_lines_fish,
                                         cl = cl)
  stopCluster(cl)
  
  
  transmission_lines_density_all <- do.call(rbind, transmission_lines_density)
  
  st_write(transmission_lines_density_all, file.path(transportation_density_dir, "transmission_lines_density.gpkg"))
  
  system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix))
  
} else {
  transmission_lines_density_all <- st_read(file.path(transportation_density_dir, "transmission_lines_density.gpkg"))
}

if (!file.exists(file.path(transportation_density_dir, "primary_rds_density.gpkg"))) {
  
  primary_fish <- primary_rds %>%
    dplyr::select(LINEARID) %>%
    st_join(., fishnet_4k, join = st_intersects) %>%
    dplyr::select(LINEARID, fishid4k)
  
  unique_fishid <- unique(primary_fish$fishid4k)
  
  pboptions(type = 'txt', use_lb = TRUE)
  cl <- makeCluster(getOption('cl.cores', 1))
  
  primary_rds_density <- pblapply(unique_fishid,
                                  FUN = get_density,
                                  grids = fishnet_4k,
                                  lines = primary_fish,
                                  cl = cl)
  stopCluster(cl)
  
  primary_rds_density_all <- do.call(rbind, primary_rds_density)
  
  st_write(primary_rds_density_all, file.path(transportation_density_dir, "primary_rds_density.gpkg"))
  
  system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix))
  
} else {
  primary_rds_density_all <- st_read(file.path(transportation_density_dir, "primary_rds_density.gpkg"))
}

if (!file.exists(file.path(transportation_density_dir, "secondary_rds_density.gpkg"))) {
  
  secondary_fish <- secondary_rds %>%
    dplyr::select(LINEARID) %>%
    st_join(., fishnet_4k, join = st_intersects) %>%
    dplyr::select(LINEARID, fishid4k)
  
  
  unique_fishid <- unique(secondary_fish$fishid4k)
  
  pboptions(type = 'txt', use_lb = TRUE)
  cl <- makeCluster(getOption('cl.cores', parallel::detectCores()))
  
  secondary_rds_density <- pblapply(unique_fishid,
                                    FUN = get_density,
                                    grids = fishnet_4k,
                                    lines = secondary_fish,
                                    cl = cl)
  stopCluster(cl)
  
  secondary_rds_density_all <- do.call(rbind, secondary_rds_density)
  
  st_write(secondary_rds_density_all, file.path(transportation_density_dir, "secondary_rds_density.gpkg"))
  
  system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix))
  
} else {
  secondary_rds_density_all <- st_read(file.path(transportation_density_dir, "secondary_rds_density.gpkg"))
}

if (!file.exists(file.path(transportation_density_dir, "tertiary_rds_density.gpkg"))) {
  
  tertiary_fish <- tertiary_rds %>%
    dplyr::select(LINEARID) %>%
    st_join(., fishnet_4k, join = st_intersects) %>%
    dplyr::select(LINEARID, fishid4k)
  
  unique_fishid <- unique(tertiary_fish$fishid4k)
  
  pboptions(type = 'txt', use_lb = TRUE)
  
  tertiary_rds_density <- pblapply(unique_fishid,
                                   FUN = get_density,
                                   grids = fishnet_4k,
                                   lines = tertiary_fish)
  
  tertiary_rds_density_all <-  do.call(rbind, tertiary_rds_density) 
  
  st_write(tertiary_rds_density_all, file.path(transportation_density_dir, "tertiary_rds_density.gpkg"))
  
  system(paste0("aws s3 sync ", processed_dir, " ", s3_proc_prefix))
}  else {
  tertiary_rds_density_all <- st_read(file.path(transportation_density_dir, "tertiary_rds_density.gpkg"))
}

