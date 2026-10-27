# 04 — Principal Component Analysis (PCA)

**Language: [English](README.md) | [Español](README.es.md)**

This folder contains the principal component analysis (PCA) used to reduce environmental dimensionality before constructing niche hypervolumes for benthic species.

The PCA is performed on environmental variables extracted for the 0.1° marine cells belonging to the MEOW biogeographic regions.

## 1. Scripts

| Script | Inputs | Outputs |
| --- | --- | --- |
| `04_01_environmental_pca.R` | `grid_meow_env_clean_0.1deg.gpkg` | Grid with PC1–PC6, explained-variance tables, environmental loadings, and PCA figures |

The script originates from the former `11_PCA_REALM.R` and has been reorganized to use relative paths through `here()`.

## 2. Input data

**Main file:**

`data/processed/grids/grid_meow_env_clean_0.1deg.gpkg`

This GeoPackage is produced by `03_03_extract_environmental.R` and contains the 0.1° marine cells with harmonized and extracted environmental variables.

The ten variables used for PCA are:

- `bathymetry`
- `o2`
- `ph`
- `phyc`
- `po4`
- `so`
- `sws`
- `thetao`
- `chl`
- `r_sediment_size`

The first nine continuous variables were standardized during the previous environmental processing. Sediment size is standardized in the PCA script.

## 3. Methodology

The script performs the following operations:

1. Loads the final environmental grid and temporarily removes geometry for statistical analysis.
2. Selects the ten environmental variables.
3. Standardizes sediment size.
4. Performs PCA using `prcomp()`, with centering and without a second global standardization (`center = TRUE`, `scale. = FALSE`).
5. Calculates the variance explained by each component.
6. Evaluates component importance using the Broken Stick criterion.
7. Retains the first six principal components (PC1–PC6), following the original manuscript analysis.
8. Adds PCA scores to the spatial grid.
9. Exports the final GeoPackage, tables, and figures.

The six selected components jointly explained 89.96% of environmental variance in the historical analysis.

The Broken Stick criterion is retained for component assessment but does not automatically modify the fixed selection of PC1–PC6.

## 4. Output files

### Main GeoPackage

`data/processed/grids/grid_meow_env_pca6_0.1deg.gpkg`

It contains the original grid geometries, environmental attributes, and scores for the six principal components.

This file is a key input for hypervolume and niche-similarity analyses.

### Tables and figures

`results/pca/`

This folder contains auxiliary analysis results, such as:

- Individual and cumulative component variance.
- Comparison with the Broken Stick criterion.
- Environmental component loadings.
- PCA and explained-variance figures.

The specific table and figure names must be checked against the script's exports.

## 5. Dependencies

**Previous stage:**

`03_spatial_processing/03_03_extract_environmental.R`

**Next stage:**

`05_hypervolumes/05_01_build_gaussian_hypervolumes.R`

Processing workflow:

`0.1° environmental grid → PCA → PC1–PC6 per cell → Gaussian hypervolumes`

## 6. Reproducibility and status

The script has been reorganized from the original analysis, preserving the variable selection, PCA procedure, Broken Stick, and six components used in the manuscript.

A complete run and numerical validation of the reorganized version have not yet been performed.

Before the historical results can be considered reproduced, the following must be checked:

- The number of environmental cells included.
- The absence of missing values in the selected variables.
- The cumulative variance of PC1–PC6 against the historical 89.96%.
- The environmental loadings and component scores.
- The correspondence between the historical and new GeoPackages.

Large spatial datasets are currently kept outside the Git repository. The code should allow the products to be regenerated when the input files are available.
