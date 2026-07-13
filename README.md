# Global Maritime Piracy Analysis (2010–2025)

Bachelor's thesis project on the automated extraction, processing, spatial analysis, and interactive visualization of global maritime piracy incidents documented in IMO piracy reports.

This repository contains the Python and R workflows, analysis scripts, selected datasets, and Shiny application developed as part of my Bachelor's thesis in Applied Geoinformatics.

The project implements a reproducible workflow for extracting piracy incident data from monthly IMO Piracy Reports, transforming the extracted information into a GIS-ready dataset, analyzing spatial and temporal patterns of maritime piracy, and providing an interactive web-based visualization of the resulting dataset.

## Interactive Dashboard

An interactive version of the Global Maritime Piracy Monitor is available online:

https://maximilian1dick.shinyapps.io/global-maritime-piracy-monitor/

The dashboard enables the exploration of piracy incidents from 2010 to 2025 using temporal filters, attribute-based filtering, point-based visualization, and hexagonal spatial aggregation.

## Project Overview

The workflow consists of three main components:

1. **Automated Data Extraction (Python)**

   A rule-based parsing workflow extracts piracy incidents from monthly IMO Piracy Reports and transforms the extracted information into a structured, GIS-ready dataset.

   The Python workflow processes the source reports, identifies individual incident records, extracts relevant attributes, standardizes the resulting data, and exports the final master dataset for subsequent analysis.

2. **Spatial and Statistical Analysis (R)**

   The generated dataset is processed and analyzed using R.

   The analyses include:

   - temporal development of piracy incidents,
   - incident and attack types,
   - waters types,
   - time-of-day patterns,
   - monthly and seasonal patterns,
   - spatial hotspot analyses,
   - regional developments,
   - distances between piracy incidents and ports,
   - distances between piracy incidents and coastlines,
   - documented weapons used during piracy incidents.

3. **Interactive Visualization (R Shiny)**

   The interactive Shiny application enables the exploration of the piracy dataset through a web-based map interface.

   The application provides temporal and attribute-based filtering, point-based incident visualization, hexagonal spatial aggregation, port information, and interactive map exploration.

## Repository Structure

```text
global-maritime-piracy-analysis/
│
├── python/
│   └── 00_build_piracy_master_dataset.py
│
├── r/
│   ├── 00_init.R
│   ├── 01_read_data.R
│   ├── 02_temporal_analysis.R
│   ├── 03_incident_type_analysis.R
│   ├── 04_waters_type_analysis.R
│   ├── 05_time_of_day_analysis.R
│   ├── 06_hotspot_analysis.R
│   ├── 07_monthly_analysis.R
│   ├── 08_port_data_preparation.R
│   ├── 09_port_distance_analysis.R
│   ├── 10_distance_to_coast_analysis.R
│   ├── 11_region_time_incident_analysis.R
│   ├── 12_weapons_analysis.R
│   └── master_runner.R
│
├── shiny-app/
│   ├── app.R
│   ├── piracy_mappable_2010_2025.rds
│   ├── ports_processed.rds
│   └── additional application resources
│
├── master_piracy_dataset.csv
├── .gitignore
└── README.md
