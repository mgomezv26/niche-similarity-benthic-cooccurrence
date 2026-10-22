# =============================================================================
# 03_02 - ASSIGN MEOW REALMS TO THE OCEAN GRID
# =============================================================================
# Input:
#   data/interim/grids/grid_ocean_0.1deg.gpkg
#   data/raw/meow/meow_ecos.shp (+ associated shapefile components)
# Output:
#   data/interim/grids/grid_meow_0.1deg.gpkg
#
# Historical method: spatial join by intersection; retain cells with a REALM;
# when a cell intersects multiple MEOW polygons, keep the first joined match.
# This does NOT clip grid-cell geometry to MEOW boundaries.
# =============================================================================

library(here)
library(sf)
library(dplyr)

# 1. Project paths ---------------------------------------------------------
grid_file <- here("data", "interim", "grids", "grid_ocean_0.1deg.gpkg")
meow_file <- here("data", "raw", "meow", "meow_ecos.shp")
output_file <- here("data", "interim", "grids", "grid_meow_0.1deg.gpkg")

if (!file.exists(grid_file)) stop("Missing ocean grid: ", grid_file)
if (!file.exists(meow_file)) stop("Missing MEOW shapefile: ", meow_file)
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)

# 2. Read and prepare geometries ------------------------------------------
grid_ocean <- st_read(grid_file, quiet = TRUE)
meow <- st_read(meow_file, quiet = TRUE)

if (!"cell_id" %in% names(grid_ocean)) stop("Ocean grid has no 'cell_id' column.")
if (!all(c("REALM", "RLM_CODE") %in% names(meow))) {
  stop("MEOW shapefile must contain 'REALM' and 'RLM_CODE'.")
}
if (is.na(st_crs(grid_ocean)) || is.na(st_crs(meow))) {
  stop("Both spatial inputs must have a defined CRS.")
}

# Match coordinate systems before spatial join.
if (st_crs(meow) != st_crs(grid_ocean)) {
  meow <- st_transform(meow, st_crs(grid_ocean))
}

# Preserve original behavior: first existing row per cell_id.
grid_geom <- grid_ocean %>%
  group_by(cell_id) %>%
  slice(1) %>%
  ungroup() %>%
  select(cell_id)

# Original workflow repaired grid geometries before the join.
grid_geom <- st_make_valid(grid_geom)

# 3. Assign MEOW realms ----------------------------------------------------
# Retain the original planar (s2 disabled) spatial join behavior.
previous_s2 <- sf_use_s2()
sf_use_s2(FALSE)

grid_realms <- st_join(
  grid_geom,
  meow[, c("REALM", "RLM_CODE")],
  join = st_intersects,
  left = TRUE
)

sf_use_s2(previous_s2)

# Keep only cells matching MEOW; take first match for multiply matched cells.
# The first match depends on the order of polygons in the source shapefile.
grid_meow <- grid_realms %>%
  filter(!is.na(REALM)) %>%
  group_by(cell_id) %>%
  slice(1) %>%
  ungroup()

if (anyDuplicated(grid_meow$cell_id)) stop("Duplicated cell_id in output.")
if (nrow(grid_meow) == 0) stop("No ocean cells intersect MEOW polygons.")

# 4. Export ---------------------------------------------------------------
st_write(grid_meow, output_file, delete_dsn = TRUE, quiet = TRUE)

message("MEOW grid saved: ", output_file)
message("Ocean cells read: ", nrow(grid_ocean))
message("Cells assigned to MEOW: ", nrow(grid_meow))
message("Unique cell IDs: ", length(unique(grid_meow$cell_id)))

# NOTE: Historical workflow mentions manual QGIS edits to a MEOW grid.
# This script does not reproduce those undocumented manual edits.
