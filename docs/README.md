# Documentation of the study code

**Language: [English](README.md) | [Español](README.es.md)**

- source_inventory.csv: 64 source files inventoried; 22 incorporated and 42 recorded without copying.
- sanitization_log.csv: location and class of each public substitution, without original private values.
- integrity_summary.csv: integrity checks for sources, copies, validations, and the manuscript.
- public_copy_review.md: scope and limitations of the review.
- technical_pending.md: current pending publication tasks and earlier technical planning identified as historical.
- dependencies_observed.csv: libraries declared in the scripts, without installation or version pinning.

Source paths are expressed relative to the folders 07_GitHub, Niche_bentic_species, 02_DATA_GENOVEVA, 05_ENVIROMENTAL_VARIABLES, and 08_GRID_BASE. The personal location of these folders is deliberately omitted. The combination source_root + source_relative_path identifies each source, together with its SHA256.

The statuses copied_identical and copied_sanitized_configuration distinguish binary identity from configuration sanitization. The not_copied_* statuses document earlier versions, exploration, duplicates, or pending provenance; they do not imply that these files have been demonstrated to lack scientific value.

The selected scripts are the principal sources identified to document the workflow. This alone does not certify that each file, if run from scratch today, would reconstruct all final products.

- [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md): scientific decisions and validation background; the initial update distinguishes the current scope from the historical record.
- [data_product_inventory.md](data_product_inventory.md) and [data_product_inventory.csv](data_product_inventory.csv): 121 products documented with hashes and versions, without redistribution approval.
- [Correspondence with the manuscript](../scripts/08_figures/README.md): tables, figures, retained analyses, and external procedures.

The current objective is a documentary archive, without promising automation or verified numerical reproduction. Review and integrity reports retain their historical dates and evidence; they do not become certifications of execution. The removed infrastructure remains in the Git history. Inventories are not regenerated, and hashes or sanitization records are not deleted.
