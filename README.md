# global-maritime-piracy-analysis
Bachelor thesis project: Automated extraction and GIS-based analysis of IMO piracy reports using Python, R and Shiny
# Global Maritime Piracy Analysis (2010–2025)

This repository contains the code, data processing workflows, and analysis scripts developed as part of my Bachelor's thesis on the spatial and temporal analysis of global maritime piracy.

The project develops a reproducible workflow for extracting incident data from monthly IMO Piracy Reports, transforming the extracted information into a GIS-ready dataset, and analyzing global piracy patterns using Python, R, and GIS-based methods.

## Project Overview

The workflow consists of three main components:

1. **Automated Data Extraction (Python)**  
   A rule-based parsing workflow extracts piracy incidents from monthly IMO Piracy Reports and transforms the information into a structured dataset suitable for further analysis.

2. **Spatial and Statistical Analysis (R)**  
   The generated dataset is analyzed using R. The analyses include temporal trends, regional differences, attack types, time-of-day patterns, seasonal patterns, hotspot analyses, and distance analyses related to coastlines and ports.

3. **Interactive Visualization (R Shiny)**  
   An interactive Shiny dashboard enables the exploration of piracy incidents by year, month, region, attack type, and other attributes using point-based and hexagonal map visualizations.

## Repository Structure

- `python/` – Python scripts for PDF processing, information extraction, data transformation, and quality control.
- `r/` – R scripts for data preparation, statistical analysis, spatial analysis, visualization, and the Shiny dashboard.

## Data Sources

The primary data source consists of the monthly piracy reports published by the International Maritime Organization (IMO).

Additional geospatial datasets are used for spatial analyses, including global coastline and port data.

## Methodological Note

The rule-based extraction workflow achieves high agreement with official IMO incident statistics for the reporting period from 2011 to 2020.

Changes in the structure and formatting of the IMO reports from 2021 onwards reduce the completeness of the automated extraction. These limitations are quantified and explicitly considered in the interpretation of the analysis results.

## Reproducibility

The project follows a modular and reproducible workflow. Python is used for automated information extraction and dataset generation, while R is used for data preparation, statistical and spatial analyses, visualization, and the interactive dashboard.

The complete repository, including scripts, documentation, and selected datasets, is currently being finalized and will be made available upon completion of the Bachelor's thesis.

## Author

**Maximilian Dick**

Bachelor's thesis project in Applied Geoinformatics.
