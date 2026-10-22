# =============================================================================
# 03_03 - EXTRACT ENVIRONMENTAL VARIABLES TO THE MEOW OCEAN GRID
# =============================================================================
# Inputs:
#   data/interim/grids/grid_meow_0.1deg.gpkg
#   data/processed/environmental/raster_standardized_vars_correct_new_vars.tif
# Outputs:
#   data/interim/grids/grid_meow_env_0.1deg.gpkg
#   data/processed/grids/grid_meow_env_clean_0.1deg.gpkg
#
# Original procedure:
# - Extract mean per grid cell for continuous environmental variables.
# - Extract modal sediment size and origin per grid cell.
# - Keep cells with non-missing sediment size, bathymetry and chlorophyll.
# - Do not carry the raw 'sediments' category layer into the final grid.
# =============================================================================

library(here)
library(sf)
library(terra)
library(dplyr)

# 1. Define paths ----------------------------------------------------------
grid_file <- here("data", "interim", "grids", "grid_meow_0.1deg.gpkg")
raster_file <- here("data", "processed", "environmental",
                    "raster_standardized_vars_correct_new_vars.tif")

interim_file <- here("data", "interim", "grids", "grid_meow_env_0.1deg.gpkg")
final_file <- here("data", "processed", "grids", "grid_meow_env_clean_0.1deg.gpkg")

for (path in c(grid_file, raster_file)) {
  if (!file.exists(path)) stop("Required input not found: ", path)
}
dir.create(dirname(interim_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(final_file), recursive = TRUE, showWarnings = FALSE)

# 2. Load inputs -----------------------------------------------------------
grid_meow <- st_read(grid_file, quiet = TRUE)
env_raster <- rast(raster_file)

if (!"cell_id" %in% names(grid_meow)) stop("Grid is missing 'cell_id'.")
if (anyDuplicated(grid_meow$cell_id)) stop("Duplicated 'cell_id' in grid.")
if (is.na(st_crs(grid_meow))) stop("Grid CRS is undefined.")
if (is.na(crs(env_raster)) || crs(env_raster) == "") stop("Raster CRS is undefined.")

# The previous stage produced these names. Assign them explicitly only if the
# TIFF does not preserve them; avoid relying on TIFF band names from GDAL.
expected_names <- c("bathymetry", "o2", "ph", "phyc", "po4", "so",
                    "sws", "thetao", "chl", "sediments",
                    "sediment_size", "z_origin")
if (!all(expected_names %in% names(env_raster))) {
  names_file <- here("data", "processed", "environmental",
                     "layer_names_raster_standardized_vars_correct_new_vars.rds")
  if (!file.exists(names_file)) {
    stop("Raster band names do not match expected names and no names RDS found.")
  }
  saved_names <- readRDS(names_file)
  if (length(saved_names) != nlyr(env_raster)) {
    stop("Saved band names count differs from number of raster bands.")
  }
  names(env_raster) <- saved_names
}
if (!all(expected_names %in% names(env_raster))) {
  stop("Missing raster layers: ",
       paste(setdiff(expected_names, names(env_raster)), collapse = ", "))
}

# Match raster CRS for extraction (without changing grid geometry on disk).
grid_for_extract <- st_transform(grid_meow, crs(env_raster))
grid_vect <- vect(grid_for_extract)

# 3. Extract continuous variables (mean per cell) --------------------------
continuous_names <- c("bathymetry", "o2", "ph", "phyc", "po4",
                      "so", "sws", "thetao", "chl")

mean_values <- terra::extract(
  env_raster[[continuous_names]],
  grid_vect,
  fun = mean,
  na.rm = TRUE
)

if (nrow(mean_values) != nrow(grid_meow) ||
    !identical(mean_values$ID, seq_len(nrow(grid_meow)))) {
  stop("Mean extraction returned unexpected grid row indices.")
}

grid_with_env <- grid_meow
for (column in continuous_names) {
  grid_with_env[[column]] <- mean_values[[column]]
}

# Save intermediate environmental grid (before sediment-based filtering).
st_write(grid_with_env, interim_file, delete_dsn = TRUE, quiet = TRUE)

# 4. Extract sediment categories (mode per cell) ---------------------------
size_values <- terra::extract(env_raster[["sediment_size"]], grid_vect,
                              fun = modal, na.rm = TRUE)
origin_values <- terra::extract(env_raster[["z_origin"]], grid_vect,
                                fun = modal, na.rm = TRUE)

expected_ids <- seq_len(nrow(grid_meow))
if (!identical(size_values$ID, expected_ids) ||
    !identical(origin_values$ID, expected_ids)) {
  stop("Sediment extraction returned unexpected grid row indices.")
}

grid_with_env$r_sediment_size <- size_values[["sediment_size"]]
grid_with_env$r_sediment_origin <- origin_values[["z_origin"]]

# 5. Apply original filtering criteria ------------------------------------
grid_clean <- grid_with_env %>%
  filter(!is.na(r_sediment_size), !is.na(bathymetry), !is.na(chl))

if (nrow(grid_clean) == 0) stop("All cells were removed during filtering.")
if (anyDuplicated(grid_clean$cell_id)) stop("Duplicate cell IDs after filtering.")

# Retains the original grid geometry and the environmental attributes.
# In the historical script 'sediment_size' and 'z_origin' were extracted twice
# (mean then mode), and the mean columns were subsequently removed. Here only
# the modal versions are extracted, avoiding unnecessary work.
st_write(grid_clean, final_file, delete_dsn = TRUE, quiet = TRUE)

message("Input MEOW cells: ", nrow(grid_meow))
message("Cells with complete required values: ", nrow(grid_clean))
message("Intermediate grid: ", interim_file)
message("Final grid: ", final_file)
message("Note: historical manual QGIS geometry edits are not reproduced here.")
