# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 11_region_time_incident_analysis.R
# Purpose: Analyze incident types by region and time period
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
# 3. Define target regions
# -----------------------------------------------------

target_regions <- c(
  "Arabian Sea",
  "East Africa",
  "Indian Ocean",
  "Malacca Strait",
  "South China Sea",
  "West Africa"
)

# -----------------------------------------------------
# 4. Prepare plot data
# -----------------------------------------------------

plot_data <- piracy_data %>%
  filter(
    year >= 2010,
    year <= 2025,
    region %in% target_regions,
    !is.na(time_period),
    time_period != "",
    time_period != "unknown",
    !is.na(incident_type),
    incident_type != ""
  ) %>%
  mutate(
    time_period = factor(
      time_period,
      levels = c(
        "night",
        "dawn",
        "day",
        "dusk"
      )
    )
  )

# -----------------------------------------------------
# 5. Summary table
# -----------------------------------------------------

region_time_attack <- plot_data %>%
  group_by(
    region,
    time_period,
    incident_type
  ) %>%
  summarise(
    incidents = n(),
    .groups = "drop"
  )

print(region_time_attack)

write.csv(
  region_time_attack,
  file.path(
    table_dir,
    "region_time_incident_types_2010_2025.csv"
  ),
  row.names = FALSE
)

# -----------------------------------------------------
# 6. Visualization
# -----------------------------------------------------

p_region_time_attack <- ggplot(
  plot_data,
  aes(
    x = time_period,
    fill = incident_type
  )
) +
  geom_bar(
    position = "stack"
  ) +
  facet_wrap(
    ~ region,
    ncol = 3,
    scales = "free_y"
  ) +
  labs(
    title = "Incident Types by Region and Time Period",
    subtitle = "Absolute number of piracy incidents, 2010–2025",
    x = "Time Period",
    y = "Number of Incidents",
    fill = "Incident Type"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p_region_time_attack)

# -----------------------------------------------------
# 7. Export figure
# -----------------------------------------------------

ggsave(
  filename = file.path(
    figure_dir,
    "region_time_incident_types_2010_2025.png"
  ),
  plot = p_region_time_attack,
  width = 12,
  height = 8,
  dpi = 300
)

# -----------------------------------------------------
# 8. Completion message
# -----------------------------------------------------

cat("\n")
cat("Region-time incident type analysis completed successfully.\n")
cat("Figure and table saved to output folders.\n")
cat("\n")

