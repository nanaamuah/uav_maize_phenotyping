# Plot polygons for both trials, with and without an inward buffer
# Output: data/processed/plot_polygons.gpkg (layers "original" and "buffered")

library(here)
library(sf)
library(dplyr)


# Folder paths
shape_dir <- here("data", "raw", "uav", "shapefiles")
processed_dir <- here("data", "processed")


# Read and combine plots
rainfed <- st_read(file.path(shape_dir, "CS17-DG2F.shp"))
irrigated <- st_read(file.path(shape_dir, "CS17-G2FE.shp"))

# Check the layers before combining them
if (!all(c("id" %in% names(rainfed), "id" %in% names(irrigated)))) {
  stop("The shapefiles have no 'id' column; inspect the attribute tables")
}

# st_set_crs() below only relabels the CRS; it does not reproject
for (layer in list(rainfed, irrigated)) {
  if (!is.na(st_crs(layer)) && st_crs(layer) != st_crs(32614)) {
    warning("A shapefile carries a CRS other than EPSG:32614; reproject it before relabelling")
  }
}

message(sprintf(
  "Polygons read: %d rainfed (DG2F), %d irrigated (G2FE)", nrow(rainfed), nrow(irrigated)
))

plots <- bind_rows(rainfed, irrigated) %>%
  rename(plot_id = id) %>%
  st_set_crs(32614)

if (anyDuplicated(plots$plot_id) > 0) {
  stop("Duplicate plot identifiers across the two shapefiles")
}

if (!all(st_is_valid(plots))) {
  warning(sprintf("%d invalid polygon geometries", sum(!st_is_valid(plots))))
}


# Reduce plot-edge influence
buffered <- st_buffer(plots, dist = -0.20)

# A negative buffer larger than half the plot width empties the polygon
if (any(st_is_empty(buffered))) {
  warning(sprintf("%d polygons are empty after buffering", sum(st_is_empty(buffered))))
}

message(sprintf(
  "Median plot area: %.2f m2 before and %.2f m2 after the 0.20 m inward buffer",
  median(as.numeric(st_area(plots))), median(as.numeric(st_area(buffered)))
))


# Save both polygon layers
st_write(
  plots, file.path(processed_dir, "plot_polygons.gpkg"),
  layer = "original", delete_layer = TRUE
)

st_write(
  buffered, file.path(processed_dir, "plot_polygons.gpkg"),
  layer = "buffered", delete_layer = TRUE
)
