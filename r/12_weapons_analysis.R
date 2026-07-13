# ==================================================
# weapons_analysis.R
#
# Purpose:
# Analysis of the weapons used by attackers in piracy incidents
# as documented in the IMO annual reports for the period 2010–2025.
# ==================================================

library(tidyverse)
library(scales)

weapons <- read.csv(
  "D:/your/directory/weapons.csv",
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8-BOM"
)

weapons <- weapons %>%
  mutate(
    year = as.numeric(year),
    count = as.numeric(count),
    weapon_type_label = case_when(
      weapon_type == "guns" ~ "Guns",
      weapon_type == "knives" ~ "Knives",
      weapon_type == "rpg" ~ "Rocket-propelled grenades",
      weapon_type == "other" ~ "Other",
      weapon_type == "none_not_stated" ~ "None / not stated",
      TRUE ~ weapon_type_label
    )
  ) %>%
  filter(
    year >= 2010,
    year <= 2025,
    !is.na(count)
  )

dir.create(
  "D:/your/directory/working/figures",
  showWarnings = FALSE,
  recursive = TRUE
)

underestimation_note <- paste(
  "Note: Values from 2021 onwards are affected by systematic",
  "underestimation due to changed IMO report structures."
)

# --------------------------------------------------
# 1. Total Development of Armament
# --------------------------------------------------

p_weapons_absolute <- weapons %>%
  ggplot(aes(
    x = year,
    y = count,
    color = weapon_type_label,
    group = weapon_type_label
  )) +
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
    y = max(weapons$count, na.rm = TRUE) * 0.92,
    label = "Changed IMO report layout\n→ systematic parser underestimation",
    color = "red3",
    size = 3.2,
    hjust = 0.5
  ) +
  scale_x_continuous(
    breaks = 2010:2025
  ) +
  labs(
    title = "Weapons used in piracy incidents",
    subtitle = "Annual number of reported incidents by weapon type, 2010–2025",
    x = "Year",
    y = "Number of incidents",
    color = "Weapon type",
    caption = underestimation_note
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.caption = element_text(size = 9, hjust = 0),
    legend.position = "bottom"
  )

print(p_weapons_absolute)

ggsave(
  "D:/your/directory/weapons_absolute_2010_2025.png",
  p_weapons_absolute,
  width = 10,
  height = 6,
  dpi = 300
)

# --------------------------------------------------
# 2. Relative Distribution of Armament
# --------------------------------------------------

p_weapons_relative <- weapons %>%
  group_by(year) %>%
  mutate(
    share = count / sum(count, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  ggplot(aes(
    x = year,
    y = share,
    fill = weapon_type_label
  )) +
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
  geom_area(position = "fill", alpha = 0.9) +
  scale_x_continuous(
    breaks = 2010:2025
  ) +
  scale_y_continuous(
    labels = percent_format()
  ) +
  labs(
    title = "Relative composition of weapons used in piracy incidents",
    subtitle = "Share of reported weapon types, 2010–2025",
    x = "Year",
    y = "Share of incidents",
    fill = "Weapon type",
    caption = underestimation_note
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.caption = element_text(size = 9, hjust = 0),
    legend.position = "bottom"
  )

print(p_weapons_relative)

ggsave(
  "D:/Studium/6. Semester/Bachelorarbeit/working/figures/weapons_relative_2010_2025.png",
  p_weapons_relative,
  width = 10,
  height = 6,
  dpi = 300
)

# --------------------------------------------------
# 3. Separated Histogram
# --------------------------------------------------

p_weapons_stacked <- weapons %>%
  ggplot(aes(
    x = year,
    y = count,
    fill = weapon_type_label
  )) +
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
  geom_col(width = 0.8) +
  scale_x_continuous(
    breaks = 2010:2025
  ) +
  labs(
    title = "Weapons used by attackers in piracy incidents",
    subtitle = "Reported incidents by weapon type, 2010–2025",
    x = "Year",
    y = "Number of incidents",
    fill = "Weapon type",
    caption = underestimation_note
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.caption = element_text(size = 9, hjust = 0),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

print(p_weapons_stacked)

ggsave(
  "D:/Studium/6. Semester/Bachelorarbeit/working/figures/weapons_stacked_2010_2025.png",
  p_weapons_stacked,
  width = 10,
  height = 6,
  dpi = 300
)

# --------------------------------------------------
# 4. Summary: armed vs. not specified
# --------------------------------------------------

weapons_summary <- weapons %>%
  mutate(
    weapon_group = if_else(
      weapon_type == "none_not_stated",
      "None / not stated",
      "Weapon reported"
    )
  ) %>%
  group_by(year, weapon_group) %>%
  summarise(
    count = sum(count, na.rm = TRUE),
    .groups = "drop"
  )

p_weapon_reported <- weapons_summary %>%
  ggplot(aes(
    x = year,
    y = count,
    color = weapon_group,
    group = weapon_group
  )) +
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
    y = max(weapons_summary$count, na.rm = TRUE) * 0.92,
    label = "Changed IMO report layout\n→ systematic parser underestimation",
    color = "red3",
    size = 3.2,
    hjust = 0.5
  ) +
  scale_x_continuous(
    breaks = 2010:2025
  ) +
  labs(
    title = "Reported weapons versus none / not stated",
    subtitle = "Piracy incidents by weapon reporting status, 2010–2025",
    x = "Year",
    y = "Number of incidents",
    color = "Category",
    caption = underestimation_note
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.caption = element_text(size = 9, hjust = 0),
    legend.position = "bottom"
  )

print(p_weapon_reported)

ggsave(
  "D:/Studium/6. Semester/Bachelorarbeit/working/figures/weapons_reported_vs_not_stated_2010_2025.png",
  p_weapon_reported,
  width = 10,
  height = 6,
  dpi = 300
)

write.csv(
  weapons_summary,
  "D:/Studium/6. Semester/Bachelorarbeit/working/data/raw/weapons_summary_reported_vs_not_stated.csv",
  row.names = FALSE
)
