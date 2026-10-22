### ======================================================================= ###
### 03_04 - ASSIGN SPECIES OCCURRENCES TO MEOW GRID CELLS
### ======================================================================= ###
# Reconstructs the spatial step previously performed in QGIS.
# IMPORTANT: The historical QGIS 'Join attributes by location' settings are
# unknown. This version uses st_intersects and keeps ALL point-grid matches
# (one-to-many). It is not guaranteed to reproduce the historical GPKG.

library(here)
library(sf)
library(dplyr)

# 1. Directories -----------------------------------------------------------
# Previously: 01_DATA/02_SPECIES_DATA/Data_Occurrence_period_2000_2020.csv
occurrences_file <- here(
  "data", "interim", "occurrences", "Data_Occurrence_period_2000_2020.csv"
)

# Output from 03_03: environmental grid after filtering missing values
# Only geometry + cell_id + MEOW attributes are retained for this join.
grid_file <- here(
  "data", "processed", "grids", "grid_meow_env_clean_0.1deg.gpkg"
)

occurrences_dir <- here("data", "interim", "occurrences")
output_dir <- here("data", "processed", "grids")
dir.create(occurrences_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

species_csv <- file.path(occurrences_dir, "species_data.csv")
output_file <- file.path(output_dir, "species_grid_assignments.gpkg")

if (!file.exists(occurrences_file)) stop("Input CSV not found: ", occurrences_file)
if (!file.exists(grid_file)) stop("Input grid not found: ", grid_file)

# 2. Filter species records ------------------------------------------------
records <- read.csv(occurrences_file, stringsAsFactors = FALSE)
required_columns <- c("ID", "latitude", "longitude", "species")
if (!all(required_columns %in% names(records))) {
  stop("Occurrence CSV requires columns: ", paste(required_columns, collapse = ", "))
}

# Original criterion: at least 10 RECORDS per species, before spatial join.
records_filtered <- records %>%
  group_by(species) %>%
  filter(n() >= 10) %>%
  ungroup()

species_data <- records_filtered %>%
  select(all_of(required_columns))

write.csv(species_data, species_csv, row.names = FALSE)
message("Species after >=10-record filter: ", n_distinct(species_data$species))
message("Records after filter: ", nrow(species_data))

# 3. Prepare MEOW grid -----------------------------------------------------
grid <- st_read(grid_file, quiet = TRUE)
required_grid <- c("cell_id", "REALM", "RLM_CODE")
if (!all(required_grid %in% names(grid))) {
  stop("Grid requires columns: ", paste(required_grid, collapse = ", "))
}
if (is.na(st_crs(grid))) stop("Grid has no CRS")
if (anyDuplicated(grid$cell_id)) stop("Grid contains duplicate cell_id values")

grid_base <- grid %>% select(all_of(required_grid))

# 4. Assign occurrences to grid -------------------------------------------
# Drop missing or invalid coordinates before creating point geometries.
valid_coordinates <- !is.na(species_data$longitude) &
  !is.na(species_data$latitude) &
  is.finite(species_data$longitude) &
  is.finite(species_data$latitude) &
  species_data$longitude >= -180 & species_data$longitude <= 180 &
  species_data$latitude >= -90 & species_data$latitude <= 90

species_points <- st_as_sf(
  species_data[valid_coordinates, , drop = FALSE],
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
)
species_points <- st_transform(species_points, st_crs(grid_base))

# Uses polygon-point intersection. Boundary points can match multiple cells.
# Keep polygon geometries (as in the historical grid-based QGIS output).
grid_species <- st_join(
  grid_base,
  species_points,
  join = st_intersects,
  left = FALSE
)

# 5. Add grid centroid coordinates ----------------------------------------
# The coordinates below are of GRID CELLS, not original occurrence points.
centroids <- suppressWarnings(st_centroid(st_geometry(grid_species)))
centroid_xy <- st_coordinates(centroids)
grid_species$longitude <- centroid_xy[, 1]
grid_species$latitude <- centroid_xy[, 2]

# 6. Save result -----------------------------------------------------------
# Explicitly overwrite the target GeoPackage when regenerating.
if (file.exists(output_file)) file.remove(output_file)
st_write(grid_species, output_file, driver = "GPKG", quiet = TRUE)

message("Grid-species matches: ", nrow(grid_species))
message("Unique occupied cells: ", n_distinct(grid_species$cell_id))
message("Saved: ", output_file)
