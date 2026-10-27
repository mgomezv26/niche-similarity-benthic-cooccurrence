# ============================================================================
# 06_01 - GLOBAL SPECIES CO-OCCURRENCE
# ============================================================================
# Analytical unit: marine MEOW grid cell (0.1 degrees), NOT 50 km.
# A species is present (1) or absent (0) in a cell regardless of the number
# of occurrence records associated with that cell.
# Outputs: number of shared occupied cells and binary Jaccard dissimilarity.

library(here)
library(sf)
library(dplyr)
library(tidyr)
library(vegan)

# 1. Paths -----------------------------------------------------------------
input_file <- here("data", "processed", "grids", "species_grid_assignments.gpkg")
output_dir <- here("results", "global_analyses", "cooccurrence")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(input_file)) {
  stop("Missing species-grid input: ", input_file)
}

# 2. Load presence records and filter species ------------------------------
species_grid <- sf::st_read(input_file, quiet = TRUE)
required <- c("cell_id", "species")
missing <- setdiff(required, names(species_grid))
if (length(missing)) {
  stop("Missing required columns: ", paste(missing, collapse = ", "))
}

# Drop geometry immediately: calculations depend only on cell IDs and species.
# Remove NA/empty species explicitly (the original observed 147 including NA,
# and 146 valid species; do not hardcode a species count).
occurrences <- species_grid |>
  sf::st_drop_geometry() |>
  dplyr::select(cell_id, species) |>
  dplyr::filter(!is.na(cell_id), !is.na(species), nzchar(trimws(as.character(species))))

# Each occupied cell counts once per species, irrespective of repeated records.
presences <- occurrences |>
  dplyr::distinct(cell_id, species)

species_counts <- presences |>
  dplyr::count(species, name = "n_cells") |>
  dplyr::arrange(species)

# Original study criterion: >=10 DISTINCT occupied 0.1-degree grid cells.
species_valid <- species_counts |>
  dplyr::filter(n_cells >= 10L) |>
  dplyr::pull(species)

if (length(species_valid) < 2L) {
  stop("At least two species with >=10 occupied cells are required.")
}

presences <- presences |>
  dplyr::filter(species %in% species_valid)

message("Species with >=10 occupied cells: ", length(species_valid))
message("Unique species-cell presences: ", nrow(presences))
message("Occupied cells in the analysis: ", dplyr::n_distinct(presences$cell_id))

# Save a compact QA table documenting which species passed the cell filter.
utils::write.csv(
  species_counts,
  file.path(output_dir, "species_occupied_cell_counts.csv"),
  row.names = FALSE
)

# 3. Presence-absence matrix (cells x species) ------------------------------
# The original code counted records before binarizing. Directly generating
# presence=1 gives the SAME binary analysis without redundant counting.
presence_wide <- presences |>
  dplyr::mutate(presence = 1L) |>
  tidyr::pivot_wider(
    id_cols = cell_id,
    names_from = species,
    values_from = presence,
    values_fill = 0L,
    names_sort = TRUE
  )

species_columns <- setdiff(names(presence_wide), "cell_id")
pa_matrix <- as.matrix(presence_wide[, species_columns, drop = FALSE])
storage.mode(pa_matrix) <- "numeric"
rownames(pa_matrix) <- as.character(presence_wide$cell_id)
stopifnot(all(pa_matrix %in% c(0, 1)))

# 4. Absolute co-occurrence ------------------------------------------------
# (i, j): number of distinct grid cells occupied by both species;
# diagonal: number of distinct grid cells occupied by each species.
cooc_matrix <- crossprod(pa_matrix)

stopifnot(
  identical(rownames(cooc_matrix), colnames(cooc_matrix)),
  all(diag(cooc_matrix) == colSums(pa_matrix))
)

# Original output names retained to simplify downstream script adaptation.
saveRDS(cooc_matrix, file.path(output_dir, "cooc_matrix.rds"))
utils::write.csv(cooc_matrix, file.path(output_dir, "cooc_matrix_square.csv"))
utils::write.csv(
  as.data.frame(as.table(cooc_matrix)),
  file.path(output_dir, "cooc_matrix_long_format.csv"),
  row.names = FALSE
)

# 5. Jaccard dissimilarity -------------------------------------------------
# vegan::vegdist expects species as ROWS and cells as COLUMNS.
# binary=TRUE ignores abundance and joint absences.
jaccard_dist <- vegan::vegdist(
  t(pa_matrix),
  method = "jaccard",
  binary = TRUE
)
jaccard_matrix <- as.matrix(jaccard_dist)

stopifnot(
  identical(rownames(jaccard_matrix), colnames(jaccard_matrix)),
  identical(rownames(jaccard_matrix), rownames(cooc_matrix))
)

saveRDS(jaccard_matrix, file.path(output_dir, "jaccard_distance_matrix.rds"))
utils::write.csv(
  jaccard_matrix,
  file.path(output_dir, "jaccard_distance_matrix_square.csv")
)
utils::write.csv(
  as.data.frame(as.table(jaccard_matrix)),
  file.path(output_dir, "jaccard_distance_matrix_long_format.csv"),
  row.names = FALSE
)

# 6. Diagnostics -----------------------------------------------------------
upper <- jaccard_matrix[upper.tri(jaccard_matrix)]
message("Species pairs: ", length(upper))
message("Pairs with no shared occupied cells (Jaccard distance = 1): ",
        sum(upper == 1), " (", round(100 * mean(upper == 1), 2), "%)")
message("Outputs saved to: ", output_dir)
