# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 01_read_data.R
# Purpose: Load and prepare piracy master dataset
# Author: Maximilian Dick
# =====================================================

# -----------------------------------------------------
# 1. Initialize project
# -----------------------------------------------------

source("r/scripts/00_init.R")

# -----------------------------------------------------
# 2. Load piracy master dataset
# -----------------------------------------------------

piracy_raw <- read.csv2(
  file.path(
    project_dir,
    "data",
    "reports",
    "_output",
    "piracy_master_final_documented.csv"
  ),
  header = TRUE,
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8-BOM"
)

# -----------------------------------------------------
# 3. Prepare data types
# -----------------------------------------------------

piracy_data <- piracy_raw %>%
  mutate(
    year = as.numeric(year),
    month = as.numeric(month),
    lat_dd = as.numeric(gsub(",", ".", lat_dd)),
    lon_dd = as.numeric(gsub(",", ".", lon_dd))
  )

# -----------------------------------------------------
# 4. Basic data checks
# -----------------------------------------------------

cat("\n")
cat("========================================\n")
cat(" Piracy master dataset loaded\n")
cat("========================================\n")
cat("Rows:", nrow(piracy_data), "\n")
cat("Columns:", ncol(piracy_data), "\n")
cat("Years:", min(piracy_data$year, na.rm = TRUE), "-",
    max(piracy_data$year, na.rm = TRUE), "\n")
cat("========================================\n")
cat("\n")

year_counts <- piracy_data %>%
  count(year) %>%
  arrange(year)

print(year_counts)

# -----------------------------------------------------
# 5. Coordinate validity check
# -----------------------------------------------------

coordinate_check <- piracy_data %>%
  summarise(
    total_records = n(),
    records_with_coordinates = sum(!is.na(lat_dd) & !is.na(lon_dd)),
    records_without_coordinates = sum(is.na(lat_dd) | is.na(lon_dd)),
    valid_coordinates = sum(
      !is.na(lat_dd) & !is.na(lon_dd) &
        lat_dd >= -90 & lat_dd <= 90 &
        lon_dd >= -180 & lon_dd <= 180
    )
  )

print(coordinate_check)

# -----------------------------------------------------
# 6. Annual data quality overview
# -----------------------------------------------------

annual_quality <- piracy_data %>%
  group_by(year) %>%
  summarise(
    total_records = n(),
    valid_month = sum(!is.na(month) & month >= 1 & month <= 12),
    valid_coordinates = sum(
      !is.na(lat_dd) & !is.na(lon_dd) &
        lat_dd >= -90 & lat_dd <= 90 &
        lon_dd >= -180 & lon_dd <= 180
    ),
    valid_month_and_coordinates = sum(
      !is.na(month) & month >= 1 & month <= 12 &
        !is.na(lat_dd) & !is.na(lon_dd) &
        lat_dd >= -90 & lat_dd <= 90 &
        lon_dd >= -180 & lon_dd <= 180
    ),
    .groups = "drop"
  )

print(annual_quality)

# -----------------------------------------------------
# 7. Export quality tables
# -----------------------------------------------------

write.csv(
  year_counts,
  file.path(table_dir, "year_counts.csv"),
  row.names = FALSE
)

write.csv(
  coordinate_check,
  file.path(table_dir, "coordinate_check.csv"),
  row.names = FALSE
)

write.csv(
  annual_quality,
  file.path(table_dir, "annual_quality.csv"),
  row.names = FALSE
)

# -----------------------------------------------------
# 8. Create cleaned, mappable dataset
# -----------------------------------------------------

piracy_mappable <- piracy_data %>%
  filter(
    year >= 2010,
    year <= 2025,
    !is.na(lat_dd),
    !is.na(lon_dd),
    lat_dd >= -90,
    lat_dd <= 90,
    lon_dd >= -180,
    lon_dd <= 180
  )

cat("\n")
cat("Mappable records 2010-2025:", nrow(piracy_mappable), "\n")
cat("\n")

# -----------------------------------------------------
# 9. Save prepared datasets
# -----------------------------------------------------

saveRDS(
  piracy_data,
  file.path(processed_dir, "piracy_data_prepared.rds")
)

saveRDS(
  piracy_mappable,
  file.path(processed_dir, "piracy_mappable_2010_2025.rds")
)

write.csv(
  piracy_mappable,
  file.path(export_dir, "piracy_mappable_2010_2025.csv"),
  row.names = FALSE
)

cat("Prepared datasets saved successfully.\n")
