
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
