# ============================================================================
# 05_02_calculate_hypervolume_overlap.R
# Pairwise overlap and centroid distance of Gaussian environmental hypervolumes
# ============================================================================
# INPUT:
#   results/hypervolumes/gaussian/hv_list_all_species.RData
# OUTPUTS (results/hypervolumes/overlap/):
#   individual_volumes_all_species.csv
#   species_hv_names.csv
#   pairwise_hypervolume_overlap_all_species.csv
#
# Scientific operations kept from the original script:
#   - Individual hypervolume size: get_volume()
#   - Pairwise geometric overlap: hypervolume_set() and
#     hypervolume_overlap_statistics()
#   - Intersection and union hypervolume sizes
#   - Euclidean centroid distance: hypervolume_distance(...,
#     type = "centroid", num.points.max = 1000)
#
# ============================================================================

library(here)
library(hypervolume)

# 1. Paths ------------------------------------------------------------------
input_file <- here("results", "hypervolumes", "gaussian",
                   "hv_list_all_species.RData")
output_dir <- here("results", "hypervolumes", "overlap")

if (!file.exists(input_file)) {
  stop("Hypervolume collection not found: ", input_file,
       "\nRun 05_01_build_gaussian_hypervolumes.R first, or copy the historical ",
       "hv_list_all_species.RData to this location.")
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# 2. Load and validate collection -----------------------------------------
# load() returns the names of objects restored from the RData file.
loaded_objects <- load(input_file)
if (!"hv_list_Species" %in% loaded_objects) {
  stop("Expected an object named 'hv_list_Species' inside: ", input_file)
}
if (!is(hv_list_Species, "HypervolumeList")) {
  stop("hv_list_Species is not a HypervolumeList.")
}

hypervolumes <- hv_list_Species@HVList
n_species <- length(hypervolumes)
if (n_species < 2L) {
  stop("At least two species hypervolumes are required for pairwise overlap.")
}

species_names <- vapply(hypervolumes, function(hv) hv@Name, character(1))
if (anyNA(species_names) || any(!nzchar(species_names)) ||
    anyDuplicated(species_names)) {
  stop("Species names must be present and unique in the HypervolumeList.")
}

message("Loaded ", n_species, " species hypervolumes from: ", input_file)

# 3. Individual volumes and species index ---------------------------------
individual_volumes_df <- data.frame(
  volume = round(as.numeric(get_volume(hv_list_Species)), 4),
  species = species_names,
  stringsAsFactors = FALSE
)
write.csv(individual_volumes_df,
          file.path(output_dir, "individual_volumes_all_species.csv"),
          row.names = FALSE)

species_hv_df <- data.frame(
  species = species_names,
  hv_index = seq_len(n_species),
  stringsAsFactors = FALSE
)
write.csv(species_hv_df,
          file.path(output_dir, "species_hv_names.csv"),
          row.names = FALSE)

# 4. Pairwise overlap and centroid distances -------------------------------
# For 146 species this comprises choose(146, 2) = 10,585 pairs. This can be
# computationally expensive; no parallelism or new sampling configuration is
# introduced here because it could change the historical estimates.

n_pairs <- choose(n_species, 2L)
results <- vector("list", n_pairs)
pair_index <- 0L

for (i in seq_len(n_species - 1L)) {
  for (j in seq.int(i + 1L, n_species)) {
    pair_index <- pair_index + 1L
    hv1 <- hypervolumes[[i]]
    hv2 <- hypervolumes[[j]]

    message("Pair ", pair_index, "/", n_pairs, ": ",
            species_names[[i]], " / ", species_names[[j]])

    # In the original script these operations were accidentally repeated
    # twice per pair; calculating them once retains the intended metrics.
    hv_set <- hypervolume::hypervolume_set(
      hv1, hv2, check.memory = FALSE
    )
    overlap <- hypervolume::hypervolume_overlap_statistics(hv_set)
    hv_distance <- hypervolume::hypervolume_distance(
      hv1, hv2,
      type = "centroid",
      num.points.max = 1000
    )

    # Keep the original output column names and their meaning.
    results[[pair_index]] <- data.frame(
      sp1 = species_names[[i]],
      sp2 = species_names[[j]],
      jaccard = unname(as.numeric(overlap["jaccard"])),
      sorensen = unname(as.numeric(overlap["sorensen"])),
      frac_unique_1 = unname(as.numeric(overlap["frac_unique_1"])),
      frac_unique_2 = unname(as.numeric(overlap["frac_unique_2"])),
      intersection_volume = as.numeric(hv_set@HVList$Intersection@Volume),
      union_volume = as.numeric(hv_set@HVList$Union@Volume),
      distance = as.numeric(hv_distance),
      stringsAsFactors = FALSE
    )
  }
}

pairwise_results <- do.call(rbind, results)
stopifnot(nrow(pairwise_results) == n_pairs)

write.csv(pairwise_results,
          file.path(output_dir, "pairwise_hypervolume_overlap_all_species.csv"),
          row.names = FALSE)

message("Saved individual volumes, species index and ", n_pairs,
        " pairwise comparisons in: ", output_dir)
