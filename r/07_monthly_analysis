# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 07_monthly_analysis.R
# Purpose: Analyze monthly and regional seasonality of piracy incidents
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
# 3. Monthly distribution
# -----------------------------------------------------

monthly_analysis <- piracy_data %>%
  filter(
    year >= 2010,
    year <= 2025,
    !is.na(month),
    month >= 1,
    month <= 12
  ) %>%
  group_by(month) %>%
  summarise(
    incidents = n(),
    .groups = "drop"
  ) %>%
  arrange(month) %>%
  mutate(
    month_name = factor(
      month,
      levels = 1:12,
      labels = c(
        "Jan", "Feb", "Mar", "Apr",
        "May", "Jun", "Jul", "Aug",
        "Sep", "Oct", "Nov", "Dec"
      )
    )
  )

print(monthly_analysis)

# -----------------------------------------------------
# 4. Visualization: monthly distribution
# -----------------------------------------------------

p_monthly_distribution <- ggplot(
  monthly_analysis,
  aes(
    x = month_name,
    y = incidents
  )
) +
  geom_col() +
  geom_text(
    aes(label = incidents),
    vjust = -0.4,
    size = 4
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.12))
  ) +
  labs(
    title = "Monthly Distribution of Maritime Piracy Incidents (2010–2025)",
    subtitle = "Frequency by month",
    x = "Month",
    y = "Number of Incidents"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold")
  )

print(p_monthly_distribution)

ggsave(
  filename = file.path(
    figure_dir,
    "monthly_distribution_2010_2025.png"
  ),
  plot = p_monthly_distribution,
  width = 11,
  height = 7,
  dpi = 300
)

write.csv(
  monthly_analysis,
  file.path(
    table_dir,
    "monthly_distribution_2010_2025.csv"
  ),
  row.names = FALSE
)

# -----------------------------------------------------
# 5. Regional monthly distribution
# -----------------------------------------------------

regional_monthly <- piracy_data %>%
  filter(
    year >= 2010,
    year <= 2025,
    !is.na(month),
    month >= 1,
    month <= 12,
    !is.na(region),
    region != ""
  ) %>%
  group_by(region, month) %>%
  summarise(
    incidents = n(),
    .groups = "drop"
  ) %>%
  mutate(
    month_name = factor(
      month,
      levels = 1:12,
      labels = c(
        "Jan", "Feb", "Mar", "Apr",
        "May", "Jun", "Jul", "Aug",
        "Sep", "Oct", "Nov", "Dec"
      )
    )
  )

top_regions <- regional_monthly %>%
  group_by(region) %>%
  summarise(
    total = sum(incidents),
    .groups = "drop"
  ) %>%
  arrange(desc(total)) %>%
  slice(1:6)

regional_monthly_top <- regional_monthly %>%
  filter(region %in% top_regions$region)

print(regional_monthly_top)

# -----------------------------------------------------
# 6. Visualization: regional seasonality
# -----------------------------------------------------

p_regional_seasonality <- ggplot(
  regional_monthly_top,
  aes(
    x = month_name,
    y = incidents
  )
) +
  geom_col() +
  facet_wrap(
    ~ region,
    scales = "free_y"
  ) +
  labs(
    title = "Seasonal Distribution of Piracy Incidents by Region (2010–2025)",
    subtitle = "Monthly frequency by operational region",
    x = "Month",
    y = "Number of Incidents"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

print(p_regional_seasonality)

ggsave(
  filename = file.path(
    figure_dir,
    "regional_seasonality_2010_2025.png"
  ),
  plot = p_regional_seasonality,
  width = 14,
  height = 10,
  dpi = 300
)

write.csv(
  regional_monthly_top,
  file.path(
    table_dir,
    "regional_seasonality_2010_2025.csv"
  ),
  row.names = FALSE
)

cat("\n")
cat("Monthly analysis completed successfully.\n")
cat("Figures and tables saved to output folders.\n")
cat("\n")
