# ============================================================================
# 05_03_calculate_schoener_d.R
# Schoener's D between Gaussian niche hypervolumes on a shared PCA environment
# ============================================================================
# INPUTS
#   data/processed/grids/grid_meow_env_pca6_0.1deg.gpkg
#   data/processed/grids/species_grid_assignments.gpkg
#   results/hypervolumes/gaussian/hv_list_all_species.RData
# OUTPUTS
#   results/hypervolumes/schoener/ (sampled bins, normalized densities,
#   pairwise Schoener's D, full D matrix)
# ============================================================================

library(here)
library(dplyr)
library(sf)
library(hypervolume)
library(parallel)

# 1. Configuration ----------------------------------------------------------
input_grid <- here("data", "processed", "grids", "grid_meow_env_pca6_0.1deg.gpkg")
input_species <- here("data", "processed", "grids", "species_grid_assignments.gpkg")
input_hv <- here("results", "hypervolumes", "gaussian", "hv_list_all_species.RData")
output_dir <- here("results", "hypervolumes", "schoener")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

required_files <- c(input_grid, input_species, input_hv)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  stop("Missing input files:\n", paste(missing_files, collapse = "\n"))
}

var_axes <- paste0("PC", 1:6)
digits_round <- 1L
n_target_bins <- 100000L
random_seed <- 123L
# Parallel workers each receive an in-memory copy of the hypervolume list;
# cap the default to avoid excessive memory use on high-core-count machines.
available_cores <- parallel::detectCores(logical = TRUE)
if (is.na(available_cores)) available_cores <- 1L
n_cores <- min(4L, max(1L, available_cores - 1L))

message("PCA axes: ", paste(var_axes, collapse = ", "))
message("Rounding digits: ", digits_round, "; target bins: ", n_target_bins)
message("Parallel workers: ", n_cores)

# 2. Environmental PCA grid -------------------------------------------------
grid_env <- sf::st_read(input_grid, quiet = TRUE)
required_env <- c("cell_id", var_axes)
if (!all(required_env %in% names(grid_env))) {
  stop("Missing PCA grid fields: ", paste(setdiff(required_env, names(grid_env)), collapse = ", "))
}
data_env <- grid_env %>%
  sf::st_drop_geometry() %>%
  distinct(cell_id, .keep_all = TRUE) %>%
  select(cell_id, all_of(var_axes))
if (anyNA(data_env$cell_id)) stop("PCA grid contains missing cell_id values.")
if (!all(vapply(data_env[var_axes], is.numeric, logical(1)))) {
  stop("PC1 to PC6 must be numeric.")
}
if (anyNA(data_env[var_axes]) || any(!is.finite(as.matrix(data_env[var_axes])))) {
  stop("PCA grid contains missing/non-finite scores. Inspect the grid before Schoener's D.")
}
message("Unique grid cells: ", nrow(data_env))

# 3. Common environmental bins ----------------------------------------------
# Replicate the original: round all 6 PC scores, group equal combinations,
# weight bins by the number of original grid cells they represent, sample
# 100,000 bins without replacement weighted by their environmental frequency.
env_bins_full <- data_env %>%
  mutate(across(all_of(var_axes), ~ round(.x, digits = digits_round))) %>%
  group_by(across(all_of(var_axes))) %>%
  summarise(weight_n_cells = n(), cell_id_rep = first(cell_id), .groups = "drop") %>%
  mutate(bin_id = row_number()) %>%
  select(bin_id, cell_id_rep, weight_n_cells, all_of(var_axes))

message("Bins before sampling: ", nrow(env_bins_full))
set.seed(random_seed)
if (nrow(env_bins_full) > n_target_bins) {
  env_bins <- env_bins_full %>%
    slice_sample(n = n_target_bins, weight_by = weight_n_cells) %>%
    mutate(bin_id = row_number())
} else {
  env_bins <- env_bins_full
}
message("Bins after sampling: ", nrow(env_bins))

suffix <- paste0("round_", digits_round, "_n_", nrow(env_bins))
saveRDS(env_bins, file.path(output_dir, paste0("env_bins_sampled_", suffix, ".rds")))
write.csv(env_bins, file.path(output_dir, paste0("env_bins_sampled_", suffix, ".csv")), row.names = FALSE)

env_points_mat <- as.matrix(env_bins[, var_axes, drop = FALSE])
storage.mode(env_points_mat) <- "double"

# 4. Species eligibility ----------------------------------------------------
# Preserve the >=10 DISTINCT cells filter and one presence per cell/species.
# Species are used to check membership; each hypervolume is matched by NAME,
# not by its position in a potentially differently ordered list.
grid_species <- sf::st_read(input_species, quiet = TRUE)
if (!all(c("cell_id", "species") %in% names(grid_species))) {
  stop("Species grid must contain cell_id and species.")
}
data_species <- grid_species %>%
  sf::st_drop_geometry() %>%
  filter(!is.na(species), trimws(species) != "", !is.na(cell_id))

species_valid <- data_species %>%
  distinct(species, cell_id) %>%
  count(species, name = "n_cells") %>%
  filter(n_cells >= 10L) %>%
  pull(species)

# Original code joins the species cells to environmental values and then
# identifies species; maintain that eligibility flow for comparability.
species_in_environment <- data_species %>%
  filter(species %in% species_valid) %>%
  distinct(species, cell_id) %>%
  inner_join(data_env %>% select(cell_id), by = "cell_id") %>%
  distinct(species) %>%
  pull(species)
message("Species >=10 cells: ", length(species_valid))
message("Species matched to PCA grid: ", length(species_in_environment))

# 5. Load existing Gaussian hypervolumes ------------------------------------
hv_workspace <- new.env(parent = emptyenv())
loaded <- load(input_hv, envir = hv_workspace)
if (!("hv_list_Species" %in% loaded)) {
  stop("Expected object 'hv_list_Species' in hv_list_all_species.RData")
}
hv_list_Species <- hv_workspace$hv_list_Species
if (!is(hv_list_Species, "HypervolumeList")) {
  stop("hv_list_Species must be a HypervolumeList.")
}
hv_items <- hv_list_Species@HVList
if (!length(hv_items)) stop("The hypervolume list is empty.")
hv_names <- vapply(hv_items, function(x) x@Name, character(1))
if (anyNA(hv_names) || any(!nzchar(hv_names)) || anyDuplicated(hv_names)) {
  stop("Hypervolume names must be non-empty and unique.")
}
names(hv_items) <- hv_names

# A species with a fitted hypervolume is the authoritative set of outputs of
# 05_01. Report inconsistencies rather than silently pairing the wrong species.
only_hv <- setdiff(hv_names, species_in_environment)
only_grid <- setdiff(species_in_environment, hv_names)
if (length(only_hv) || length(only_grid)) {
  warning("Species membership differs between fitted hypervolumes and current grid. ",
          "HV-only: ", paste(only_hv, collapse = ", "),
          "; grid-only: ", paste(only_grid, collapse = ", "),
          ". Check provenance before interpreting results.")
}
# Compute D for all successfully fitted Gaussian hypervolumes, so Schoener's D
# uses the same species universe as geometric overlap from 05_02.
species_names <- sort(hv_names)
message("Hypervolumes to evaluate: ", length(species_names))

# 6. Evaluate species densities over identical environmental bins ------------
# Fail visibly when estimation fails or yields a zero density total. A zero
# vector is not a valid normalized occupancy distribution for Schoener's D.
evaluate_species <- function(sp, hypervolumes, points, bin_weights) {
  hv <- hypervolumes[[sp]]
  dens <- hypervolume::hypervolume_estimate_probability(hv, points = points)
  if (length(dens) != nrow(points)) {
    stop("Unexpected density vector length for species: ", sp)
  }
  dens[is.na(dens) | dens < 0] <- 0
  if (any(!is.finite(dens))) stop("Non-finite densities for species: ", sp)
  weighted <- as.numeric(dens) * bin_weights
  total <- sum(weighted)
  if (!is.finite(total) || total <= 0) {
    stop("Zero or invalid weighted density for species: ", sp)
  }
  weighted / total
}

if (n_cores > 1L) {
  cl <- parallel::makeCluster(n_cores)
  tryCatch({
    parallel::clusterExport(
      cl,
      c("hv_items", "env_points_mat", "env_bins", "evaluate_species"),
      envir = environment()
    )
    parallel::clusterEvalQ(cl, { library(hypervolume); NULL })
    z_list <- parallel::parLapply(cl, species_names, function(sp) {
      tryCatch(
        list(species = sp, z = evaluate_species(sp, hv_items, env_points_mat,
                                                env_bins$weight_n_cells), error = NULL),
        error = function(e) list(species = sp, z = NULL, error = conditionMessage(e))
      )
    })
  }, finally = {
    parallel::stopCluster(cl)
  })
} else {
  z_list <- lapply(species_names, function(sp) {
    tryCatch(
      list(species = sp, z = evaluate_species(sp, hv_items, env_points_mat,
                                              env_bins$weight_n_cells), error = NULL),
      error = function(e) list(species = sp, z = NULL, error = conditionMessage(e))
    )
  })
}

errors <- vapply(z_list, function(x) !is.null(x$error), logical(1))
if (any(errors)) {
  failed <- vapply(z_list[errors], function(x) paste0(x$species, ": ", x$error), character(1))
  stop("Schoener density evaluation failed; refusing partial results:\n",
       paste(failed, collapse = "\n"))
}

# Construct bins x species matrix; individual columns sum to 1.
Z_mat <- do.call(cbind, lapply(z_list, `[[`, "z"))
colnames(Z_mat) <- species_names
rownames(Z_mat) <- as.character(env_bins$bin_id)
sum_z <- colSums(Z_mat)
if (any(abs(sum_z - 1) > 1e-6)) {
  stop("Not all species densities sum to one.")
}

# Preserve the long-form weighted densities of the original implementation.
z_df <- bind_rows(lapply(seq_along(species_names), function(i) {
  data.frame(
    species = species_names[[i]],
    bin_id = env_bins$bin_id,
    cell_id_rep = env_bins$cell_id_rep,
    weight_n_cells = env_bins$weight_n_cells,
    z = Z_mat[, i]
  )
}))
saveRDS(z_df, file.path(output_dir, paste0("schoener_z_on_common_bins_weighted_", suffix, ".rds")))
write.csv(z_df, file.path(output_dir, paste0("schoener_z_on_common_bins_weighted_", suffix, ".csv")), row.names = FALSE)

# 7. Schoener's D -----------------------------------------------------------
# D(i,j) = 1 - 0.5 * sum_k |p_ik - p_jk|.
# The same bins and weighting are used for all species.
manhattan_dist <- as.matrix(stats::dist(t(Z_mat), method = "manhattan"))
D_mat <- 1 - 0.5 * manhattan_dist
D_mat <- pmax(0, pmin(1, D_mat))
diag(D_mat) <- 1

pair_idx <- which(upper.tri(D_mat), arr.ind = TRUE)
D_results_df <- data.frame(
  sp1 = rownames(D_mat)[pair_idx[, 1]],
  sp2 = colnames(D_mat)[pair_idx[, 2]],
  schoener_D = D_mat[pair_idx],
  stringsAsFactors = FALSE
)

saveRDS(D_mat, file.path(output_dir, paste0("schoener_D_matrix_", suffix, ".rds")))
saveRDS(D_results_df, file.path(output_dir, paste0("schoener_D_pairs_", suffix, ".rds")))
write.csv(D_results_df, file.path(output_dir, paste0("schoener_D_pairs_", suffix, ".csv")), row.names = FALSE)

message("Schoener's D complete: ", length(species_names), " species; ",
        nrow(D_results_df), " unique pairs. Results: ", output_dir)
# ============================================================================
# 05_03_calculate_schoener_d.R
# Schoener's D between Gaussian niche hypervolumes on a shared PCA environment
# Adapted from Calculate_D_Shoener.R; methodological parameters retained.
# ============================================================================
# INPUTS
#   data/processed/grids/grid_meow_env_pca6_0.1deg.gpkg
#   data/processed/grids/species_grid_assignments.gpkg
#   results/hypervolumes/gaussian/hv_list_all_species.RData
# OUTPUTS
#   results/hypervolumes/schoener/ (sampled bins, normalized densities,
#   pairwise Schoener's D, full D matrix)
# ============================================================================

library(here)
library(dplyr)
library(sf)
library(hypervolume)
library(parallel)

# 1. Configuration ----------------------------------------------------------
input_grid <- here("data", "processed", "grids", "grid_meow_env_pca6_0.1deg.gpkg")
input_species <- here("data", "processed", "grids", "species_grid_assignments.gpkg")
input_hv <- here("results", "hypervolumes", "gaussian", "hv_list_all_species.RData")
output_dir <- here("results", "hypervolumes", "schoener")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

required_files <- c(input_grid, input_species, input_hv)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  stop("Missing input files:\n", paste(missing_files, collapse = "\n"))
}

var_axes <- paste0("PC", 1:6)
digits_round <- 1L
n_target_bins <- 100000L
random_seed <- 123L
# Parallel workers each receive an in-memory copy of the hypervolume list;
# cap the default to avoid excessive memory use on high-core-count machines.
available_cores <- parallel::detectCores(logical = TRUE)
if (is.na(available_cores)) available_cores <- 1L
n_cores <- min(4L, max(1L, available_cores - 1L))

message("PCA axes: ", paste(var_axes, collapse = ", "))
message("Rounding digits: ", digits_round, "; target bins: ", n_target_bins)
message("Parallel workers: ", n_cores)

# 2. Environmental PCA grid -------------------------------------------------
grid_env <- sf::st_read(input_grid, quiet = TRUE)
required_env <- c("cell_id", var_axes)
if (!all(required_env %in% names(grid_env))) {
  stop("Missing PCA grid fields: ", paste(setdiff(required_env, names(grid_env)), collapse = ", "))
}
data_env <- grid_env %>%
  sf::st_drop_geometry() %>%
  distinct(cell_id, .keep_all = TRUE) %>%
  select(cell_id, all_of(var_axes))
if (anyNA(data_env$cell_id)) stop("PCA grid contains missing cell_id values.")
if (!all(vapply(data_env[var_axes], is.numeric, logical(1)))) {
  stop("PC1 to PC6 must be numeric.")
}
if (anyNA(data_env[var_axes]) || any(!is.finite(as.matrix(data_env[var_axes])))) {
  stop("PCA grid contains missing/non-finite scores. Inspect the grid before Schoener's D.")
}
message("Unique grid cells: ", nrow(data_env))

# 3. Common environmental bins ----------------------------------------------
# Replicate the original: round all 6 PC scores, group equal combinations,
# weight bins by the number of original grid cells they represent, sample
# 100,000 bins without replacement weighted by their environmental frequency.
env_bins_full <- data_env %>%
  mutate(across(all_of(var_axes), ~ round(.x, digits = digits_round))) %>%
  group_by(across(all_of(var_axes))) %>%
  summarise(weight_n_cells = n(), cell_id_rep = first(cell_id), .groups = "drop") %>%
  mutate(bin_id = row_number()) %>%
  select(bin_id, cell_id_rep, weight_n_cells, all_of(var_axes))

message("Bins before sampling: ", nrow(env_bins_full))
set.seed(random_seed)
if (nrow(env_bins_full) > n_target_bins) {
  env_bins <- env_bins_full %>%
    slice_sample(n = n_target_bins, weight_by = weight_n_cells) %>%
    mutate(bin_id = row_number())
} else {
  env_bins <- env_bins_full
}
message("Bins after sampling: ", nrow(env_bins))

suffix <- paste0("round_", digits_round, "_n_", nrow(env_bins))
saveRDS(env_bins, file.path(output_dir, paste0("env_bins_sampled_", suffix, ".rds")))
write.csv(env_bins, file.path(output_dir, paste0("env_bins_sampled_", suffix, ".csv")), row.names = FALSE)

env_points_mat <- as.matrix(env_bins[, var_axes, drop = FALSE])
storage.mode(env_points_mat) <- "double"

# 4. Species eligibility ----------------------------------------------------
# Preserve the >=10 DISTINCT cells filter and one presence per cell/species.
# Species are used to check membership; each hypervolume is matched by NAME,
# not by its position in a potentially differently ordered list.
grid_species <- sf::st_read(input_species, quiet = TRUE)
if (!all(c("cell_id", "species") %in% names(grid_species))) {
  stop("Species grid must contain cell_id and species.")
}
data_species <- grid_species %>%
  sf::st_drop_geometry() %>%
  filter(!is.na(species), trimws(species) != "", !is.na(cell_id))

species_valid <- data_species %>%
  distinct(species, cell_id) %>%
  count(species, name = "n_cells") %>%
  filter(n_cells >= 10L) %>%
  pull(species)

# Original code joins the species cells to environmental values and then
# identifies species; maintain that eligibility flow for comparability.
species_in_environment <- data_species %>%
  filter(species %in% species_valid) %>%
  distinct(species, cell_id) %>%
  inner_join(data_env %>% select(cell_id), by = "cell_id") %>%
  distinct(species) %>%
  pull(species)
message("Species >=10 cells: ", length(species_valid))
message("Species matched to PCA grid: ", length(species_in_environment))

# 5. Load existing Gaussian hypervolumes ------------------------------------
hv_workspace <- new.env(parent = emptyenv())
loaded <- load(input_hv, envir = hv_workspace)
if (!("hv_list_Species" %in% loaded)) {
  stop("Expected object 'hv_list_Species' in hv_list_all_species.RData")
}
hv_list_Species <- hv_workspace$hv_list_Species
if (!is(hv_list_Species, "HypervolumeList")) {
  stop("hv_list_Species must be a HypervolumeList.")
}
hv_items <- hv_list_Species@HVList
if (!length(hv_items)) stop("The hypervolume list is empty.")
hv_names <- vapply(hv_items, function(x) x@Name, character(1))
if (anyNA(hv_names) || any(!nzchar(hv_names)) || anyDuplicated(hv_names)) {
  stop("Hypervolume names must be non-empty and unique.")
}
names(hv_items) <- hv_names

# A species with a fitted hypervolume is the authoritative set of outputs of
# 05_01. Report inconsistencies rather than silently pairing the wrong species.
only_hv <- setdiff(hv_names, species_in_environment)
only_grid <- setdiff(species_in_environment, hv_names)
if (length(only_hv) || length(only_grid)) {
  warning("Species membership differs between fitted hypervolumes and current grid. ",
          "HV-only: ", paste(only_hv, collapse = ", "),
          "; grid-only: ", paste(only_grid, collapse = ", "),
          ". Check provenance before interpreting results.")
}
# Compute D for all successfully fitted Gaussian hypervolumes, so Schoener's D
# uses the same species universe as geometric overlap from 05_02.
species_names <- sort(hv_names)
message("Hypervolumes to evaluate: ", length(species_names))

# 6. Evaluate species densities over identical environmental bins ------------
# Fail visibly when estimation fails or yields a zero density total. A zero
# vector is not a valid normalized occupancy distribution for Schoener's D.
evaluate_species <- function(sp, hypervolumes, points, bin_weights) {
  hv <- hypervolumes[[sp]]
  dens <- hypervolume::hypervolume_estimate_probability(hv, points = points)
  if (length(dens) != nrow(points)) {
    stop("Unexpected density vector length for species: ", sp)
  }
  dens[is.na(dens) | dens < 0] <- 0
  if (any(!is.finite(dens))) stop("Non-finite densities for species: ", sp)
  weighted <- as.numeric(dens) * bin_weights
  total <- sum(weighted)
  if (!is.finite(total) || total <= 0) {
    stop("Zero or invalid weighted density for species: ", sp)
  }
  weighted / total
}

if (n_cores > 1L) {
  cl <- parallel::makeCluster(n_cores)
  tryCatch({
    parallel::clusterExport(
      cl,
      c("hv_items", "env_points_mat", "env_bins", "evaluate_species"),
      envir = environment()
    )
    parallel::clusterEvalQ(cl, { library(hypervolume); NULL })
    z_list <- parallel::parLapply(cl, species_names, function(sp) {
      tryCatch(
        list(species = sp, z = evaluate_species(sp, hv_items, env_points_mat,
                                                env_bins$weight_n_cells), error = NULL),
        error = function(e) list(species = sp, z = NULL, error = conditionMessage(e))
      )
    })
  }, finally = {
    parallel::stopCluster(cl)
  })
} else {
  z_list <- lapply(species_names, function(sp) {
    tryCatch(
      list(species = sp, z = evaluate_species(sp, hv_items, env_points_mat,
                                              env_bins$weight_n_cells), error = NULL),
      error = function(e) list(species = sp, z = NULL, error = conditionMessage(e))
    )
  })
}

errors <- vapply(z_list, function(x) !is.null(x$error), logical(1))
if (any(errors)) {
  failed <- vapply(z_list[errors], function(x) paste0(x$species, ": ", x$error), character(1))
  stop("Schoener density evaluation failed; refusing partial results:\n",
       paste(failed, collapse = "\n"))
}

# Construct bins x species matrix; individual columns sum to 1.
Z_mat <- do.call(cbind, lapply(z_list, `[[`, "z"))
colnames(Z_mat) <- species_names
rownames(Z_mat) <- as.character(env_bins$bin_id)
sum_z <- colSums(Z_mat)
if (any(abs(sum_z - 1) > 1e-6)) {
  stop("Not all species densities sum to one.")
}

# Preserve the long-form weighted densities of the original implementation.
z_df <- bind_rows(lapply(seq_along(species_names), function(i) {
  data.frame(
    species = species_names[[i]],
    bin_id = env_bins$bin_id,
    cell_id_rep = env_bins$cell_id_rep,
    weight_n_cells = env_bins$weight_n_cells,
    z = Z_mat[, i]
  )
}))
saveRDS(z_df, file.path(output_dir, paste0("schoener_z_on_common_bins_weighted_", suffix, ".rds")))
write.csv(z_df, file.path(output_dir, paste0("schoener_z_on_common_bins_weighted_", suffix, ".csv")), row.names = FALSE)

# 7. Schoener's D -----------------------------------------------------------
# D(i,j) = 1 - 0.5 * sum_k |p_ik - p_jk|.
# The same bins and weighting are used for all species.
manhattan_dist <- as.matrix(stats::dist(t(Z_mat), method = "manhattan"))
D_mat <- 1 - 0.5 * manhattan_dist
D_mat <- pmax(0, pmin(1, D_mat))
diag(D_mat) <- 1

pair_idx <- which(upper.tri(D_mat), arr.ind = TRUE)
D_results_df <- data.frame(
  sp1 = rownames(D_mat)[pair_idx[, 1]],
  sp2 = colnames(D_mat)[pair_idx[, 2]],
  schoener_D = D_mat[pair_idx],
  stringsAsFactors = FALSE
)

saveRDS(D_mat, file.path(output_dir, paste0("schoener_D_matrix_", suffix, ".rds")))
saveRDS(D_results_df, file.path(output_dir, paste0("schoener_D_pairs_", suffix, ".rds")))
write.csv(D_results_df, file.path(output_dir, paste0("schoener_D_pairs_", suffix, ".csv")), row.names = FALSE)

message("Schoener's D complete: ", length(species_names), " species; ",
        nrow(D_results_df), " unique pairs. Results: ", output_dir)
