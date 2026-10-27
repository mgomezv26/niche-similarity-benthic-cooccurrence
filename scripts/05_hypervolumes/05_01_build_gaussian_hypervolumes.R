# ============================================================================
# 05_01_build_gaussian_hypervolumes.R
# Build Gaussian environmental niche hypervolumes from six PCA axes.
# ============================================================================
# INPUTS:
#   data/processed/grids/grid_meow_env_pca6_0.1deg.gpkg
#   data/processed/grids/species_grid_assignments.gpkg
# OUTPUTS:
#   results/hypervolumes/gaussian/hypervolume_<species>.rds
#   results/hypervolumes/gaussian/hv_list_all_species.RData
#   results/hypervolumes/gaussian/hv_probabilities_all_species.rds
#   results/hypervolumes/gaussian/hv_probabilities_all_species.csv
#   results/hypervolumes/gaussian/species_cell_counts.csv
#   results/hypervolumes/gaussian/species_included.csv
#
# Manuscript choices preserved:
#   - Species with at least 10 DISTINCT grid cells before the environmental join
#   - One occurrence per species / grid cell
#   - Six environmental PCA axes (PC1 through PC6)
#   - Gaussian hypervolumes with Silverman bandwidth
#   - hypervolume_gaussian default density/quantile settings
#   - Per-hypervolume probabilities = ValueAtRandomPoints / sum(densities)
# ============================================================================

library(here)
library(dplyr)
library(sf)
library(hypervolume)

# 1. Input and output paths -------------------------------------------------
pca_grid_file <- here("data", "processed", "grids", "grid_meow_env_pca6_0.1deg.gpkg")
species_grid_file <- here("data", "processed", "grids", "species_grid_assignments.gpkg")
output_dir <- here("results", "hypervolumes", "gaussian")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

for (file in c(pca_grid_file, species_grid_file)) {
  if (!file.exists(file)) stop("Required input not found: ", file)
}

# 2. Read PCA environment grid ----------------------------------------------
message("Reading PCA grid ...")
grid_env <- sf::st_read(pca_grid_file, quiet = TRUE)
data_env <- sf::st_drop_geometry(grid_env)

pca_axes <- paste0("PC", 1:6)
required_env <- c("cell_id", pca_axes)
missing_env <- setdiff(required_env, names(data_env))
if (length(missing_env)) {
  stop("PCA grid is missing fields: ", paste(missing_env, collapse = ", "))
}
if (anyNA(data_env$cell_id) || anyDuplicated(data_env$cell_id)) {
  stop("PCA grid must contain nonmissing, unique cell_id values.")
}
if (!all(vapply(data_env[pca_axes], is.numeric, logical(1)))) {
  stop("PC1 through PC6 must be numeric.")
}

# Only cell_id and the six PCA scores are needed for hypervolume estimation.
# This prevents collisions with duplicate MEOW/environmental attribute names.
pca_by_cell <- data_env %>% select(cell_id, all_of(pca_axes))

# 3. Read species-by-cell assignments ---------------------------------------
message("Reading species assignments ...")
grid_species <- sf::st_read(species_grid_file, quiet = TRUE)
data_species <- sf::st_drop_geometry(grid_species)

required_species <- c("cell_id", "species")
missing_species <- setdiff(required_species, names(data_species))
if (length(missing_species)) {
  stop("Species grid is missing fields: ", paste(missing_species, collapse = ", "))
}

# Omit records without a valid species/cell ID and count distinct occupied
# cells, not the number of underlying occurrence records.
data_species <- data_species %>%
  filter(!is.na(species), trimws(species) != "", !is.na(cell_id))

species_cell_counts <- data_species %>%
  distinct(species, cell_id) %>%
  count(species, name = "n_cells") %>%
  arrange(n_cells, species)

write.csv(species_cell_counts,
          file.path(output_dir, "species_cell_counts.csv"), row.names = FALSE)

species_valid <- species_cell_counts %>%
  filter(n_cells >= 10L) %>%
  pull(species)

message("Species with >= 10 occupied grid cells: ", length(species_valid))
if (!length(species_valid)) stop("No species passed the >= 10-cell filter.")

# 4. Associate each occupied cell with its environmental PCA scores ---------
# Use one species-cell pair only, as in the original distinct() step.
data_hv <- data_species %>%
  filter(species %in% species_valid) %>%
  distinct(species, cell_id) %>%
  left_join(pca_by_cell, by = "cell_id")

# Original workflow later removes missing species, not incomplete PCA scores.
# Missing/non-finite scores cannot be fitted by hypervolume_gaussian; report
# and exclude those cells explicitly (without silently imputing values).
valid_scores <- stats::complete.cases(data_hv[, pca_axes, drop = FALSE]) &
  apply(as.matrix(data_hv[, pca_axes, drop = FALSE]), 1, function(x) all(is.finite(x)))

missing_score_rows <- sum(!valid_scores)
if (missing_score_rows) {
  warning(missing_score_rows,
          " species-cell assignments lack complete finite PCA values; excluding them.")
}
data_hv <- data_hv[valid_scores, , drop = FALSE]

counts_after_join <- data_hv %>%
  count(species, name = "n_cells_with_pca") %>%
  arrange(species)

# Retain all species still represented after the environmental join, mirroring
# the source script (which does not reapply the >= 10-cell filter afterward).
# Warn clearly when the post-join sample would no longer meet that criterion.
low_after_join <- counts_after_join %>% filter(n_cells_with_pca < 10L)
if (nrow(low_after_join)) {
  warning("Species with fewer than 10 valid PCA cells AFTER the join: ",
          paste(low_after_join$species, collapse = ", "),
          ". Inspect results before publication.")
}

write.csv(counts_after_join,
          file.path(output_dir, "species_included.csv"), row.names = FALSE)

species_list <- sort(unique(data_hv$species))
message("Species entering hypervolume calculation: ", length(species_list))
if (!length(species_list)) stop("No valid species-cell observations remain.")

# 5. Build Gaussian hypervolumes --------------------------------------------
# Keep HypervolumeList class and the original file formats for downstream use.
hv_list_Species <- new("HypervolumeList")
hv_list_Species@HVList <- vector("list", length(species_list))
pdf_list <- vector("list", length(species_list))

# File names are derived from the original species names. Replace filesystem-
# unsafe characters only for filenames; preserve the true species name inside
# each hypervolume and probability table.
filename_for_species <- function(species) {
  gsub("[^[:alnum:]_.-]+", "_", species)
}

safe_names <- vapply(species_list, filename_for_species, character(1))
if (anyDuplicated(safe_names)) {
  stop("Species names produce duplicate file names after sanitization; review species labels.")
}

for (i in seq_along(species_list)) {
  sp_name <- species_list[[i]]
  message("Gaussian hypervolume: ", sp_name, " (", i, "/", length(species_list), ")")

  data_Species <- data_hv[data_hv$species == sp_name, pca_axes, drop = FALSE]
  if (nrow(data_Species) < 2L) {
    stop("Not enough PCA cell observations for species: ", sp_name)
  }

  # Preserve the original bandwidth estimator and gaussian hypervolume call.
  hv <- hypervolume::hypervolume_gaussian(
    data = data_Species,
    name = sp_name,
    kde.bandwidth = hypervolume::estimate_bandwidth(
      data_Species, method = "silverman"
    ),
    verbose = TRUE
  )

  saveRDS(hv,
          file = file.path(output_dir, paste0("hypervolume_", safe_names[[i]], ".rds")))
  hv_list_Species@HVList[[i]] <- hv

  # These are the original script's RELATIVE weights over sampled random
  # points, not normalized integration densities over the full PCA space.
  dens <- hv@ValueAtRandomPoints
  dens_total <- sum(dens, na.rm = TRUE)
  if (!is.finite(dens_total) || dens_total <= 0) {
    stop("Invalid density sum for species: ", sp_name)
  }
  probs <- dens / dens_total

  pdf_list[[i]] <- data.frame(
    species = sp_name,
    hv_index = i,
    hv@RandomPoints,
    prob = probs,
    check.names = FALSE
  )
}

# 6. Save complete hypervolume collection and relative probabilities --------
save(hv_list_Species, file = file.path(output_dir, "hv_list_all_species.RData"))

pdf_df <- do.call(rbind, pdf_list)
saveRDS(pdf_df, file = file.path(output_dir, "hv_probabilities_all_species.rds"))
write.csv(pdf_df, file = file.path(output_dir, "hv_probabilities_all_species.csv"),
          row.names = FALSE)

message("Saved Gaussian hypervolumes and relative point probabilities to: ",
        output_dir)
message("Hypervolumes created: ", length(hv_list_Species@HVList))
