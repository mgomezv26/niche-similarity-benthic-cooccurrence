import geopandas as gpd
import rasterio
from shapely.geometry import box
import numpy as np
import pandas as pd
from tqdm import tqdm
from rasterio.mask import mask
import os

##===================================================================================================================================###
### DEFINE THE WORKING DIRECTORY
###===================================================================================================================================###

# Ruta base (similar a "local" en R)
local = "__CONFIGURE_PATH_01__"
os.chdir(local)
save_path = os.path.join(local, "08_GRID_BASE")

##===================================================================================================================================###
### CREATE A GRID
###===================================================================================================================================###

# 1. Import shapefile 
file_path = os.path.join(save_path, "02_Shp_land", "basemap2.shp")
grid_land = gpd.read_file(file_path).to_crs("EPSG:4326")

# 2. Import raster
raster_path = os.path.join(local, "05_ENVIROMENTAL_VARIABLES", "03_Variables_Processed", "r_stack_standardized.tif")
with rasterio.open(raster_path) as src:
    bounds = src.bounds  # (left, bottom, right, top)
    raster_crs = src.crs

# Convert to EPSG:4326 if necessary
if raster_crs.to_epsg() != 4326:
    raise ValueError("Raster must be in EPSG:4326")

# 3. Create grid of 0.1° × 0.1°
x_coords = np.arange(bounds.left, bounds.right, 0.1)
y_coords = np.arange(bounds.bottom, bounds.top, 0.1)

grid_cells = []
for x in tqdm(x_coords, desc="Generating cells by columns"):
    for y in y_coords:
        cell = box(x, y, x + 0.1, y + 0.1)
        grid_cells.append(cell)

grid_sf = gpd.GeoDataFrame({'geometry': grid_cells})
grid_sf.set_crs("EPSG:4326", inplace=True)

# 4. Assign cell ID
grid_sf["cell_id"] = np.arange(1, len(grid_sf) + 1)

# 5. Save the complete grid
grid_result_path = os.path.join(save_path, "01_GRIDS", "grid_sf_0.1deg.gpkg")
grid_sf.to_file(grid_result_path, driver="GPKG")

# 6. Validate geometries
from shapely.validation import make_valid
grid_land["geometry"] = grid_land["geometry"].apply(make_valid)

# 7. Select oceanic cells only
grid_ocean = grid_sf[~grid_sf.geometry.intersects(grid_land.unary_union)]

# 8. Export
grid_ocean_path = os.path.join(save_path, "01_GRIDS", "grid_ocean_0.1deg_python.gpkg")
grid_ocean.to_file(grid_ocean_path, driver="GPKG")


##===================================================================================================================================###
### FILTER ONLY NORTHERN HEMISPHERE
###===================================================================================================================================###

# 1. Load the grid of ocean cells
grid_ocean_path = os.path.join(save_path, "01_GRIDS", "grid_ocean_0.1deg_python.gpkg")
grid_ocean = gpd.read_file(grid_ocean_path)

# 2. Calculate the centroids
centroids = grid_ocean.geometry.centroid

# 3. Extract latitudes (Y-coordinate)
latitudes = centroids.y

# 4. Filter cells with centroid at latitude > 0 (Northern hemisphere)
grid_north = grid_ocean[latitudes > 0]

# 5. Export
grid_north.to_file("01_GRIDS/grid_north_sf_0.1deg.gpkg", driver="GPKG")
