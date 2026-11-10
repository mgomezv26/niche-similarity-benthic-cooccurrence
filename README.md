# niche-similarity-benthic-cooccurrence

**Language: [English](README.md) | [Español](README.es.md)**

Documentary archive of the code for the study of niche similarity and co-occurrence in benthic organisms. It preserves 22 selected scientific scripts, their original calculations, and the complete R Markdown documents, organized into seven stages.


| Stage | Documentary content |
| --- | --- |
| [01_data_acquisition](scripts/01_data_acquisition/README.md) | GBIF, OBIS, and CMEMS |
| [02_data_processing](scripts/02_data_processing/README.md) | Occurrences, environment, grids, MEOW, and local presence/absence |
| [03_spatial_processing](scripts/03_spatial_processing/README.md) | Ocean grid creation, MEOW realm assignment, environmental extraction, and species-to-grid assignment |
| [04_pca](scripts/04_pca/README.md) | PCA6 procedure |
| [05_hypervolumes](scripts/05_hypervolumes/README.md) | Hypervolumes, overlap, and Schoener's D |
| [06_global_analyses](scripts/06_global_analyses/README.md) | Co-occurrence, Mantel tests, and residuals; statistical analysis using external genetic distances |
| [07_local_analyses](scripts/07_local_analyses/README.md) | MAREANO: quantiles, residuals, community index, and environment; local Mantel tests with manuscript correspondence pending |
| [08_figures](scripts/08_figures/README.md) | Correspondence with figures, tables, and external procedures |

The genetic analyses were performed externally by another person using specialized software. The Porifera and Cnidaria Rmd documents statistically analyze residuals and previously obtained genetic matrices; they do not generate those distances. Figure 1 originates from QGIS, and Figure 4 includes assembly in Affinity. No scripts are invented for these procedures.

## Data availability

The datasets and analytical outputs associated with this study are available on Figshare:

**Dataset:** *Environmental niche similarity and local co-occurrence of marine benthic species: Data and analytical outputs*

**Figshare DOI:** [Add DOI after publication]

The dataset contains environmental and spatial data, processed species occurrence information, environmental niche hypervolume outputs, global niche-overlap and co-occurrence matrices, and local community data from Norwegian benthic surveys.

The deposited files retain their original directory structure:

- `data/` — Environmental and spatial data, species occurrence data, and local community datasets.
- `results/` — Hypervolume outputs, niche similarity matrices, statistical results, and figures.

To use the data alongside the scripts in this repository, extract the dataset into the repository root, preserving the original directory names and relative paths.

Some upstream datasets originate from external providers and are subject to their respective citation and reuse conditions.