# 03 — Spatial processing

**Language: English | [Español](README.es.md)**

This stage documents the spatial processing steps used to prepare the global marine study grid and associate environmental and species occurrence information with spatial units.

| Script | Purpose |
|---|---|
| `03_01_create_ocean_grid.py` | Creation of the oceanic spatial grid |
| `03_02_assign_meow_realms.R` | Assignment of MEOW marine realms to grid cells |
| `03_03_extract_environmental.R` | Extraction of environmental information for spatial units |
| `03_04_assign_species_to_grid.R` | Assignment of species occurrence records to grid cells |

Some spatial processing steps relied on external GIS operations. The scripts document the original procedures and should not be interpreted as a fully automated workflow.