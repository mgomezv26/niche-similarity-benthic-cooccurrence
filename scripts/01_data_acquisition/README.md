# 01 — Acquisition and preparation of original data

**Language: [English](README.md) | [Español](README.es.md)**

This folder contains the scripts used to obtain occurrence records for benthic species and prepare environmental data from external sources.

The data used in the study come mainly from **GBIF, OBIS, Bio-ORACLE, Copernicus Marine Service, and marine sediment maps**.

The objective of this stage is to preserve the original sources and prepare the products required for subsequent environmental and spatial processing.

## 1. Scripts

| Script | Function | Main products |
| --- | --- | --- |
| `01_01_GBIF_download.R` | Downloads species occurrence records from GBIF. | Original GBIF occurrence data |
| `01_02_OBIS_download.R` | Downloads species occurrence records from OBIS. | Original OBIS occurrence data |
| `01_03_Enviromental_Variables.R` | Prepares Bio-ORACLE environmental variables and sediment maps. | Intermediate environmental rasters |
| `01_04_Download_Copernicus.py` | Downloads chlorophyll data from Copernicus Marine Service for the study period. | Original Copernicus oceanographic files |

The scripts have been reorganized and renamed to maintain nomenclature consistent with the other project stages.

## 2. Data sources

### 2.1. GBIF — Global Biodiversity Information Facility

**Script:** `01_01_GBIF_download.R`

GBIF provides species presence records from scientific collections, observations, and other biodiversity sources.

The downloaded records are one of the principal sources for constructing the study's occurrence database.

Cleaning, harmonization, and integration with OBIS records are performed subsequently in `02_data_processing/`.

### 2.2. OBIS — Ocean Biodiversity Information System

**Script:** `01_02_OBIS_download.R`

OBIS provides georeferenced records of marine species.

These data complement the GBIF records and extend the spatial coverage of benthic organism occurrences.

The two sources are integrated in the occurrence-processing scripts of stage 02.

### 2.3. Bio-ORACLE

**Script:** `01_03_Enviromental_Variables.R`

Bio-ORACLE provides marine environmental variables used to characterize the ecological conditions of benthic organisms.

The study uses environmental data for the following periods:

- 2000–2010.
- 2010–2020.

The products from both periods are combined to represent environmental conditions over the study interval.

The variables considered include bathymetry, dissolved oxygen, pH, productivity, nutrients, salinity, current velocity, and temperature.

The final selection of predictors and their spatial harmonization are performed subsequently in `02_03_Join_Harmonise_Enviromental_Variables.R`.

### 2.4. Marine sediments

**Script:** `01_03_Enviromental_Variables.R`

Information on marine substrate composition is incorporated from a classification of seafloor lithology.

The original source contains sediment categories that subsequently allow variables to be derived for:

- Sediment size.
- The organic or inorganic origin of the material.

Sediment classes are treated as categorical information during spatial processing.

### 2.5. Copernicus Marine Service

**Script:** `01_04_Download_Copernicus.py`

Copernicus Marine Service provides the chlorophyll concentration data used in the study as an indicator of marine productivity conditions.

The reference period is **2000–2020**.

The downloaded products are subsequently processed to obtain a temporal mean representation compatible with the other environmental variables.

The exact transformation of the original Copernicus files into the final mean raster must be checked and documented before this stage can be considered fully reproducible.

## 3. Data organization

The original and intermediate files are organized using the following structure:

```text
data/
├── raw/
│   ├── occurrences/
│   ├── bio_oracle/
│   │   ├── 2000_2010/
│   │   └── 2010_2020/
│   └── seafloor_sediments/
│
└── interim/
    ├── bio_oracle/
    │   └── raster_stack_biooracle_2000_2020.tif
    └── cmems/
        └── chl_mean_2000_2020_v0.tif
```

Original occurrence files are retained in `data/raw/occurrences/`.

The original Bio-ORACLE and sediment NetCDF files are kept separate from the derived rasters.

**Note:** this structure documents the intended organization of the products. The exact GBIF, OBIS, and Copernicus download paths must be checked against the scripts and their configurations before rerunning the workflow.

## 4. General methodology

### Downloading occurrence records

The GBIF and OBIS scripts obtain georeferenced records for the species considered in the study.

Source data are retained at this stage. Cleaning and harmonization are performed in the next stage.

### Preparing Bio-ORACLE variables

Environmental data from 2000–2010 and 2010–2020 are combined to obtain variables representative of the study interval.

The resulting rasters are subsequently used as a reference for harmonizing chlorophyll and sediment data.

### Preparing chlorophyll data

Chlorophyll data from Copernicus are used to obtain a mean product for 2000–2020.

The historical processing from downloaded files to the mean raster is not yet fully documented.

### Preparing sediment data

The original lithological classification is retained for subsequent transformation into the categorical variables used in the environmental analysis.

## 5. Dependencies and processing workflow

**Current stage:**

`01_data_acquisition/`

**Next stage:**

`02_data_processing/`

The stage 02 scripts use the products obtained here to:

1. Process the original occurrence records.
2. Integrate data from GBIF and OBIS.
3. Prepare and harmonize environmental predictors.
4. Evaluate correlations among environmental variables.
5. Generate the final environmental rasters.

Subsequently, `03_spatial_processing/` extracts these values for the 0.1° marine cells.

## 6. Reproducibility and status

The scripts have been organized according to the data sources used in the manuscript.

**Current status: reorganized code, pending end-to-end execution and validation against the historical products.**

Before this stage can be considered reproduced, the following must be checked:

- The queries and parameters used for GBIF and OBIS downloads.
- The temporal and taxonomic filters applied.
- The correspondence between downloaded records and retained original files.
- The Bio-ORACLE variables and time periods.
- The parameters used to download Copernicus data.
- The procedure for obtaining mean chlorophyll for 2000–2020.
- The correspondence between original sediment categories and derived variables.
- The versions and references of the original environmental products.

Large original datasets are currently retained outside the Git repository, in the project's external storage.

The repository contains the scripts required to document and reconstruct the procedure, but **exact reproduction of the historical products has not yet been certified**.
