# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 02_temporal_analysis.R
# Purpose: Analyze annual temporal development of piracy incidents
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
# 3. Annual incident counts
# -----------------------------------------------------

yearly_counts <- piracy_data %>%
  filter(
    !is.na(year),
    year >= 2010,
    year <= 2025
  ) %>%
  group_by(year) %>%
  summarise(
    incidents = n(),
    .groups = "drop"
  ) %>%
  arrange(year) %>%
  mutate(
    parser_completeness = ifelse(
      year >= 2021,
      "Reduced parser completeness",
      "High parser completeness"
    )
  )

print(yearly_counts)

# -----------------------------------------------------
# 4. Identify maximum and minimum
# -----------------------------------------------------

max_point <- yearly_counts %>%
  filter(incidents == max(incidents, na.rm = TRUE))

min_point <- yearly_counts %>%
  filter(incidents == min(incidents, na.rm = TRUE))

print(max_point)
print(min_point)

# -----------------------------------------------------
# 5. Plot temporal development
# -----------------------------------------------------

p_temporal_development <- ggplot(
  yearly_counts,
  aes(
    x = year,
    y = incidents
  )
) +
  
  # Period with reduced parser completeness
  annotate(
    "rect",
    xmin = 2020.5,
    xmax = 2025.5,
    ymin = -Inf,
    ymax = Inf,
    alpha = 0.12
  ) +
  
  geom_vline(
    xintercept = 2020.5,
    linetype = "dashed",
    linewidth = 0.8
  ) +
  
  geom_line(
    linewidth = 1
  ) +
  
  geom_point(
    size = 2
  ) +
  
  # Maximum
  geom_point(
    data = max_point,
    size = 4
  ) +
  
  geom_text(
    data = max_point,
    aes(
      label = paste0(year, " = ", incidents)
    ),
    vjust = -1,
    size = 4
  ) +
  
  # Minimum
  geom_point(
    data = min_point,
    size = 4
  ) +
  
  geom_text(
    data = min_point,
    aes(
      label = paste0(year, " = ", incidents)
    ),
    vjust = 1.5,
    size = 4
  ) +
  
  # Annotation for limited data quality
  annotate(
    "text",
    x = 2023,
    y = max(yearly_counts$incidents, na.rm = TRUE) * 0.92,
    label = "2021–2025: reduced parser completeness",
    size = 3.5,
    hjust = 0.5
  ) +
  
  scale_x_continuous(
    breaks = 2010:2025
  ) +
  
  labs(
    title = "Temporal Development of Maritime Piracy Incidents (2010–2025)",
    subtitle = "Based on extracted IMO Piracy Reports; values from 2021 onward are affected by reduced extraction completeness",
    x = "Year",
    y = "Number of Extracted Incidents"
  ) +
  
  theme_minimal(
    base_size = 12
  ) +
  
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    axis.title = element_text(
      size = 11
    ),
    axis.text = element_text(
      size = 9
    ),
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    )
  )

print(p_temporal_development)

# -----------------------------------------------------
# 6. Export figure
# -----------------------------------------------------

ggsave(
  filename = file.path(
    figure_dir,
    "temporal_development_2010_2025.png"
  ),
  plot = p_temporal_development,
  width = 10,
  height = 6,
  dpi = 300
)

# -----------------------------------------------------
# 7. Export table
# -----------------------------------------------------

write.csv(
  yearly_counts,
  file.path(
    table_dir,
    "temporal_development_2010_2025.csv"
  ),
  row.names = FALSE
)

# -----------------------------------------------------
# 8. Additional check for 2025
# -----------------------------------------------------

check_2025 <- piracy_data %>%
  filter(
    year == 2025
  ) %>%
  summarise(
    incidents_2025 = n(),
    parser_completeness = "Reduced parser completeness",
    .groups = "drop"
  )

print(check_2025)

source_files_2025 <- piracy_data %>%
  filter(
    year == 2025
  ) %>%
  count(
    source_file,
    sort = TRUE
  ) %>%
  mutate(
    parser_completeness = "Reduced parser completeness"
  )

print(source_files_2025)

write.csv(
  check_2025,
  file.path(
    table_dir,
    "check_2025_incidents.csv"
  ),
  row.names = FALSE
)

write.csv(
  source_files_2025,
  file.path(
    table_dir,
    "check_2025_source_files.csv"
  ),
  row.names = FALSE
)

cat("\n")
cat("Temporal analysis completed successfully.\n")
cat("Figure and tables saved to output folders.\n")
cat("Note: Values from 2021 onward are affected by reduced parser completeness.\n")
cat("\n")
