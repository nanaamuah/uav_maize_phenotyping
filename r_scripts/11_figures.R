# Figures for the report
# Output: outputs/figures/heritability.png, rank_correlations.png, selection.png

library(here)
library(dplyr)
library(tidyr)
library(ggplot2)


# Folder paths
processed_dir <- here("data", "processed")
figure_dir <- here("outputs", "figures")

# Create the figure folder on a fresh clone
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)


# Read results
heritability <- read.csv(file.path(processed_dir, "heritability.csv"))
correlations <- read.csv(file.path(processed_dir, "rank_correlations.csv"))
selection <- read.csv(file.path(processed_dir, "selection.csv"))


# Heritability
p1 <- ggplot(heritability, aes(trait, heritability, fill = environment)) +
  geom_col(position = "dodge") +
  labs(x = NULL, y = "Generalized heritability", fill = "Trial") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))


# Rank correlations
p2 <- ggplot(correlations, aes(trait, spearman)) +
  geom_col(fill = "steelblue") +
  geom_hline(yintercept = 0, colour = "grey40") +
  coord_cartesian(ylim = c(-1, 1)) +
  labs(x = NULL, y = "Spearman correlation with rainfed yield") +
  theme_bw()


# Selection performance
selection_long <- selection %>%
  mutate(intensity = paste0(intensity * 100, "%")) %>%
  pivot_longer(
    c(coincidence, retention),
    names_to = "metric", values_to = "proportion"
  )

p3 <- ggplot(selection_long, aes(trait, proportion, fill = intensity)) +
  geom_col(position = "dodge") +
  facet_wrap(~ metric) +
  scale_y_continuous(labels = scales::label_percent()) +
  coord_cartesian(ylim = c(0, 1)) +
  labs(x = NULL, y = NULL, fill = "Selection intensity") +
  theme_bw()


# Save figures
ggsave(file.path(figure_dir, "heritability.png"), p1,
       width = 8, height = 5, dpi = 300)
ggsave(file.path(figure_dir, "rank_correlations.png"), p2,
       width = 7, height = 5, dpi = 300)
ggsave(file.path(figure_dir, "selection.png"), p3,
       width = 9, height = 5, dpi = 300)

message("Figures written to ", figure_dir, ":")
print(list.files(figure_dir, pattern = "\\.png$"))
