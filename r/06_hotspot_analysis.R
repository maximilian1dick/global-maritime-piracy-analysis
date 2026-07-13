# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 06_hotspot_analysis.R
# Purpose: Create hotspot and regional density maps
# Author: Maximilian Dick
# =====================================================

# -----------------------------------------------------
# 1. Initialize project
# -----------------------------------------------------

source("r/scripts/00_init.R")

library(ggspatial)
library(viridis)

# -----------------------------------------------------
# 2. Load prepared mappable dataset
# -----------------------------------------------------

piracy_data <- readRDS(
  file.path(
    processed_dir,
    "piracy_mappable_2010_2025.rds"
  )
)

world <- rnaturalearth::ne_countries(
  scale = "medium",
  returnclass = "sf"
)

cat("Georeferenced incidents:", nrow(piracy_data), "\n")

# -----------------------------------------------------
# 3. Global plot settings
# -----------------------------------------------------

density_bins <- 8

density_palette <- viridisLite::viridis(
  n = density_bins,
  option = "magma",
  direction = -1
)

density_labels <- paste0(
  "Class ",
  seq_len(density_bins)
)

map_theme <- theme_minimal(base_size = 12) +
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
    strip.text = element_text(
      face = "bold",
      size = 10
    ),
    legend.title = element_text(
      size = 10
    ),
    legend.text = element_text(
      size = 9
    ),
    legend.position = "right",
    panel.background = element_rect(
      fill = "grey10",
      color = NA
    ),
    plot.background = element_rect(
      fill = "white",
      color = NA
    ),
    panel.grid.major = element_line(
      color = "grey25",
      linewidth = 0.2
    ),
    panel.grid.minor = element_blank()
  )

add_world_dark <- function() {
  geom_sf(
    data = world,
    fill = "grey25",
    color = "grey10",
    linewidth = 0.25
  )
}

density_scale <- scale_fill_manual(
  values = density_palette,
  name = "Density class",
  labels = density_labels,
  na.translate = FALSE
)

# -----------------------------------------------------
# 4. Global hotspot density map
# -----------------------------------------------------

p_global_hotspot <- ggplot() +
  add_world_dark() +
  stat_density_2d_filled(
    data = piracy_data,
    aes(
      x = lon_dd,
      y = lat_dd,
      fill = after_stat(level)
    ),
    alpha = 0.75,
    contour_var = "density",
    bins = density_bins
  ) +
  geom_point(
    data = piracy_data,
    aes(x = lon_dd, y = lat_dd),
    alpha = 0.30,
    size = 0.45,
    color = "black"
  ) +
  coord_sf(
    xlim = c(-100, 130),
    ylim = c(-40, 40),
    expand = FALSE
  ) +
  density_scale +
  labs(
    title = "Global Hotspot Distribution of Maritime Piracy Incidents (2010–2025)",
    subtitle = "Kernel density approximation based on georeferenced IMO piracy incidents",
    x = "Longitude",
    y = "Latitude"
  ) +
  map_theme

print(p_global_hotspot)

ggsave(
  filename = file.path(
    figure_dir,
    "global_hotspot_density_2010_2025.png"
  ),
  plot = p_global_hotspot,
  width = 12,
  height = 7,
  dpi = 300
)

# -----------------------------------------------------
# 5. Somalia / Horn of Africa heatmap 2010–2013
# -----------------------------------------------------

somalia_data <- piracy_data %>%
  filter(
    year %in% 2010:2013,
    region %in% c("East Africa", "Indian Ocean", "Arabian Sea")
  )

print(somalia_data %>% count(year))

p_somalia_heatmap <- ggplot() +
  add_world_dark() +
  stat_density_2d_filled(
    data = somalia_data,
    aes(
      x = lon_dd,
      y = lat_dd,
      fill = after_stat(level)
    ),
    alpha = 0.75,
    contour_var = "density",
    bins = density_bins
  ) +
  geom_point(
    data = somalia_data,
    aes(x = lon_dd, y = lat_dd),
    size = 0.55,
    alpha = 0.45,
    color = "black"
  ) +
  facet_wrap(~ year, ncol = 2) +
  coord_sf(
    xlim = c(35, 75),
    ylim = c(-10, 25),
    expand = FALSE
  ) +
  density_scale +
  labs(
    title = "Spatial Shift of Piracy Incidents around the Horn of Africa",
    subtitle = "Kernel density approximation of reported incidents, 2010–2013",
    x = "Longitude",
    y = "Latitude"
  ) +
  map_theme

print(p_somalia_heatmap)

ggsave(
  filename = file.path(
    figure_dir,
    "somalia_heatmap_2010_2013.png"
  ),
  plot = p_somalia_heatmap,
  width = 12,
  height = 8,
  dpi = 300
)

# -----------------------------------------------------
# 6. Strait of Malacca heatmap 2020–2023
# -----------------------------------------------------

malacca_data <- piracy_data %>%
  filter(
    region == "Malacca Strait",
    year %in% 2020:2023
  )

print(malacca_data %>% count(year))

p_malacca_heatmap <- ggplot() +
  add_world_dark() +
  stat_density_2d_filled(
    data = malacca_data,
    aes(
      x = lon_dd,
      y = lat_dd,
      fill = after_stat(level)
    ),
    contour_var = "density",
    bins = density_bins,
    alpha = 0.75,
    h = c(0.9, 0.45)
  ) +
  geom_point(
    data = malacca_data,
    aes(x = lon_dd, y = lat_dd),
    color = "black",
    size = 0.65,
    alpha = 0.55
  ) +
  facet_wrap(~ year, ncol = 2) +
  coord_sf(
    xlim = c(96, 108),
    ylim = c(-2, 7),
    expand = FALSE
  ) +
  density_scale +
  labs(
    title = "Spatial Shift of Piracy Incidents in the Strait of Malacca",
    subtitle = "Kernel density approximation of reported incidents, 2020–2023",
    x = "Longitude",
    y = "Latitude"
  ) +
  map_theme

print(p_malacca_heatmap)

ggsave(
  filename = file.path(
    figure_dir,
    "malacca_heatmap_2020_2023.png"
  ),
  plot = p_malacca_heatmap,
  width = 12,
  height = 8,
  dpi = 300
)

# -----------------------------------------------------
# 7. South China Sea heatmap 2013–2016
# -----------------------------------------------------

scs_data <- piracy_data %>%
  filter(
    region == "South China Sea",
    year %in% 2013:2016
  )

print(scs_data %>% count(year))

p_scs_heatmap <- ggplot() +
  add_world_dark() +
  stat_density_2d_filled(
    data = scs_data,
    aes(
      x = lon_dd,
      y = lat_dd,
      fill = after_stat(level)
    ),
    contour_var = "density",
    bins = density_bins,
    alpha = 0.75,
    h = c(1.0, 0.7)
  ) +
  geom_point(
    data = scs_data,
    aes(x = lon_dd, y = lat_dd),
    color = "black",
    size = 0.6,
    alpha = 0.55
  ) +
  facet_wrap(~ year, ncol = 2) +
  coord_sf(
    xlim = c(102, 121),
    ylim = c(-1, 13),
    expand = FALSE
  ) +
  density_scale +
  labs(
    title = "Spatial Shift of Piracy Incidents in the South China Sea",
    subtitle = "Kernel density approximation of reported incidents, 2013–2016",
    x = "Longitude",
    y = "Latitude"
  ) +
  map_theme

print(p_scs_heatmap)

ggsave(
  filename = file.path(
    figure_dir,
    "south_china_sea_heatmap_2013_2016.png"
  ),
  plot = p_scs_heatmap,
  width = 12,
  height = 8,
  dpi = 300
)

# -----------------------------------------------------
# 8. Annual regional trends
# -----------------------------------------------------

underestimation_note <- paste(
  "Note: Values from 2021 onwards are affected by systematic",
  "underestimation due to changed IMO report structures."
)

p_annual_region <- ggplot(
  annual_region,
  aes(
    x = year,
    y = n,
    color = region
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
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  annotate(
    "text",
    x = 2023,
    y = max(annual_region$n, na.rm = TRUE) * 0.92,
    label = "Changed IMO report layout\n→ systematic parser underestimation",
    color = "red3",
    size = 3.2,
    hjust = 0.5
  ) +
  scale_x_continuous(
    breaks = 2010:2025
  ) +
  labs(
    title = "Annual Piracy Incidents by Region",
    subtitle = "Selected major piracy regions, 2010–2025; values from 2021 onwards are affected by reduced parser completeness",
    x = "Year",
    y = "Number of Incidents",
    color = "Region",
    caption = underestimation_note
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 16
    ),
    plot.subtitle = element_text(
      size = 11
    ),
    plot.caption = element_text(
      size = 9,
      hjust = 0
    ),
    axis.title = element_text(
      size = 11
    ),
    axis.text = element_text(
      size = 9
    ),
    legend.title = element_text(
      size = 10
    ),
    legend.text = element_text(
      size = 9
    ),
    legend.position = "bottom",
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    )
  )
print(p_annual_region)

ggsave(
  filename = file.path(
    figure_dir,
    "annual_region_trends_2010_2025.png"
  ),
  plot = p_annual_region,
  width = 10,
  height = 6,
  dpi = 300
)

write.csv(
  annual_region,
  file.path(
    table_dir,
    "annual_region_trends_2010_2025.csv"
  ),
  row.names = FALSE
)

cat("\n")
cat("Hotspot analysis completed successfully.\n")
cat("Figures and tables saved to output folders.\n")
cat("\n")
