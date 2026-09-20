# Trial design and grain yield for the irrigated (G2FE) and rainfed (DG2F) trials
# Output: data/processed/trial_metadata.csv

library(here)
library(dplyr)


# Folder paths
uav_dir <- here("data", "raw", "uav")
processed_dir <- here("data", "processed")


# Read field notes
notes <- read.csv(file.path(uav_dir, "CS17_G2F_FieldNotes.csv"))

needed <- c("Test", "Barcode", "Pedigree", "Rep", "Range", "Row", "YieldMoist")
missing <- setdiff(needed, names(notes))

if (length(missing) > 0) {
  stop("Field notes are missing columns: ", paste(missing, collapse = ", "))
}

message("Plots per trial code in the field notes:")
print(table(notes$Test, useNA = "ifany"))


# Prepare trial metadata
trial <- notes %>%
  filter(Test %in% c("G2FE", "DG2F")) %>%
  transmute(
    plot_id = Barcode,
    genotype = Pedigree,
    environment = Test,
    replicate = Rep,
    range = Range,
    row = Row,
    yield = YieldMoist
  )


# Checks on the trial table
if (!all(c("G2FE", "DG2F") %in% trial$environment)) {
  stop("One of the two trial codes (G2FE, DG2F) is absent from the field notes")
}

if (anyDuplicated(trial$plot_id) > 0) {
  stop("Duplicate plot barcodes in the field notes; the polygon join needs a unique key")
}

if (!is.numeric(trial$yield)) {
  warning("YieldMoist was not read as numeric; check for text codes in the column")
}

if (!is.numeric(trial$range) || !is.numeric(trial$row)) {
  warning("Range or Row is not numeric; the spatial models need numeric coordinates")
}

message("Plots per environment:")
print(table(trial$environment))

message("Distinct genotypes per environment:")
print(tapply(trial$genotype, trial$environment, function(x) length(unique(x))))

message(sprintf(
  "Genotypes present in both environments: %d",
  length(intersect(
    trial$genotype[trial$environment == "G2FE"],
    trial$genotype[trial$environment == "DG2F"]
  ))
))

message(sprintf(
  "Plots with an empty pedigree: %d", sum(trial$genotype == "" | is.na(trial$genotype))
))

message("Number of genotypes by plots per genotype (rows: environment):")
print(with(count(trial, environment, genotype), table(environment, n)))

message("Plots without a yield value:")
print(tapply(is.na(trial$yield), trial$environment, sum))

message("Grain yield by environment:")
print(tapply(trial$yield, trial$environment, summary))

message(sprintf(
  "Field grid: ranges %s to %s, rows %s to %s",
  min(trial$range, na.rm = TRUE), max(trial$range, na.rm = TRUE),
  min(trial$row, na.rm = TRUE), max(trial$row, na.rm = TRUE)
))


# Save
write.csv(
  trial,
  file.path(processed_dir, "trial_metadata.csv"),
  row.names = FALSE
)
