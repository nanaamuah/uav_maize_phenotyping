# Spatially corrected models for each UAV trait within each environment
# Output: data/processed/rgb_models_20170420.rds

library(here)
library(dplyr)
library(SpATS)


# Folder paths
processed_dir <- here("data", "processed")


# Read plot measurements
traits <- read.csv(file.path(
  processed_dir, "plot_data_20170420.csv"
)) %>%
  filter(is.finite(value)) %>%
  mutate(across(c(genotype, replicate), as.factor))

# Unmatched plots carry no genotype and should not reach the models
message(sprintf(
  "Rows without environment or genotype: %d", sum(is.na(traits$environment) | is.na(traits$genotype))
))


# Group measurements
groups <- split(
  traits,
  interaction(traits$environment, traits$date, traits$trait,
              drop = TRUE)
)

message(sprintf("%d environment x date x trait groups; plots per group:", length(groups)))
print(sapply(groups, nrow))


# Fit spatial models
results <- lapply(groups, function(dat) {
  dat <- droplevels(dat)

  label <- paste(unique(dat$environment), unique(dat$date), unique(dat$trait))
  stopifnot(is.numeric(dat$row), is.numeric(dat$range))

  fit <- function(random) {
    SpATS(
      response = "value",
      genotype = "genotype",
      genotype.as.random = random,
      fixed = ~ replicate,
      spatial = ~ PSANOVA(row, range, nseg = c(10, 10)),
      data = dat
    )
  }

  random_model <- fit(TRUE)
  fixed_model <- fit(FALSE)

  heritability <- getHeritability(random_model)
  message(sprintf("%s: generalized heritability %.2f", label, heritability))

  list(
    info = distinct(dat, environment, date, trait),
    random = random_model,
    fixed = fixed_model,
    heritability = heritability,
    blues = predict(
      fixed_model, which = "genotype", predFixed = "marginal"
    )
  )
})


# Save models and estimates
saveRDS(
  results,
  file.path(processed_dir, "rgb_models_20170420.rds")
)
