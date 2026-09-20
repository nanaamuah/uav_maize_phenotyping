# Genotype BLUEs and heritability estimates as flat tables
# Output: data/processed/blues.csv, data/processed/heritability.csv

library(here)
library(dplyr)


# Folder paths
processed_dir <- here("data", "processed")


# Read model results
yield_models <- readRDS(file.path(
  processed_dir, "yield_models.rds"
))
rgb_models <- readRDS(file.path(
  processed_dir, "rgb_models_20170420.rds"
))


# Collect adjusted genotype means
yield_blues <- bind_rows(
  lapply(yield_models, function(x) x$blues),
  .id = "environment"
) %>%
  mutate(date = NA_character_, trait = "grain_yield")

rgb_blues <- lapply(rgb_models, function(x) {
  bind_cols(x$info, x$blues)
}) %>%
  bind_rows()

blues <- bind_rows(yield_blues, rgb_blues)

# Later scripts read these two columns by name
if (!all(c("genotype", "predicted.values") %in% names(blues))) {
  stop("BLUE table lacks 'genotype' or 'predicted.values'; check the SpATS predict() output")
}

duplicates <- count(blues, environment, date, trait, genotype) %>% filter(n > 1)

if (nrow(duplicates) > 0) warning(sprintf("%d duplicated genotype BLUEs", nrow(duplicates)))

message("Genotype BLUEs by environment and trait:")
print(table(blues$trait, blues$environment))


# Collect heritability estimates
yield_h2 <- bind_rows(
  lapply(yield_models, function(x) {
    data.frame(heritability = unname(x$heritability))
  }),
  .id = "environment"
) %>%
  mutate(date = NA_character_, trait = "grain_yield")

rgb_h2 <- lapply(rgb_models, function(x) {
  mutate(x$info, heritability = unname(x$heritability))
}) %>%
  bind_rows()

heritability <- bind_rows(yield_h2, rgb_h2)

message("Generalized heritability:")
print(heritability, row.names = FALSE)


# Save tables
write.csv(
  blues, file.path(processed_dir, "blues.csv"),
  row.names = FALSE
)
write.csv(
  heritability, file.path(processed_dir, "heritability.csv"),
  row.names = FALSE
)
