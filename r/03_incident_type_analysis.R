# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 03_incident_type_analysis.R
# Purpose: Analyze piracy incident types by frequency,
#          time of day and region
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
# 3. Incident type distribution
# -----------------------------------------------------

incident_types <- piracy_data %>%
  filter(
    year >= 2010,
    year <= 2025,
    !is.na(incident_type),
    incident_type != ""
  ) %>%
  group_by(incident_type) %>%
  summarise(
    incidents = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(incidents))

print(incident_types)

p_incident_types <- ggplot(
  incident_types,
  aes(
    x = reorder(incident_type, incidents),
    y = incidents
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Distribution of Piracy Incident Types (2010–2025)",
    subtitle = "Based on extracted IMO Piracy Reports",
    x = "Incident Type",
    y = "Number of Incidents"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold")
  )

print(p_incident_types)

ggsave(
  filename = file.path(
    figure_dir,
    "incident_type_distribution_2010_2025.png"
  ),
  plot = p_incident_types,
  width = 10,
  height = 6,
  dpi = 300
)

write.csv(
  incident_types,
  file.path(
    table_dir,
    "incident_type_distribution_2010_2025.csv"
  ),
  row.names = FALSE
)

# -----------------------------------------------------
# 4. Incident type by time of day
# -----------------------------------------------------

incident_time <- piracy_data %>%
  filter(
    year >= 2010,
    year <= 2025,
    !is.na(incident_type),
    incident_type != "",
    !is.na(time_period),
    time_period != "",
    time_period != "unknown"
  ) %>%
  group_by(incident_type, time_period) %>%
  summarise(
    incidents = n(),
    .groups = "drop"
  )

incident_time <- incident_time %>%
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

top_types <- incident_time %>%
  group_by(incident_type) %>%
  summarise(
    total = sum(incidents),
    .groups = "drop"
  ) %>%
  arrange(desc(total)) %>%
  slice(1:6)

incident_time_top <- incident_time %>%
  filter(incident_type %in% top_types$incident_type)

print(incident_time_top)

p_incident_time <- ggplot(
  incident_time_top,
  aes(
    x = time_period,
    y = incidents
  )
) +
  geom_col() +
  facet_wrap(
    ~ incident_type,
    scales = "free_y"
  ) +
  labs(
    title = "Incident Type by Time of Day (2010–2025)",
    subtitle = "Night, dawn, day and dusk by attack type",
    x = "Time Period",
    y = "Number of Incidents"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

print(p_incident_time)

ggsave(
  filename = file.path(
    figure_dir,
    "incident_type_time_of_day_2010_2025.png"
  ),
  plot = p_incident_time,
  width = 15,
  height = 10,
  dpi = 300
)

write.csv(
  incident_time_top,
  file.path(
    table_dir,
    "incident_type_time_of_day_2010_2025.csv"
  ),
  row.names = FALSE
)

# -----------------------------------------------------
# 5. Incident type by region
# -----------------------------------------------------

incident_region <- piracy_data %>%
  filter(
    year >= 2010,
    year <= 2025,
    !is.na(incident_type),
    incident_type != "",
    !is.na(region),
    region != ""
  ) %>%
  group_by(region, incident_type) %>%
  summarise(
    incidents = n(),
    .groups = "drop"
  )

top_regions <- incident_region %>%
  group_by(region) %>%
  summarise(
    total = sum(incidents),
    .groups = "drop"
  ) %>%
  arrange(desc(total)) %>%
  slice(1:6)

incident_region_top <- incident_region %>%
  filter(region %in% top_regions$region)

print(incident_region_top)

p_incident_region <- ggplot(
  incident_region_top,
  aes(
    x = reorder(incident_type, incidents),
    y = incidents
  )
) +
  geom_col() +
  coord_flip() +
  facet_wrap(
    ~ region,
    scales = "free_y"
  ) +
  labs(
    title = "Incident Type Distribution by Region (2010–2025)",
    subtitle = "Attack types across major piracy regions",
    x = "Incident Type",
    y = "Number of Incidents"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

print(p_incident_region)

ggsave(
  filename = file.path(
    figure_dir,
    "incident_type_by_region_2010_2025.png"
  ),
  plot = p_incident_region,
  width = 15,
  height = 10,
  dpi = 300
)

write.csv(
  incident_region_top,
  file.path(
    table_dir,
    "incident_type_by_region_2010_2025.csv"
  ),
  row.names = FALSE
)

cat("\n")
cat("Incident type analysis completed successfully.\n")
cat("Figures and tables saved to output folders.\n")
cat("\n")
