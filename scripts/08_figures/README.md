# 07 — Correspondence with the manuscript

**Language: [English](README.md) | [Español](README.es.md)**

Documentary index; it contains no standalone scripts. The Rmd documents retain their calculations and figures in full. Editorial reference: `MS_Bentic_MG_13_7_2026_review.docx`, including the supplement in its final part; the standalone supplement is an earlier version.

The correspondence is based on reading the manuscript and code, without running analyses or verifying numerical equality. Identifying a relevant block does not certify the selection of a saved editorial version.

## Manuscript products

| Section or product | Identified code or procedure | Scope |
| --- | --- | --- |
| Acquisition and preparation; Table 1 | [Stage 01](../01_data_acquisition/README.md) and [stage 02](../02_data_processing/README.md) | Variable provenance and processing; source table as an editorial synthesis |
| PCA; Table 2 | [11_PCA_REALM.R](../04_pca/04_01_environmental_pca.R) | PCA, variance, and diagnostics; PCA6 decision retained |
| Hypervolumes and niche metrics | [Stage 04](../05_hypervolumes/README.md) | Original procedure, without additional visualizations outside the article |
| Figure 1 | Spatial preparation in stage 02; QGIS capture | External composition; no R generator for the final figure |
| Table 4; Figures 2–3 | [14_Mantel_test_clean.Rmd](../06_global_analyses/06_02_mantel_tests_and_residuals.Rmd) | Global Mantel tests, relationships, and residuals |
| Table 5; Figure 4 | [Residuals_Porifera.Rmd](../06_global_analyses/06_04_porifera_phylogenetic_residuals.Rmd) and [Residuals_Cnidaria.Rmd](../06_global_analyses/06_03_cnidaria_phylogenetic_residuals.Rmd) | Statistics on residuals and external genetic distances; R plots and Affinity assembly |
| Table 6; Figure 5 | [03_expected_vs_observed_cooccurrence.Rmd](../07_local_analyses/07_02_expected_vs_observed_cooccurrence.Rmd) | Quantiles and plots by scale |
| Table 7; Figure 6 | [03_expected_vs_observed_cooccurrence.Rmd](../07_local_analyses/07_02_expected_vs_observed_cooccurrence.Rmd) | Local residuals and comparison across scales |
| Table 3; Figure 7 | [04_Analisis_residuos_locales.R](../07_local_analyses/07_03_local_residual_analysis.R) | Community counts and a relative index, not a calibrated probability |
| Tables 8–9; Figure 8 | [00_Env_data_norway.R](../07_local_analyses/07_04_norway_environmental_models.R) | Original environmental models, summaries, and coefficients |
| Table S2 | [06_Join_Harmonise_Enviromental_Variables.R](../02_data_processing/02_03_Join_Harmonise_Enviromental_Variables.R) | Sediment reclassification block; editorial presentation |
| Figure S3; Table S3 | [00_Env_data_norway.R](../07_local_analyses/07_04_norway_environmental_models.R) | Environmental correlations and VIF |
| S1 | Outline present in the supplement | Table not yet prepared; columns not approved. Do not generate a table or new code |

## Retained analyses and background

- [02_Mantel_Test_Local_Scale.Rmd](../07_local_analyses/07_01_local_mantel_tests.Rmd) is retained as a **study analysis with manuscript correspondence pending**. No explicit passage describing the nine local Mantel tests was found in the reviewed results. They are not presented as published or reclassified as auxiliary because they lack a figure or table. DP025 is a provisional historical reference because it matches the original HTML; DP027 remains a documented alternative and is not declared erroneous.
- The original exploratory blocks are retained without automatically attributing their results to the article. The subsequent model-selection block in the environmental script is not reclassified as a principal analysis.
- B0, B1, C, and D remain separate. Their reported results are retained in the [handoff](../../docs/PROJECT_HANDOFF.md); they do not replace the originals and are not recalculated.

## External procedures and limitations

The genetic analyses were performed by another person using specialized software. The COI/MEGA matrices are previously obtained inputs to the two statistical Rmd documents. Their attribution and documentary provenance still need to be completed using substantiated information, without inventing genetic-analysis code.

Figure 1 is a QGIS capture. The four panels of Figure 4 were exported from R and combined in Affinity, where the illustrations were added. These steps are not automated. Identification of the final editorial files remains pending where alternative copies exist.

`17_Phylogeny.R` and `17_ISA.R` remain excluded. The `16_Hypervolume_Plots.Rmd` variants are not incorporated: their references and hashes remain in the [source inventory](../../docs/source_inventory.csv), without expanding the supplement or creating new scientific scripts.
