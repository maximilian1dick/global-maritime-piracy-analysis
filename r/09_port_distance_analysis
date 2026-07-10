# -----------------------------------------------------
# 8. Export extended dataset
# -----------------------------------------------------

write.csv2(
  piracy_ports_distance,
  file.path(export_dir, "piracy_ports_distance.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

saveRDS(
  piracy_ports_distance,
  file.path(processed_dir, "piracy_ports_distance.rds")
)

# -----------------------------------------------------
# 9. Yearly summary statistics
# -----------------------------------------------------

distance_yearly_summary <- piracy_ports_distance %>%
  group_by(year) %>%
  summarise(
    n_incidents = n(),
    mean_distance_km = mean(distance_to_port_km, na.rm = TRUE),
    median_distance_km = median(distance_to_port_km, na.rm = TRUE),
    min_distance_km = min(distance_to_port_km, na.rm = TRUE),
    max_distance_km = max(distance_to_port_km, na.rm = TRUE),
    sd_distance_km = sd(distance_to_port_km, na.rm = TRUE),
    .groups = "drop"
  )

print(distance_yearly_summary)

write.csv2(
  distance_yearly_summary,
  file.path(table_dir, "distance_to_ports_yearly_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

underestimation_note <- paste(
  "Note: Values from 2021 onwards are affected by systematic",
  "underestimation due to changed IMO report structures."
)

data_quality_subtitle <- paste(
  "Annual distance statistics, 2010–2025;",
  "values from 2021 onwards are affected by reduced parser completeness"
)

# -----------------------------------------------------
# 10. Plot: median distance by year
# -----------------------------------------------------

p_year_median <- ggplot(
  distance_yearly_summary,
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
    y = max(distance_yearly_summary$median_distance_km, na.rm = TRUE) * 0.9,
    label = "Changed IMO report layout\n→ systematic parser underestimation",
    color = "red3",
    size = 3.2,
    hjust = 0.5
  ) +
  scale_x_continuous(
    breaks = 2010:2025
  ) +
  labs(
    title = "Median Distance of Piracy Incidents to Nearest Port",
    subtitle = data_quality_subtitle,
    x = "Year",
    y = "Median distance to nearest port (km)",
    caption = underestimation_note
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11),
    plot.caption = element_text(size = 9, hjust = 0),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 9),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p_year_median)

ggsave(
  filename = file.path(
    figure_dir,
    "distance_to_ports_median_by_year_2010_2025.png"
  ),
  plot = p_year_median,
  width = 10,
  height = 6,
  dpi = 300
)

# -----------------------------------------------------
# 11. Plot: yearly distance distribution
# -----------------------------------------------------

p_year_boxplot <- ggplot(
  piracy_ports_distance,
  aes(x = year, y = distance_to_port_km, group = year)
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
  scale_x_continuous(
    breaks = 2010:2025
  ) +
  labs(
    title = "Distribution of Piracy Incident Distances to Nearest Port",
    subtitle = data_quality_subtitle,
    x = "Year",
    y = "Distance to nearest port (km)",
    caption = underestimation_note
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11),
    plot.caption = element_text(size = 9, hjust = 0),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 9),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

print(p_year_boxplot)

ggsave(
  filename = file.path(
    figure_dir,
    "distance_to_ports_boxplot_by_year_2010_2025.png"
  ),
  plot = p_year_boxplot,
  width = 11,
  height = 6,
  dpi = 300
)

# -----------------------------------------------------
# 12. Plot: histogram of all distances
# -----------------------------------------------------

p_hist <- ggplot(
  piracy_ports_distance,
  aes(x = distance_to_port_km)
) +
  geom_histogram(bins = 40) +
  labs(
    title = "Distance Distribution of Piracy Incidents to Nearest Port",
    subtitle = "Global overview, 2010–2025",
    x = "Distance to nearest port (km)",
    y = "Number of extracted incidents"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 9)
  )

print(p_hist)

ggsave(
  filename = file.path(
    figure_dir,
    "distance_to_ports_histogram_2010_2025.png"
  ),
  plot = p_hist,
  width = 10,
  height = 6,
  dpi = 300
)

# -----------------------------------------------------
# 13. Plot: regional distance distribution
# -----------------------------------------------------

p_region_boxplot <- ggplot(
  piracy_ports_distance,
  aes(
    x = reorder(region, distance_to_port_km, median, na.rm = TRUE),
    y = distance_to_port_km
  )
) +
  geom_boxplot(outlier.alpha = 0.35) +
  coord_flip() +
  labs(
    title = "Distance of Piracy Incidents to Nearest Port by Region",
    subtitle = "Regional comparison, 2010–2025",
    x = "Region",
    y = "Distance to nearest port (km)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 9)
  )

print(p_region_boxplot)

ggsave(
  filename = file.path(
    figure_dir,
    "distance_to_ports_boxplot_by_region_2010_2025.png"
  ),
  plot = p_region_boxplot,
  width = 10,
  height = 7,
  dpi = 300
)

# -----------------------------------------------------
# 14. Completion message
# -----------------------------------------------------

cat("\n")
cat("Port distance analysis completed successfully.\n")
cat("Extended dataset, tables and figures saved to output folders.\n")
cat("Note: Values from 2021 onwards are affected by systematic parser underestimation.\n")
cat("\n")
