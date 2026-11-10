"""Generate the global 0.1-degree grid and its ocean-only subset.

The environmental raster supplies the geographic extent (not pixel values).
Ocean cells are those that do not intersect the land shapefile.
Run this script from anywhere; the project root is found using .here.
"""

from pathlib import Path

import geopandas as gpd
import numpy as np
import rasterio
from shapely.geometry import box
from shapely.validation import make_valid
from tqdm import tqdm

# ============================================================
# PYTHON AND PACKAGE VERSIONS
# ============================================================
# Versions from the current runtime, not the historical analysis environment.

import sys
from importlib.metadata import PackageNotFoundError, version

print(f"Python version: {sys.version}")
print("Package versions:")
for _version_package in ['geopandas', 'numpy', 'rasterio', 'shapely', 'tqdm']:
    try:
        print(f"{_version_package}: {version(_version_package)}")
    except PackageNotFoundError:
        print(f"{_version_package}: version not available")
del _version_package


# 1. Project paths ----------------------------------------------------------
def find_project_root(script_path: Path) -> Path:
    """Find the repository root marked by the .here file."""
    for folder in (script_path.parent, *script_path.parents):
        if (folder / ".here").is_file():
            return folder
    raise FileNotFoundError(
        "Project root not found. Create a .here file in the repository root."
    )


PROJECT_ROOT = find_project_root(Path(__file__).resolve())
LAND_FILE = PROJECT_ROOT / "data" / "raw" / "geography" / "basemap2.shp"
RASTER_FILE = (
    PROJECT_ROOT / "data" / "interim" / "environmental"
    / "r_stack_standardized.tif"
)
OUTPUT_DIR = PROJECT_ROOT / "data" / "interim" / "grids"
GLOBAL_GRID_FILE = OUTPUT_DIR / "grid_global_0.1deg.gpkg"
OCEAN_GRID_FILE = OUTPUT_DIR / "grid_ocean_0.1deg.gpkg"

GRID_RESOLUTION = 0.1  # degrees in EPSG:4326


def main() -> None:
    # 2. Validate input files ----------------------------------------------
    for path in (LAND_FILE, RASTER_FILE):
        if not path.is_file():
            raise FileNotFoundError(f"Input file not found: {path}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # 3. Load land and read raster extent ---------------------------------
    land = gpd.read_file(LAND_FILE).to_crs("EPSG:4326")
    land["geometry"] = land.geometry.apply(make_valid)

    with rasterio.open(RASTER_FILE) as src:
        if src.crs is None or src.crs.to_epsg() != 4326:
            raise ValueError("Environmental raster must use EPSG:4326.")
        bounds = src.bounds

    # 4. Build grid (preserving the original cell-ID order) ----------------
    x_coords = np.arange(bounds.left, bounds.right, GRID_RESOLUTION)
    y_coords = np.arange(bounds.bottom, bounds.top, GRID_RESOLUTION)

    grid_cells = [
        box(x, y, x + GRID_RESOLUTION, y + GRID_RESOLUTION)
        for x in tqdm(x_coords, desc="Generating grid columns")
        for y in y_coords
    ]
    grid = gpd.GeoDataFrame(
        {"cell_id": np.arange(1, len(grid_cells) + 1)},
        geometry=grid_cells,
        crs="EPSG:4326",
    )
    grid.to_file(GLOBAL_GRID_FILE, driver="GPKG", index=False)
    print(f"Global grid saved: {GLOBAL_GRID_FILE} ({len(grid):,} cells)")

    # 5. Exclude all grid cells intersecting land --------------------------
    land_union = land.geometry.union_all()
    ocean_grid = grid.loc[~grid.geometry.intersects(land_union)].copy()
    ocean_grid.to_file(OCEAN_GRID_FILE, driver="GPKG", index=False)
    print(f"Ocean grid saved: {OCEAN_GRID_FILE} ({len(ocean_grid):,} cells)")


if __name__ == "__main__":
    main()
