# RGB vegetation indices from the 20 April 2017 fixed-wing mosaic
# Output: data/processed/rgb_indices_20170420.tif (layers ExG, GLI, VARI)

library(here)
library(terra)


# Folder paths
rgb_dir <- here("data", "raw", "uav", "20170420_FW_RGB")
processed_dir <- here("data", "processed")


# Read inputs
rgb <- rast(file.path(
  rgb_dir, "CS17_G2F_20170420_FW_RGB_Mosaic.tif"
))
plots <- vect(
  file.path(processed_dir, "plot_polygons.gpkg"),
  layer = "buffered"
)

# Check the mosaic against the polygons before cropping
message(sprintf(
  "Mosaic: %d layers (%s), cell size %s m",
  nlyr(rgb), paste(names(rgb), collapse = ", "), paste(round(res(rgb), 3), collapse = " x ")
))

if (nlyr(rgb) < 3) stop("The mosaic has fewer than three bands")

if (!same.crs(rgb, plots)) stop("The mosaic and the plot polygons use different CRS")

outside <- !is.related(plots, as.polygons(ext(rgb), crs = crs(rgb)), "within")

if (any(outside)) {
  warning(sprintf("%d plot polygons fall partly or wholly outside the mosaic", sum(outside)))
}

# Layers 1 to 3 are assumed to be red, green and blue in that order
rgb <- crop(rgb[[1:3]], plots)

message("Band value ranges after cropping:")
print(global(rgb, "range", na.rm = TRUE))


# Normalize colour channels
total <- rgb[[1]] + rgb[[2]] + rgb[[3]]
total <- ifel(total == 0, NA, total)

red <- rgb[[1]] / total
green <- rgb[[2]] / total
blue <- rgb[[3]] / total


# Calculate indices
exg <- 2 * green - red - blue
gli <- exg / (2 * green + red + blue)

denominator <- green + red - blue
vari <- (green - red) / ifel(denominator == 0, NA, denominator)

indices <- c(exg, gli, vari)
names(indices) <- c("ExG", "GLI", "VARI")

# ExG lies between -1 and 2 and GLI between -1 and 1; VARI can spike where
# its denominator is close to zero, so its tails are worth a look
message("Index quantiles from a random sample of 100,000 cells:")
print(sapply(
  spatSample(indices, 1e5, method = "random", na.rm = TRUE),
  quantile, probs = c(0, 0.01, 0.5, 0.99, 1), na.rm = TRUE
))

# Visual check of polygon alignment on the mosaic (interactive sessions only)
if (interactive()) {
  window <- ext(plots[1:20])
  plotRGB(crop(rgb, window), stretch = "lin")
  lines(plots, col = "yellow")
}


# Save
writeRaster(
  indices,
  file.path(processed_dir, "rgb_indices_20170420.tif"),
  overwrite = TRUE
)
