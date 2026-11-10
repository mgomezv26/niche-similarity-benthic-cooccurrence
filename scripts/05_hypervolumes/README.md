# 05 — Hypervolumes and niche metrics

**Language: [English](README.md) | [Español](README.es.md)**

This folder contains the scripts for constructing Gaussian hypervolumes for benthic species and calculating the niche-similarity metrics used in the global analyses. The scripts have been reorganized from the historical code, retaining the original scientific procedure as the reference.

## Scripts and workflow

| Script | Main inputs | Main outputs |
| --- | --- | --- |
| `05_01_build_gaussian_hypervolumes.R` | `data/processed/grids/grid_meow_env_pca6_0.1deg.gpkg`; `data/processed/grids/species_grid_assignments.gpkg` | Individual `.rds` hypervolumes, `hv_list_all_species.RData`, probabilities, and cell counts per species in `results/hypervolumes/gaussian/` |
| `05_02_calculate_hypervolume_overlap.R` | `results/hypervolumes/gaussian/hv_list_all_species.RData` | Individual volumes, species mappings, and pairwise overlap metrics in `results/hypervolumes/overlap/` |
| `05_03_calculate_schoener_d.R` | PCA6 grid, species assignments, and Gaussian hypervolumes | Schoener's D pairs, similarity matrix, and sampled environmental bins in `results/hypervolumes/schoener/` |

Logical execution order: **05_01 → 05_02 and 05_03**. The scripts `05_02` and `05_03` use the results of `05_01` but do not depend on each other.

## Retained methodological decisions

- Hypervolumes are constructed in the environmental space defined by **PC1–PC6**, previously calculated in `04_pca/`.
- The criterion of **at least 10 distinct cells per species** is retained, counting a single presence per species–cell combination.
- Niche estimation uses `hypervolume_gaussian()` and Silverman's bandwidth, following the original script.
- Pairwise comparisons include the overlap and centroid-distance metrics specified in the historical analysis.
- Schoener's D is calculated on common environmental bins, with PCA coordinates rounded to one decimal place, up to 100 000 bins, and sampling weighted by environmental availability; the configured seed is `123`.

**Caution:** the Schoener script links species and hypervolumes by name to avoid ordering mismatches. This safeguard and other cleanup operations may produce differences from historical outputs if the previous code paired elements incorrectly. Numerical equivalence is not considered demonstrated.

## Organization of results

```text
results/
└── hypervolumes/
    ├── gaussian/
    │   ├── hv_list_all_species.RData
    │   ├── hv_probabilities_all_species.rds
    │   ├── hv_probabilities_all_species.csv
    │   ├── hypervolume_<species>.rds
    │   └── ... tables for checking cell counts per species
    ├── overlap/
    │   ├── individual_volumes_all_species.csv
    │   ├── species_hv_names.csv
    │   └── pairwise_hypervolume_overlap_all_species.csv
    └── schoener/
        ├── schoener_D_pairs_round_1_n_100000.csv
        ├── schoener_D_matrix_round_1_n_100000.rds
        └── env_bins_sampled_round_1_n_100000.rds
```

Schoener names with the suffix `n_100000` represent the case in which 100 000 bins are used; the suffix must match the number actually sampled. It was agreed to **retain only these three Schoener products**, avoiding duplicate CSV and RDS files of probabilities and intermediate tables.

## Dependencies on other stages

- **Previous stage:** `04_pca/` generates `grid_meow_env_pca6_0.1deg.gpkg`; `03_spatial_processing/` produces species assignments to the grid.
- **Next stage:** `06_global_analyses/06_02_mantel_tests_and_residuals.Rmd` uses `pairwise_hypervolume_overlap_all_species.csv` and the Schoener's D pairs CSV for the global Mantel tests.

Paths in the reorganized scripts are defined using `here()` from the repository root, identified by `.here`. Input data and large results may be kept outside GitHub but must be available at the expected paths when the analyses are run.

## Status and reproducibility

**Status: reorganized scripts; execution and numerical validation pending.** Neither the hypervolumes nor their metrics have been recalculated or compared with historical results here. The original products will be retained as a reference until agreement in species, pairs, and values has been checked. Historical inventories and hashes, where available, document provenance and do not themselves constitute validation of the new workflow.
