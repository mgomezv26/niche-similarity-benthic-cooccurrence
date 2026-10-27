# niche-similarity-benthic-cooccurrence

**Language: [English](README.md) | [Español](README.es.md)**

Documentary archive of the code for the study of niche similarity and co-occurrence in benthic organisms. It preserves 22 selected scientific scripts, their original calculations, and the complete R Markdown documents, organized into seven stages.

**Automated execution and verified numerical reproduction are not provided.** The scripts retain their original write operations and names; identified private paths and authentication fields have been sanitized. The `__CONFIGURE_PATH_*__` placeholders are intentionally nonfunctional. Do not run the copies directly on original files.

| Stage | Documentary content |
| --- | --- |
| [01_data_acquisition](scripts/01_data_acquisition/README.md) | GBIF, OBIS, and CMEMS |
| [02_data_processing](scripts/02_data_processing/README.md) | Occurrences, environment, grids, MEOW, and local presence/absence |
| [03_pca](scripts/04_pca/README.md) | PCA6 procedure |
| [04_hypervolumes](scripts/05_hypervolumes/README.md) | Hypervolumes, overlap, and Schoener's D |
| [05_global_analyses](scripts/06_global_analyses/README.md) | Co-occurrence, Mantel tests, and residuals; statistical analysis using external genetic distances |
| [06_local_analyses](scripts/07_local_analyses/README.md) | MAREANO: quantiles, residuals, community index, and environment; local Mantel tests with manuscript correspondence pending |
| [07_figures](scripts/08_figures/README.md) | Correspondence with figures, tables, and external procedures |

The acquisition, processing, PCA, and hypervolume stages document work already completed; original products are not reconstructed or recalculated. Six PCA components are retained, selected using Broken Stick supplemented by the cumulative explained variance (approximately 89.96%), as is the relative nature of `mean_expected_prob`, which is not a calibrated probability.

The genetic analyses were performed externally by another person using specialized software. The Porifera and Cnidaria Rmd documents statistically analyze residuals and previously obtained genetic matrices; they do not generate those distances. Figure 1 originates from QGIS, and Figure 4 includes assembly in Affinity. No scripts are invented for these procedures.

`17_Phylogeny.R` and `17_ISA.R` remain excluded. B0, B1, C, and D are documented separately as background; their full reports will be retrieved from the work computer without rerunning them. No analyses or supplementary materials are added.

The inventories are neither definitive public manifests nor redistribution authorizations. Data, results, and the manuscript are not published automatically. The code license, authorship/citation, and final editorial review remain pending.

See the [documentation index](docs/README.md), [provenance inventory](docs/source_inventory.csv), [sanitization log](docs/sanitization_log.csv), and [pending publication tasks](docs/technical_pending.md).

The experimental execution infrastructure was removed from the working tree after the scope was redefined; it remains in the Git history. The global Rmd restores the sanitized documentary copy from before its adaptation.
