# =====================================================
# Global Maritime Piracy Monitor
# Bachelor Thesis
#
# Script: 00_init.R
# Purpose: Initialize project environment
# Author: Maximilian Dick
# =====================================================

# -----------------------------------------------------
# 1. Required packages
# -----------------------------------------------------

required_packages <- c(
  "tidyverse",
  "ggplot2",
  "lubridate",
  "sf",
  "leaflet",
  "shiny",
  "spatstat.geom",
  "spatstat.explore",
  "rnaturalearth",
  "rnaturalearthdata",
  "geosphere"
)

# Install missing packages
missing_packages <- required_packages[
  !(required_packages %in% installed.packages()[, "Package"])
]

if(length(missing_packages) > 0) {
  install.packages(missing_packages)
}

# Load packages
invisible(lapply(required_packages, library,
                 character.only = TRUE))

# -----------------------------------------------------
# 2. Project directory
# -----------------------------------------------------

project_dir <- "D:/set/directory"

setwd(project_dir)

# -----------------------------------------------------
# 3. Define project paths
# -----------------------------------------------------

raw_dir        <- file.path(project_dir, "data", "raw")
interim_dir    <- file.path(project_dir, "data", "interim")
processed_dir  <- file.path(project_dir, "data", "processed")

output_dir     <- file.path(project_dir, "output")
figure_dir     <- file.path(output_dir, "figures")
table_dir      <- file.path(output_dir, "tables")
export_dir     <- file.path(output_dir, "exports")

# -----------------------------------------------------
# 4. Create output folders if necessary
# -----------------------------------------------------

dir.create(output_dir,
           recursive = TRUE,
           showWarnings = FALSE)

dir.create(figure_dir,
           recursive = TRUE,
           showWarnings = FALSE)

dir.create(table_dir,
           recursive = TRUE,
           showWarnings = FALSE)

dir.create(export_dir,
           recursive = TRUE,
           showWarnings = FALSE)

# -----------------------------------------------------
# 5. Project information
# -----------------------------------------------------

cat("\n")
cat("========================================\n")
cat(" Global Maritime Piracy Monitor\n")
cat(" Project initialized successfully\n")
cat("========================================\n")
cat("Working Directory:\n")
cat(project_dir, "\n")
cat("========================================\n")
cat("\n")
