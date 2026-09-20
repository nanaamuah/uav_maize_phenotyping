# Spearman rank correlation between each UAV trait and rainfed grain yield
# Output: data/processed/rank_correlations.csv

library(here)
library(dplyr)


# Folder paths
processed_dir <- here("data", "processed")


# Read adjusted means
blues <- read.csv(file.path(processed_dir, "blues.csv"))


# Prepare rainfed yield
yield <- blues %>%
  filter(environment == "DG2F", trait == "grain_yield") %>%
  transmute(genotype, yield = predicted.values)

if (nrow(yield) == 0) stop("No rainfed (DG2F) grain yield BLUEs in blues.csv")


# Match UAV measurements to yield
paired <- blues %>%
  filter(environment == "DG2F", trait != "grain_yield") %>%
  transmute(genotype, date, trait, uav = predicted.values) %>%
  inner_join(yield, by = "genotype", relationship = "many-to-one") %>%
  filter(is.finite(uav), is.finite(yield))

message(sprintf(
  "%d genotypes with rainfed yield BLUEs; %d of them also have UAV BLUEs",
  nrow(yield), n_distinct(paired$genotype)
))


# Compare rankings
correlations <- paired %>%
  group_by(date, trait) %>%
  summarise(
    n_genotypes = n(),
    spearman = cor(uav, yield, method = "spearman"),
    .groups = "drop"
  )

message("Spearman correlation with rainfed grain yield:")
print(as.data.frame(correlations), digits = 3, row.names = FALSE)


# Save
write.csv(
  correlations,
  file.path(processed_dir, "rank_correlations.csv"),
  row.names = FALSE
)
