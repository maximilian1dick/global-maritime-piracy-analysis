# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 13_master_runner.R
# Purpose: Run complete analysis workflow
# Author: Maximilian Dick
# =====================================================

cat("\n")
cat("========================================\n")
cat(" Starting complete analysis workflow\n")
cat("========================================\n\n")

# -----------------------------------------------------
# Core setup and data preparation
# -----------------------------------------------------

source("r/scripts/00_init.R")
source("r/scripts/01_read_data.R")

# -----------------------------------------------------
# Main analyses
# -----------------------------------------------------

source("r/scripts/02_temporal_analysis.R")
source("r/scripts/03_incident_type_analysis.R")
source("r/scripts/04_waters_type_analysis.R")
source("r/scripts/05_time_of_day_analysis.R")
source("r/scripts/06_hotspot_analysis.R")
source("r/scripts/07_monthly_analysis.R")

# -----------------------------------------------------
# Port and distance analyses
# -----------------------------------------------------

source("r/scripts/08_port_data_preparation.R")
source("r/scripts/09_port_distance_analysis.R")
source("r/scripts/10_distance_to_coast_analysis.R")

# -----------------------------------------------------
# Combined regional analyses
# -----------------------------------------------------

source("r/scripts/11_region_time_incident_analysis.R")

# -----------------------------------------------------
# Weapons analysis
# -----------------------------------------------------

source("r/scripts/12_weapons_analysis.R")

cat("\n")
cat("========================================\n")
cat(" Complete analysis workflow finished\n")
cat(" All outputs were written to output folders\n")
cat("========================================\n\n")
