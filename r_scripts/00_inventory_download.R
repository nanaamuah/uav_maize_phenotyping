# Inventory of the raw files that the pipeline reads
# Output: data/processed/file_inventory.csv

library(here)


# Folder paths
raw_dir <- here("data", "raw")
processed_dir <- here("data", "processed")

# Create the output folder on a fresh clone
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

# Inventory
files <- list.files(raw_dir, recursive = TRUE, full.names = TRUE)

if (length(files) == 0) stop("data/raw/ is empty")

inventory <- data.frame(
  file = substring(files, nchar(raw_dir) + 2),
  size_mb = round(file.info(files)$size / 1024^2, 2)
)

# Check that every file read by later scripts is present
required <- c(
  "uav/CS17_G2F_FieldNotes.csv",
  "uav/shapefiles/CS17-DG2F.shp",
  "uav/shapefiles/CS17-G2FE.shp",
  "uav/20170420_FW_RGB/CS17_G2F_20170420_FW_RGB_Mosaic.tif"
)
missing <- setdiff(required, inventory$file)

if (length(missing) > 0) {
  stop("Missing raw files:\n", paste(missing, collapse = "\n"))
}

message(sprintf(
  "%d raw files found, %.1f MB in total", nrow(inventory), sum(inventory$size_mb)
))
message("Largest files:")
print(head(inventory[order(-inventory$size_mb), ], 10), row.names = FALSE)


# Save
write.csv(
  inventory,
  file.path(processed_dir, "file_inventory.csv"),
  row.names = FALSE
)
