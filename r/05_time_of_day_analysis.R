# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 05_time_of_day_analysis.R
# Purpose: Analyze time-of-day patterns of piracy incidents
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
# 3. Time-of-day distribution
# -----------------------------------------------------

time_analysis <- piracy_data %>%
  filter(
    year >= 2010,
    year <= 2025,
    !is.na(time_period),
    time_period != "",
    time_period != "unknown"
  ) %>%
  group_by(time_period) %>%
  summarise(
    incidents = n(),
    .groups = "drop"
  ) %>%
  mutate(
    time_period = factor(
      time_period,
      levels = c("night", "dawn", "day", "dusk")
    )
  ) %>%
  arrange(time_period) %>%
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

print(time_analysis)

# -----------------------------------------------------
# 4. Visualization: overall time-of-day distribution
# -----------------------------------------------------

p_time_of_day <- ggplot(
  time_analysis,
  aes(
    x = time_period,
    y = incidents
  )
) +
  geom_col() +
  geom_text(
    aes(label = label),
    vjust = -0.5,
    size = 4
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.15))
  ) +
  labs(
    title = "Time-of-Day Distribution of Maritime Piracy Incidents (2010–2025)",
    subtitle = "Night, dawn, day and dusk",
    x = "Time Period",
    y = "Number of Incidents"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold")
  )

print(p_time_of_day)

ggsave(
  filename = file.path(
    figure_dir,
    "time_of_day_analysis_2010_2025.png"
  ),
  plot = p_time_of_day,
  width = 11,
  height = 7,
  dpi = 300
)

write.csv(
  time_analysis,
  file.path(
    table_dir,
    "time_of_day_analysis_2010_2025.csv"
  ),
  row.names = FALSE
)

# -----------------------------------------------------
# 5. Regional time-of-day analysis
# -----------------------------------------------------

regional_time <- piracy_data %>%
  filter(
    year >= 2010,
    year <= 2025,
    !is.na(time_period),
    time_period != "",
    time_period != "unknown",
    !is.na(region),
    region != ""
  ) %>%
  group_by(region, time_period) %>%
  summarise(
    incidents = n(),
    .groups = "drop"
  ) %>%
  mutate(
    time_period = factor(
      time_period,
      levels = c("night", "dawn", "day", "dusk")
    )
  )

top_regions <- regional_time %>%
  group_by(region) %>%
  summarise(
    total = sum(incidents),
    .groups = "drop"
  ) %>%
  arrange(desc(total)) %>%
  slice(1:6)

regional_time_top <- regional_time %>%
  filter(region %in% top_regions$region)

print(regional_time_top)

# -----------------------------------------------------
# 6. Visualization: regional time-of-day distribution
# -----------------------------------------------------

p_regional_time <- ggplot(
  regional_time_top,
  aes(
    x = time_period,
    y = incidents
  )
) +
  geom_col() +
  facet_wrap(
    ~ region,
    scales = "free_y"
  ) +
  labs(
    title = "Regional Time-of-Day Distribution of Piracy Incidents (2010–2025)",
    subtitle = "Night, dawn, day and dusk by operational region",
    x = "Time Period",
    y = "Number of Incidents"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

print(p_regional_time)

ggsave(
  filename = file.path(
    figure_dir,
    "regional_time_of_day_analysis_2010_2025.png"
  ),
  plot = p_regional_time,
  width = 14,
  height = 10,
  dpi = 300
)

write.csv(
  regional_time_top,
  file.path(
    table_dir,
    "regional_time_of_day_analysis_2010_2025.csv"
  ),
  row.names = FALSE
)

cat("\n")
cat("Time-of-day analysis completed successfully.\n")
cat("Figures and tables saved to output folders.\n")
cat("\n")
