# Irrigated (G2FE) against rainfed (DG2F) genotype means
# Output: data/processed/treatment_comparison.csv, data/processed/yield_response.csv

library(here)
library(dplyr)
library(tidyr)


# Folder paths
processed_dir <- here("data", "processed")


# Read adjusted means
blues <- read.csv(file.path(processed_dir, "blues.csv"))

if (!all(c("G2FE", "DG2F") %in% blues$environment)) {
  stop("blues.csv does not hold both environments")
}


# Match genotypes between environments
paired <- blues %>%
  select(genotype, date, trait, environment, predicted.values) %>%
  pivot_wider(
    names_from = environment,
    values_from = predicted.values
  ) %>%
  filter(is.finite(G2FE), is.finite(DG2F))


# Compare rankings between environments
comparison <- paired %>%
  group_by(date, trait) %>%
  summarise(
    n_genotypes = n(),
    irrigated_mean = mean(G2FE),
    rainfed_mean = mean(DG2F),
    spearman = cor(G2FE, DG2F, method = "spearman"),
    .groups = "drop"
  )

message("Irrigated against rainfed genotype means:")
print(as.data.frame(comparison), digits = 3, row.names = FALSE)


# Calculate proportional yield reduction
yield_response <- paired %>%
  filter(trait == "grain_yield") %>%
  mutate(
    yield_difference = G2FE - DG2F,
    proportional_reduction = if_else(
      G2FE > 0, 1 - DG2F / G2FE, NA_real_
    )
  )

# A negative reduction means the genotype yielded more under rainfed management
message(sprintf(
  "Grain yield: %d genotypes paired, %d yielded less under rainfed management, median reduction %.1f%%",
  nrow(yield_response), sum(yield_response$yield_difference > 0),
  100 * median(yield_response$proportional_reduction, na.rm = TRUE)
))


# Save
write.csv(
  comparison,
  file.path(processed_dir, "treatment_comparison.csv"),
  row.names = FALSE
)
write.csv(
  yield_response,
  file.path(processed_dir, "yield_response.csv"),
  row.names = FALSE
)
