# Plot-level canopy cover and index means for 20 April 2017
# Output: data/processed/rgb_plot_traits_20170420.csv

library(here)
library(terra)
library(tidyr)


# Folder paths
processed_dir <- here("data", "processed")


# Read inputs
indices <- rast(file.path(
  processed_dir, "rgb_indices_20170420.tif"
))
plots <- vect(
  file.path(processed_dir, "plot_polygons.gpkg"),
  layer = "buffered"
)


# Separate vegetation from background
cover <- ifel(indices[["ExG"]] > 0, 1, 0)
names(cover) <- "canopy_cover"

vegetation <- mask(indices, cover, maskvalues = 0)

message(sprintf(
  "Share of sampled cells classed as vegetation (ExG > 0): %.1f%%",
  100 * mean(spatSample(cover, 1e5, method = "random", na.rm = TRUE)[[1]])
))


# Extract plot means
traits <- terra::extract(
  c(cover, vegetation), plots,
  fun = mean, na.rm = TRUE, exact = TRUE, ID = FALSE
)

if (nrow(traits) != nrow(plots)) stop("Extraction returned a different number of rows than polygons")

traits <- data.frame(
  plot_id = plots$plot_id,
  date = "2017-04-20",
  traits
)

# Plots with no vegetation cells return NaN for the index means
message(sprintf("Plots with zero canopy cover: %d", sum(traits$canopy_cover == 0, na.rm = TRUE)))

if (any(traits$canopy_cover < 0 | traits$canopy_cover > 1, na.rm = TRUE)) {
  warning("Canopy cover outside 0 to 1; check the cover layer")
}

traits <- pivot_longer(
  traits,
  cols = c(canopy_cover, ExG, GLI, VARI),
  names_to = "trait",
  values_to = "value"
)

message("Plot values by trait (missing or non-finite values counted separately):")
print(do.call(rbind, lapply(split(traits$value, traits$trait), function(x) {
  c(summary(x[is.finite(x)]), non_finite = sum(!is.finite(x)))
})))


# Save
write.csv(
  traits,
  file.path(processed_dir, "rgb_plot_traits_20170420.csv"),
  row.names = FALSE
)
