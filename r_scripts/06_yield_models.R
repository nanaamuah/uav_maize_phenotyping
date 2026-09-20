# Spatially corrected grain yield models within each environment
# Output: data/processed/yield_models.rds

library(here)
library(dplyr)
library(SpATS)


# Folder paths
processed_dir <- here("data", "processed")


# Read trial metadata
trial <- read.csv(file.path(
  processed_dir, "trial_metadata.csv"
)) %>%
  filter(is.finite(yield)) %>%
  mutate(across(c(genotype, replicate), as.factor))

message("Plots with a yield value, by environment:")
print(table(trial$environment))


# Fit models within each environment
results <- lapply(split(trial, trial$environment), function(dat) {
  dat <- droplevels(dat)

  # Data going into the model; rows and ranges set the spline grid
  stopifnot(is.numeric(dat$row), is.numeric(dat$range))
  message(sprintf(
    "%s: %d plots, %d genotypes, %d rows x %d ranges",
    unique(dat$environment), nrow(dat), nlevels(dat$genotype),
    n_distinct(dat$row), n_distinct(dat$range)
  ))

  fit <- function(random) {
    SpATS(
      response = "yield",
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
  blues <- predict(fixed_model, which = "genotype", predFixed = "marginal")

  message(sprintf(
    "%s: generalized heritability %.2f, %d BLUEs",
    unique(dat$environment), heritability, nrow(blues)
  ))

  if (nrow(blues) != nlevels(dat$genotype)) {
    warning("The number of BLUEs differs from the number of genotypes")
  }

  list(
    random = random_model,
    fixed = fixed_model,
    heritability = heritability,
    blues = blues
  )
})


# Save models and estimates
saveRDS(
  results,
  file.path(processed_dir, "yield_models.rds")
)
