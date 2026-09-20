# Attach trial design and yield to the plot-level UAV traits
# Output: data/processed/plot_data_20170420.csv

library(here)
library(dplyr)


# Folder paths
processed_dir <- here("data", "processed")


# Read inputs
traits <- read.csv(file.path(
  processed_dir, "rgb_plot_traits_20170420.csv"
))
trial <- read.csv(file.path(
  processed_dir, "trial_metadata.csv"
))

# Check the join key before joining
if (class(traits$plot_id) != class(trial$plot_id)) {
  warning(sprintf(
    "plot_id is %s in the traits table and %s in the trial table",
    class(traits$plot_id), class(trial$plot_id)
  ))
}

polygon_ids <- unique(traits$plot_id)
no_record <- setdiff(polygon_ids, trial$plot_id)
no_polygon <- setdiff(trial$plot_id, polygon_ids)

message(sprintf(
  "%d of %d polygons matched a field-note record", length(polygon_ids) - length(no_record),
  length(polygon_ids)
))
message(sprintf("%d field-note plots have no polygon", length(no_polygon)))

if (length(no_record) > 0) {
  message("First unmatched polygon identifiers:")
  print(head(no_record, 10))
}


# Attach trial metadata
plot_data <- traits %>%
  left_join(trial, by = "plot_id", relationship = "many-to-one")

if (nrow(plot_data) != nrow(traits)) stop("The join changed the number of rows")

message("Rows by environment and trait after the join (NA = unmatched):")
print(table(plot_data$environment, plot_data$trait, useNA = "ifany"))


# Save
write.csv(
  plot_data,
  file.path(processed_dir, "plot_data_20170420.csv"),
  row.names = FALSE
)
