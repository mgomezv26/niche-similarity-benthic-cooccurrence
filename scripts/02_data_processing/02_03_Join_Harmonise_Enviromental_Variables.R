### ======================================================================= ###
###       JOIN AND HARMONISE ENVIRONMENTAL VARIABLES — BENTHIC STUDY
### ======================================================================= ###
# This script keeps the original analysis workflow:
# - Bio-ORACLE geometry as reference (0.05 degrees)
# - nearest-neighbour for categorical sediment; bilinear for chlorophyll
# - global z-scores for nine continuous variables
# - original sediment reclassification codes
#
# Sediments are loaded directly from the ORIGINAL NetCDF.
# Confirm equivalence to the historical dummy GeoTIFF before using in publication.

library(here)
library(terra)

# ============================================================
# R AND PACKAGE VERSIONS
# ============================================================
# Versions from the current runtime, not the historical analysis environment.

cat("R version:", R.version.string, "\n") # R version: 4.5.1 (2025-06-13 ucrt)

cat("Versions of the libraries used:\n")
cat("here:", as.character(packageVersion("here")), "\n") # here: 1.0.2
cat("terra:", as.character(packageVersion("terra")), "\n") # terra: 1.8.54
cat("raster:", as.character(packageVersion("raster")), "\n") # raster: 3.6.32

# 1. Paths ---------------------------------------------------------------
bio_file <- here("data", "interim", "bio_oracle",
                 "raster_stack_biooracle_2000_2020.tif")
chl_file <- here("data", "interim", "cmems",
                 "chl_mean_2000_2020_v0.tif")
sediments_file <- here("data", "raw", "seafloor_sediments",
                       "seabed_lithology_v1.nc")

interim_dir <- here("data", "interim", "environmental")
processed_dir <- here("data", "processed", "environmental")
dir.create(interim_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

required_files <- c(bio_file, chl_file, sediments_file)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop("Missing input file(s):\n", paste(missing_files, collapse = "\n"),
       "\nCheck the repository folder structure and filenames.")
}

# 2. Load and inspect inputs ---------------------------------------------
bio <- rast(bio_file)
chl <- rast(chl_file)
sediments <- rast(sediments_file)

print(bio)
print(chl)
print(sediments)
print(list(bio_resolution = res(bio), chl_resolution = res(chl),
           sediment_resolution = res(sediments)))

if (!same.crs(bio, chl) || !same.crs(bio, sediments)) {
  stop("Input CRS differ. Reprojection must be examined explicitly before resampling.")
}
if (nlyr(chl) != 1L || nlyr(sediments) != 1L) {
  stop("Expected one chlorophyll layer and one sediment layer.")
}

# Explicit historical layer names: verify before changing them.
names(chl) <- "chl_mean_2000_2020_v0"
names(sediments) <- "z"

# 3. Spatial harmonisation -----------------------------------------------
ref_extent <- ext(bio)
sediments <- crop(sediments, ref_extent)
chl <- crop(chl, ref_extent)

sediments <- resample(sediments, bio, method = "near")
chl <- resample(chl, bio, method = "bilinear")
stopifnot(compareGeom(bio, sediments), compareGeom(bio, chl))

stack_all <- c(bio, chl, sediments)
writeRaster(stack_all, file.path(interim_dir, "r_stack_all.tif"), overwrite = TRUE)

# 4. Exploratory collinearity assessment (0.05-degree raster) --------------
# Pearson correlations are evaluated BEFORE excluding candidate variables.
# This is a reproducible random sample of raster cells, not necessarily the
# exact dataset used for the historical manuscript coefficients.
# Sediment codes are categorical and are intentionally excluded.
correlation_dir <- here("results", "environmental_collinearity")
dir.create(correlation_dir, recursive = TRUE, showWarnings = FALSE)

candidate_vars <- c(
  "bathymetry_mean", "dfe_mean", "no3_mean", "o2_mean",
  "ph_mean", "phyc_mean", "po4_mean", "si_mean", "so_mean",
  "swd_mean", "sws_mean", "thetao_mean", "chl_mean_2000_2020_v0"
)
missing_candidates <- setdiff(candidate_vars, names(stack_all))
if (length(missing_candidates) > 0L) {
  stop("Missing candidate layers for correlation: ",
       paste(missing_candidates, collapse = ", "))
}

# Use a fixed seed so repeated runs select the same sample.
# na.rm = TRUE keeps only cells with values for all candidate layers.
set.seed(123)
cor_sample_size <- 100000L
cor_data <- terra::spatSample(
  stack_all[[candidate_vars]], size = cor_sample_size,
  method = "random", na.rm = TRUE, as.df = TRUE
)
cor_data <- cor_data[stats::complete.cases(cor_data), , drop = FALSE]
if (nrow(cor_data) < 3L) {
  stop("Insufficient complete raster cells for Pearson correlations.")
}

cor_matrix <- stats::cor(cor_data, method = "pearson")
if (any(!is.finite(cor_matrix))) {
  stop("Undefined correlations. Check for constant candidate layers.")
}
stats::write.csv(cor_matrix,
                 file.path(correlation_dir, "correlation_matrix_005deg.csv"))

# One row per unique pair above the manuscript's absolute-r threshold.
cor_threshold <- 0.75
pair_idx <- which(upper.tri(cor_matrix) & abs(cor_matrix) > cor_threshold,
                  arr.ind = TRUE)
high_correlations <- data.frame(
  variable_1 = rownames(cor_matrix)[pair_idx[, 1]],
  variable_2 = colnames(cor_matrix)[pair_idx[, 2]],
  pearson_r = cor_matrix[pair_idx],
  abs_r = abs(cor_matrix[pair_idx])
)
high_correlations <- high_correlations[
  order(-high_correlations$abs_r), , drop = FALSE
]
utils::write.csv(high_correlations,
                 file.path(correlation_dir, "high_correlations_005deg.csv"),
                 row.names = FALSE)
print(high_correlations)

# Diagnostic heatmap; no clustering/reordering of candidate variables.
grDevices::png(file.path(correlation_dir, "correlation_heatmap_005deg.png"),
               width = 1500, height = 1250, res = 160)
heatmap(cor_matrix, Rowv = NA, Colv = NA, scale = "none",
        symm = TRUE, margins = c(12, 12),
        main = "Environmental Pearson correlations (0.05 degree sample)")
grDevices::dev.off()

writeLines(c(
  "Exploratory Pearson correlations on harmonised 0.05-degree raster cells.",
  paste0("Random seed: 123; requested sample size: ", cor_sample_size),
  paste0("Complete sampled cells used: ", nrow(cor_data)),
  paste0("Absolute correlation threshold: ", cor_threshold),
  "Complete cases for all candidate continuous variables; no categorical sediments.",
  "This sampled analysis does not verify the historical manuscript r values.",
  "The historical final variable selection is kept unchanged below."
), file.path(correlation_dir, "correlation_method.txt"))

# 5. Select historical study variables ------------------------------------
vars_mean <- c("bathymetry_mean", "o2_mean", "ph_mean", "phyc_mean",
               "po4_mean", "so_mean", "sws_mean", "thetao_mean",
               "chl_mean_2000_2020_v0", "z")
missing_layers <- setdiff(vars_mean, names(stack_all))
if (length(missing_layers)) {
  stop("Missing expected raster layers: ", paste(missing_layers, collapse = ", "))
}
stack_mean <- stack_all[[vars_mean]]
writeRaster(stack_mean, file.path(interim_dir, "r_stack_mean.tif"), overwrite = TRUE)

# 6. Global z-scores (continuous variables only) --------------------------
# terra::global uses population SD for some summaries; the historical script
# used raster::cellStats(..., 'sd'). Retain that exact operation to minimise
# unintended differences from the original analysis.
continuous_names <- setdiff(vars_mean, "z")
standardized_layers <- vector("list", length(continuous_names))
for (i in seq_along(continuous_names)) {
  layer <- stack_mean[[continuous_names[i]]]
  old_layer <- raster::raster(layer)
  mu <- raster::cellStats(old_layer, stat = "mean")
  sigma <- raster::cellStats(old_layer, stat = "sd")
  if (!is.finite(sigma) || sigma == 0) {
    stop("Invalid standard deviation for: ", continuous_names[i])
  }
  standardized_layers[[i]] <- (layer - mu) / sigma
}
continuous_standardized <- do.call(c, standardized_layers)
names(continuous_standardized) <- continuous_names
stack_standardized <- c(continuous_standardized, stack_mean[["z"]])
names(stack_standardized)[nlyr(stack_standardized)] <- "z"

writeRaster(stack_standardized,
            file.path(interim_dir, "r_stack_standardized.tif"),
            overwrite = TRUE)
saveRDS(names(stack_standardized),
        file.path(interim_dir, "layer_names_r_stack_standardized.rds"))

# 7. Reclassify sediment codes --------------------------------------------
# IMPORTANT: These are codes from the historical script, NOT an independently
# validated mapping for a different sediment raster.
sediment_size_map <- matrix(c(
  1,5, 2,3, 3,1, 4,2, 5,1, 6,1, 7,1,
  8,3, 9,1, 10,4, 11,5, 12,1, 13,2
), ncol = 2, byrow = TRUE)

sediment_origin_map <- matrix(c(
  1,1, 2,1, 3,1, 4,1, 5,1, 6,2, 7,2,
  8,2, 9,1, 10,2, 11,1, 12,1, 13,1
), ncol = 2, byrow = TRUE)

sediment_codes <- stack_standardized[["z"]]
# Keep unexpected non-NA sediment codes from silently escaping classification.
frequency <- freq(sediment_codes)
observed_codes <- if (is.null(frequency)) numeric(0) else frequency[, "value"]
if (length(observed_codes) == 0L) stop("No valid sediment codes found after harmonisation.")
unexpected <- setdiff(observed_codes, 1:13)
if (length(unexpected)) {
  stop("Unexpected sediment codes: ", paste(unexpected, collapse = ", "),
       ". Check the original NetCDF category codes.")
}

sediment_size <- classify(sediment_codes, rcl = sediment_size_map,
                          others = NA)
names(sediment_size) <- "sediment_size"
sediment_origin <- classify(sediment_codes, rcl = sediment_origin_map,
                            others = NA)
names(sediment_origin) <- "z_origin"
levels(sediment_origin) <- data.frame(
  value = c(1, 2), origin = c("Inorgánico", "Orgánico")
)

# 8. Final stack ----------------------------------------------------------
final_stack <- c(stack_standardized, sediment_size, sediment_origin)
names(final_stack) <- c("bathymetry", "o2", "ph", "phyc", "po4", "so",
                        "sws", "thetao", "chl", "sediments",
                        "sediment_size", "z_origin")

final_file <- file.path(processed_dir,
                        "raster_standardized_vars_correct_new_vars.tif")
writeRaster(final_stack, final_file, overwrite = TRUE)
saveRDS(names(final_stack),
        file.path(processed_dir,
                  "layer_names_raster_standardized_vars_correct_new_vars.rds"))

print(final_stack)
message("Final environmental raster: ", final_file)
