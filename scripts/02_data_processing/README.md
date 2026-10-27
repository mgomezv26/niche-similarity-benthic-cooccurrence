# 03 — Spatial processing

**Language: [English](README.md) | [Español](README.es.md)**

This folder contains the scripts responsible for constructing the global 0.1° ocean grid, assigning MEOW biogeographic regions, extracting environmental variables, and associating benthic species occurrence records with spatial cells.

The objective is to generate a common spatial structure for subsequent analyses of environmental niches, PCA, hypervolumes, and co-occurrence.

## 1. Scripts

| Script | Function | Main output |
| --- | --- | --- |
| `03_01_create_ocean_grid.py` | Generates the global 0.1° grid and removes cells that intersect land. | `grid_ocean_0.1deg.gpkg` |
| `03_02_assign_meow_realms.R` | Assigns MEOW biogeographic regions to ocean cells. | `grid_meow_0.1deg.gpkg` |
| `03_03_extract_environmental.R` | Extracts environmental variables for grid cells and removes cells lacking required environmental information. | `grid_meow_env_clean_0.1deg.gpkg` |
| `03_04_assign_species_to_grid.R` | Assigns species occurrence records to spatial cells. | `species_grid_assignments.gpkg` |

The scripts `03_02`, `03_03`, and `03_04` originate from the reorganization of the former `Assign_MEOW_realms_to_grid.R` file, which combined several spatial and environmental operations.

## 2. Input data

### Ocean grid

The script `03_01_create_ocean_grid.py` uses:

- `data/interim/environmental/r_stack_standardized.tif`: reference raster for defining the spatial extent.
- `data/raw/geography/basemap2.shp`: land map used to exclude cells that intersect land.

The grid is generated at a spatial resolution of **0.1° × 0.1°**.

### MEOW biogeographic regions

The script `03_02_assign_meow_realms.R` uses:

- `data/interim/grids/grid_ocean_0.1deg.gpkg`
- `data/raw/meow/meow_ecos.shp`

The `REALM` and `RLM_CODE` attributes are incorporated through a spatial join by intersection.

### Environmental variables

The script `03_03_extract_environmental.R` uses:

- `data/interim/grids/grid_meow_0.1deg.gpkg`
- `data/processed/environmental/raster_standardized_vars_correct_new_vars.tif`
- `data/processed/environmental/layer_names_raster_standardized_vars_correct_new_vars.rds`

Environmental values are extracted from the rasters harmonized and standardized during the previous stage.

### Species records

The script `03_04_assign_species_to_grid.R` uses the processed occurrence records and the final environmental grid.

The reference file for processed occurrences is:

`data/interim/occurrences/species_data.csv`

## 3. Methodology

### 3.1. Ocean grid creation

**Script:** `03_01_create_ocean_grid.py`

1. Obtains the spatial extent of the reference environmental raster.
2. Constructs a regular global 0.1° grid.
3. Assigns a unique `cell_id` identifier to each cell.
4. Identifies cells that intersect the land map.
5. Excludes those cells to retain only ocean cells.

Two files are generated:

- `grid_global_0.1deg.gpkg`: complete grid.
- `grid_ocean_0.1deg.gpkg`: grid after excluding cells that intersect land.

**Important:** exclusion is based on intersection with land. Coastal cells are not clipped to retain only their marine area.

### 3.2. Assignment of MEOW regions

**Script:** `03_02_assign_meow_realms.R`

1. Loads the ocean grid and MEOW polygons.
2. Checks and harmonizes spatial reference systems.
3. Performs a spatial join by intersection.
4. Incorporates the `REALM` and `RLM_CODE` attributes.
5. Retains only cells with an assigned region.
6. Keeps a single row per `cell_id`.

When a cell intersects several regions, the procedure retains the first match obtained from the spatial join.

The operation assigns biogeographic attributes; it does not clip grid geometries to MEOW boundaries.

### 3.3. Extraction of environmental variables

**Script:** `03_03_extract_environmental.R`

Continuous environmental variables are extracted using their **mean value within each 0.1° cell**.

Continuous variables:

- `bathymetry`
- `o2`
- `ph`
- `phyc`
- `po4`
- `so`
- `sws`
- `thetao`
- `chl`

Categorical sediment-related variables are summarized using their **modal class**:

- `sediment_size`
- `z_origin`

Processing retains the derived fields `r_sediment_size` and `r_sediment_origin`.

Cells without valid values for the required environmental variables are subsequently removed, following the filters in the original procedure.

The result is the final environmental grid used for PCA.

### 3.4. Assignment of species occurrences

**Script:** `03_04_assign_species_to_grid.R`

1. Loads the processed occurrence records.
2. Uses species geographic coordinates for spatial assignment.
3. Associates each record with cells in the final environmental grid.
4. Retains the cell and species identifiers required to construct presence/absence matrices subsequently.
5. Generates the spatial assignment file.

This stage replaces the spatial join previously performed using QGIS.

Exact equivalence with the historical QGIS operation remains pending validation.

## 4. Output files

### Intermediate results

`data/interim/grids/`

| File | Content |
| --- | --- |
| `grid_global_0.1deg.gpkg` | Complete global grid |
| `grid_ocean_0.1deg.gpkg` | Ocean cells after excluding intersections with land |
| `grid_meow_0.1deg.gpkg` | Ocean cells with MEOW biogeographic attributes |
| `grid_meow_env_0.1deg.gpkg` | MEOW grid with extracted environmental values, before final filtering |

### Processed results

`data/processed/grids/`

| File | Content | Subsequent use |
| --- | --- | --- |
| `grid_meow_env_clean_0.1deg.gpkg` | MEOW grid with the final environmental variables | Environmental PCA |
| `species_grid_assignments.gpkg` | Species records associated with grid cells | Hypervolumes and co-occurrence |

These two GeoPackages are the main products of this stage.

## 5. Dependencies and execution order

The scripts must be run in the following order:

1. `03_01_create_ocean_grid.py`
2. `03_02_assign_meow_realms.R`
3. `03_03_extract_environmental.R`
4. `03_04_assign_species_to_grid.R`

**Previous stages:**

- `01_data_acquisition/`: acquisition of records and environmental data.
- `02_data_processing/`: occurrence processing and preparation and harmonization of environmental variables.

**Subsequent stages:**

- `04_pca/04_01_environmental_pca.R`: environmental dimensionality reduction.
- `05_hypervolumes/05_01_build_gaussian_hypervolumes.R`: construction of niche hypervolumes.
- `06_global_analyses/06_01_calculate_global_cooccurrence.R`: calculation of spatial co-occurrence between species.

## 6. Reproducibility and status

The scripts have been reorganized to separate spatial operations and remove the dependency on absolute paths.

The R scripts use `here()`, and the Python script uses project-relative paths.

**Current status: reorganized scripts, pending end-to-end execution and numerical validation against the historical products.**

Before the original results can be considered reproduced, the following must be checked:

- The number of cells generated in the global and ocean grids.
- The exclusion of cells that intersect land.
- The assignment of MEOW regions, particularly for cells intersecting multiple polygons.
- The correspondence of extracted environmental values.
- The filters applied to obtain the final environmental grid.
- The assignment of species records to cells, compared with the historical operation performed in QGIS.
- The preservation of identifiers and species names across stages.

Manual adjustments may have been made in QGIS during the historical processing and are not yet fully documented. These adjustments must be identified before exact reproduction of the original result can be certified.

Large GeoPackages and rasters are currently kept outside the Git repository. The input data must be available to run and validate this workflow.
