# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 10_distance_to_coast_analysis.R
# Purpose: Calculate distance from piracy incidents
#          to nearest coastline
# Author: Maximilian Dick
# =====================================================

# -----------------------------------------------------
# 1. Initialize project
# -----------------------------------------------------

source("r/scripts/00_init.R")

# -----------------------------------------------------
# 2. Load prepared mappable dataset
# -----------------------------------------------------

piracy_data <- readRDS(
  file.path(
    processed_dir,
    "piracy_mappable_2010_2025.rds"
  )
)

# -----------------------------------------------------
# 3. Load world coastline
# -----------------------------------------------------

world <- rnaturalearth::ne_countries(
  scale = "medium",
  returnclass = "sf"
)

coastline <- st_boundary(world)

# -----------------------------------------------------
# 4. Create sf object from piracy incidents
# -----------------------------------------------------

piracy_sf <- st_as_sf(
  piracy_data,
  coords = c("lon_dd", "lat_dd"),
  crs = 4326,
  remove = FALSE
)

# -----------------------------------------------------
# 5. Transform to metric projection
# -----------------------------------------------------

piracy_proj <- st_transform(
  piracy_sf,
  3857
)

coastline_proj <- st_transform(
  coastline,
  3857
)

# -----------------------------------------------------
# 6. Calculate nearest coastline distance
# -----------------------------------------------------

nearest_coast_index <- st_nearest_feature(
  piracy_proj,
  coastline_proj
)

nearest_coast <- coastline_proj[
  nearest_coast_index,
]

distance_to_coast_m <- st_distance(
  piracy_proj,
  nearest_coast,
  by_element = TRUE
)

piracy_coast_distance <- piracy_data %>%
  mutate(
    distance_to_coast_km = as.numeric(distance_to_coast_m) / 1000
  )

cat("\n")
cat("Valid incidents:", nrow(piracy_coast_distance), "\n")
cat("Distance to coast calculated successfully.\n")
cat("\n")

print(
  summary(
    piracy_coast_distance$distance_to_coast_km
  )
)

# -----------------------------------------------------
# 7. Export extended dataset
# -----------------------------------------------------

write.csv2(
  piracy_coast_distance,
  file.path(
    export_dir,
    "piracy_coast_distance.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

saveRDS(
  piracy_coast_distance,
  file.path(
    processed_dir,
    "piracy_coast_distance.rds"
  )
)

# -----------------------------------------------------
# 8. Yearly summary statistics
# -----------------------------------------------------

distance_by_year <- piracy_coast_distance %>%
  group_by(year) %>%
  summarise(
    n_incidents = n(),
    mean_distance_km = mean(
      distance_to_coast_km,
      na.rm = TRUE
    ),
    median_distance_km = median(
      distance_to_coast_km,
      na.rm = TRUE
    ),
    min_distance_km = min(
      distance_to_coast_km,
      na.rm = TRUE
    ),
    max_distance_km = max(
      distance_to_coast_km,
      na.rm = TRUE
    ),
    sd_distance_km = sd(
      distance_to_coast_km,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) %>%
  arrange(year)

print(distance_by_year)

write.csv2(
  distance_by_year,
  file.path(
    table_dir,
    "distance_to_coast_yearly_summary.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# -----------------------------------------------------
## -----------------------------------------------------
# Plot note for time series affected by parser limits
# -----------------------------------------------------

underestimation_note <- paste(
  "Note: Values from 2021 onwards are affected by systematic",
  "underestimation due to changed IMO report structures."
)

data_quality_subtitle <- paste(
  "Average offshore distance of georeferenced incidents;",
  "values from 2021 onwards are affected by reduced parser completeness"
)

# -----------------------------------------------------
# 9. Plot: mean distance to coast by year
# -----------------------------------------------------

p_coast_mean <- ggplot(
  distance_by_year,
  aes(x = year, y = mean_distance_km)
) +
  annotate(
    "rect",
    xmin = 2020.5,
    xmax = 2025.5,
    ymin = -Inf,
    ymax = Inf,
    fill = "grey80",
    alpha = 0.35
  ) +
  geom_vline(
    xintercept = 2020.5,
    color = "red",
    linetype = "dashed",
    linewidth = 0.8
  ) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  annotate(
    "text",
    x = 2023,
    y = max(distance_by_year$mean_distance_km, na.rm = TRUE) * 0.9,
    label = "Changed IMO report layout\n→ systematic parser underestimation",
    color = "red3",
    size = 3.2,
    hjust = 0.5
  ) +
  scale_x_continuous(breaks = 2010:2025) +
  labs(
    title = "Mean Distance of Piracy Incidents to Coastline (2010–2025)",
    subtitle = data_quality_subtitle,
    x = "Year",
    y = "Mean distance to coastline (km)",
    caption = underestimation_note
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.caption = element_text(size = 9, hjust = 0),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p_coast_mean)

ggsave(
  filename = file.path(
    figure_dir,
    "distance_to_coast_mean_by_year_2010_2025.png"
  ),
  plot = p_coast_mean,
  width = 11,
  height = 7,
  dpi = 300
)

# -----------------------------------------------------
# 10. Plot: median distance to coast by year
# -----------------------------------------------------

p_coast_median <- ggplot(
  distance_by_year,
  aes(x = year, y = median_distance_km)
) +
  annotate(
    "rect",
    xmin = 2020.5,
    xmax = 2025.5,
    ymin = -Inf,
    ymax = Inf,
    fill = "grey80",
    alpha = 0.35
  ) +
  geom_vline(
    xintercept = 2020.5,
    color = "red",
    linetype = "dashed",
    linewidth = 0.8
  ) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  annotate(
    "text",
    x = 2023,
    y = max(distance_by_year$median_distance_km, na.rm = TRUE) * 0.9,
    label = "Changed IMO report layout\n→ systematic parser underestimation",
    color = "red3",
    size = 3.2,
    hjust = 0.5
  ) +
  scale_x_continuous(breaks = 2010:2025) +
  labs(
    title = "Median Distance of Piracy Incidents to Coastline (2010–2025)",
    subtitle = paste(
      "Median offshore distance of georeferenced incidents;",
      "values from 2021 onwards are affected by reduced parser completeness"
    ),
    x = "Year",
    y = "Median distance to coastline (km)",
    caption = underestimation_note
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.caption = element_text(size = 9, hjust = 0),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p_coast_median)

ggsave(
  filename = file.path(
    figure_dir,
    "distance_to_coast_median_by_year_2010_2025.png"
  ),
  plot = p_coast_median,
  width = 11,
  height = 7,
  dpi = 300
)

# -----------------------------------------------------
# 11. Plot: yearly boxplot
# -----------------------------------------------------

p_coast_boxplot_year <- ggplot(
  piracy_coast_distance,
  aes(
    x = year,
    y = distance_to_coast_km,
    group = year
  )
) +
  annotate(
    "rect",
    xmin = 2020.5,
    xmax = 2025.5,
    ymin = -Inf,
    ymax = Inf,
    fill = "grey80",
    alpha = 0.35
  ) +
  geom_vline(
    xintercept = 2020.5,
    color = "red",
    linetype = "dashed",
    linewidth = 0.8
  ) +
  geom_boxplot(outlier.alpha = 0.35) +
  scale_x_continuous(breaks = 2010:2025) +
  labs(
    title = "Distribution of Piracy Incident Distances to Coastline",
    subtitle = paste(
      "Global overview by year, 2010–2025;",
      "values from 2021 onwards are affected by reduced parser completeness"
    ),
    x = "Year",
    y = "Distance to coastline (km)",
    caption = underestimation_note
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.caption = element_text(size = 9, hjust = 0),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p_coast_boxplot_year)

ggsave(
  filename = file.path(
    figure_dir,
    "distance_to_coast_boxplot_by_year_2010_2025.png"
  ),
  plot = p_coast_boxplot_year,
  width = 11,
  height = 7,
  dpi = 300
)

# -----------------------------------------------------
# 12. Plot: regional boxplot
# -----------------------------------------------------

p_coast_boxplot_region <- piracy_coast_distance %>%
  filter(
    !is.na(region),
    region != ""
  ) %>%
  ggplot(
    aes(
      x = reorder(
        region,
        distance_to_coast_km,
        median,
        na.rm = TRUE
      ),
      y = distance_to_coast_km
    )
  ) +
  geom_boxplot(
    outlier.alpha = 0.35
  ) +
  coord_flip() +
  labs(
    title = "Distance of Piracy Incidents to Coastline by Region",
    subtitle = "Regional comparison, 2010–2025",
    x = "Region",
    y = "Distance to coastline (km)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold")
  )

print(p_coast_boxplot_region)

ggsave(
  filename = file.path(
    figure_dir,
    "distance_to_coast_boxplot_by_region_2010_2025.png"
  ),
  plot = p_coast_boxplot_region,
  width = 10,
  height = 7,
  dpi = 300
)

# -----------------------------------------------------
# 13. Completion message
# -----------------------------------------------------

cat("\n")
cat("Coast distance analysis completed successfully.\n")
cat("Extended dataset, tables and figures saved to output folders.\n")
cat("\n")
