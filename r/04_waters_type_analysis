# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 04_waters_type_analysis.R
# Purpose: Analyze piracy incidents by waters type
# Author: Maximilian Dick
# =====================================================

# -----------------------------------------------------
# 1. Initialize project
# -----------------------------------------------------

source("r/scripts/00_init.R")

# -----------------------------------------------------
# 2. Load prepared dataset
# -----------------------------------------------------

piracy_data <- readRDS(
  file.path(
    processed_dir,
    "piracy_data_prepared.rds"
  )
)

# -----------------------------------------------------
# 3. Waters type analysis
# -----------------------------------------------------

waters_analysis <- piracy_data %>%
  filter(
    year >= 2010,
    year <= 2025,
    !is.na(waters_type),
    waters_type != ""
  ) %>%
  group_by(waters_type) %>%
  summarise(
    incidents = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(incidents)) %>%
  mutate(
    percentage = round(
      incidents / sum(incidents) * 100,
      1
    ),
    label = paste0(
      incidents,
      " (",
      percentage,
      "%)"
    )
  )

print(waters_analysis)

# -----------------------------------------------------
# 4. Visualization
# -----------------------------------------------------

p_waters_type <- ggplot(
  waters_analysis,
  aes(
    x = reorder(waters_type, incidents),
    y = incidents
  )
) +
  geom_col() +
  coord_flip() +
  geom_text(
    aes(label = label),
    hjust = -0.1,
    size = 4
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.15))
  ) +
  labs(
    title = "Distribution of Piracy Incidents by Waters Type (2010–2025)",
    subtitle = "International waters, territorial waters and port areas",
    x = "Waters Type",
    y = "Number of Incidents"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold")
  )

print(p_waters_type)

# -----------------------------------------------------
# 5. Export figure
# -----------------------------------------------------

ggsave(
  filename = file.path(
    figure_dir,
    "waters_type_analysis_2010_2025.png"
  ),
  plot = p_waters_type,
  width = 11,
  height = 7,
  dpi = 300
)

# -----------------------------------------------------
# 6. Export table
# -----------------------------------------------------

write.csv(
  waters_analysis,
  file.path(
    table_dir,
    "waters_type_analysis_2010_2025.csv"
  ),
  row.names = FALSE
)

cat("\n")
cat("Waters type analysis completed successfully.\n")
cat("Figure and table saved to output folders.\n")
cat("\n")
