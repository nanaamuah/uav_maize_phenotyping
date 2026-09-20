# Coincidence of selection and retention of top yielders under a UAV-based cull
# Output: data/processed/selection.csv

library(here)
library(dplyr)


# Folder paths
processed_dir <- here("data", "processed")


# Read adjusted means
blues <- read.csv(file.path(processed_dir, "blues.csv"))

yield <- blues %>%
  filter(environment == "DG2F", trait == "grain_yield") %>%
  transmute(genotype, yield = predicted.values)

paired <- blues %>%
  filter(environment == "DG2F", trait != "grain_yield") %>%
  transmute(genotype, date, trait, uav = predicted.values) %>%
  inner_join(yield, by = "genotype", relationship = "many-to-one") %>%
  filter(is.finite(uav), is.finite(yield))


# Evaluate selection within each date and trait
# Higher trait values are ranked as better for every trait
selection <- paired %>%
  group_by(date, trait) %>%
  group_modify(~ {
    n <- nrow(.x)
    yield_order <- arrange(.x, desc(yield), genotype)$genotype
    uav_order <- arrange(.x, desc(uav), genotype)$genotype
    retained <- head(uav_order, ceiling(n / 2))

    bind_rows(lapply(c(0.10, 0.20), function(intensity) {
      k <- ceiling(n * intensity)
      target <- head(yield_order, k)

      data.frame(
        intensity = intensity,
        n_genotypes = n,
        n_selected = k,
        n_retained = length(retained),
        coincidence = mean(target %in% head(uav_order, k)),
        retention = mean(target %in% retained)
      )
    }))
  }) %>%
  ungroup()

# Under random ranking, coincidence is expected to equal the selection
# intensity and retention of top yielders after a half cull to be about 0.5
message("Coincidence and retention (chance: coincidence = intensity, retention = 0.5):")
print(as.data.frame(selection), digits = 3, row.names = FALSE)


# Save
write.csv(
  selection,
  file.path(processed_dir, "selection.csv"),
  row.names = FALSE
)
