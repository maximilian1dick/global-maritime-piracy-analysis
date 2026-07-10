# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 08_port_data_preparation.R
# Purpose: Load, clean and export global port data
# Author: Maximilian Dick
# =====================================================

# -----------------------------------------------------
# 1. Initialize project
# -----------------------------------------------------

source("r/scripts/00_init.R")

library(jsonlite)

# -----------------------------------------------------
# 2. Load raw port data
# -----------------------------------------------------

ports_raw <- jsonlite::fromJSON(
  file.path(
    raw_dir,
    "ports.json"
  ),
  flatten = TRUE
)

ports_data <- as.data.frame(ports_raw$ports)

# -----------------------------------------------------
# 3. Clean and prepare port data
# -----------------------------------------------------

ports_data <- ports_data %>%
  mutate(
    latitude = as.numeric(latitude),
    longitude = as.numeric(longitude),
    
    port_name = ifelse(
      is.na(wpi_port_name) | wpi_port_name == "",
      "Unnamed Port",
      wpi_port_name
    ),
    
    port_country = ifelse(
      is.na(country) | country == "",
      "Unknown",
      country
    ),
    
    port_state = ifelse(
      is.na(state) | state == "",
      "Unknown",
      state
    ),
    
    port_size = ifelse(
      is.na(port_size) | port_size == "",
      "Unknown",
      port_size
    ),
    
    max_vessel_size = ifelse(
      is.na(max_vessel_size) | max_vessel_size == "",
      "Unknown",
      max_vessel_size
    )
  ) %>%
  filter(
    !is.na(latitude),
    !is.na(longitude),
    latitude >= -90,
    latitude <= 90,
    longitude >= -180,
    longitude <= 180,
    port_name != "Unnamed Port",
    port_size != "Unknown",
    port_size %in% c("Major", "Minor", "Small")
  ) %>%
  select(
    port_name,
    port_country,
    port_state,
    port_size,
    max_vessel_size,
    latitude,
    longitude,
    everything()
  )

# -----------------------------------------------------
# 4. Quality checks
# -----------------------------------------------------

cat("\n")
cat("========================================\n")
cat(" Port data prepared\n")
cat("========================================\n")
cat("Number of ports:", nrow(ports_data), "\n")
cat("Countries:", length(unique(ports_data$port_country)), "\n")
cat("========================================\n")
cat("\n")

print(
  ports_data %>%
    count(port_size, sort = TRUE)
)

# -----------------------------------------------------
# 5. Export processed port data
# -----------------------------------------------------

write.csv2(
  ports_data,
  file.path(
    processed_dir,
    "ports_processed.csv"
  ),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

saveRDS(
  ports_data,
  file.path(
    processed_dir,
    "ports_processed.rds"
  )
)

cat("Processed port data saved successfully.\n")

