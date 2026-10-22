### ======================================================================= ###
###                  BIO-ORACLE ENVIRONMENTAL VARIABLES
### ======================================================================= ###

"
The following oceanographic variables correspond to the mean depth of the benthic layer and are available in Bio-ORACLE. 
They have been downloaded for the current conditions. The selected periods are 2000–2010 and 2010–2020.

- Ocean temperature (thetao)
- Salinity (so)
- Sea water velocity (sws)
- Sea water direction (swd)
- Nitrate (no3)
- Phosphate (po4)
- Silicate (si)
- Dissolved molecular oxygen (02)
- Iron (dfe)
- Primary productivity (phyc)
- pH (ph)
- Bathymetry (bathymetry)
"

# Packages ----------------------------------------------------------------
library(here)
library(terra)

# 1. Define directories ---------------------------------------------------

# Original NetCDF files
directory_2000 <- here("data", "raw", "bio_oracle", "2000_2010")
directory_2010 <- here("data", "raw", "bio_oracle", "2010_2020")

# Output directory for intermediate data
output_dir <- here("data", "interim", "bio_oracle")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)


# 2. Load original raster files -------------------------------------------

files_2000 <- list.files(
  directory_2000,
  pattern = "\\.nc$",
  full.names = TRUE
)

files_2010 <- list.files(
  directory_2010,
  pattern = "\\.nc$",
  full.names = TRUE
)

# Check files
if (length(files_2000) == 0 || length(files_2010) == 0) {
  stop("No NetCDF files found. Check the input directories.")
}

# Create raster stacks
raster_stack_2000 <- rast(files_2000)
raster_stack_2010 <- rast(files_2010)


# 3. Process environmental variables --------------------------------------

# Sort raster layers by name
raster_stack_2000 <- raster_stack_2000[[
  order(names(raster_stack_2000))
]]

raster_stack_2010 <- raster_stack_2010[[
  order(names(raster_stack_2010))
]]

# Verify corresponding layers
stopifnot(
  identical(names(raster_stack_2000), names(raster_stack_2010))
)

# Verify spatial geometry
stopifnot(
  compareGeom(raster_stack_2000, raster_stack_2010)
)

# Calculate mean between both periods
raster_stack_mean <- (
  raster_stack_2000 + raster_stack_2010
) / 2

# Inspect result
print(raster_stack_mean)
names(raster_stack_mean)
crs(raster_stack_mean)


# 4. Save intermediate raster stack ---------------------------------------

output_file <- here(
  "data", "interim", "bio_oracle",
  "raster_stack_biooracle_2000_2020.tif"
)

writeRaster(
  raster_stack_mean,
  filename = output_file,
  overwrite = TRUE
)

message("Raster stack saved to: ", output_file)


# 5. Visualize environmental variables ------------------------------------

plot(
  raster_stack_mean,
  main = names(raster_stack_mean),
  nc = 3
)


### ======================================================================= ###
###                  SEAFLOOR SEDIMENTS IN THE WORLD'S OCEAN
### ======================================================================= ###

# Reference:
# Dutkiewicz et al. (2015). Census of seafloor sediments in the
# world's ocean. Geology, 43(9), 795-798.
# https://doi.org/10.1130/G36883.1

# Packages ----------------------------------------------------------------
library(here)
library(terra)

# 1. Define directories ---------------------------------------------------

input_file <- here(
  "data", "raw", "seafloor_sediments",
  "seabed_lithology_v1.nc"
)

output_dir <- here("data", "interim", "seafloor_sediments")
figures_dir <- here("results", "figures")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)


# 2. Load original sediment raster ----------------------------------------

r_sediments <- rast(input_file)

print(r_sediments)
names(r_sediments)


# 3. Identify sediment classes --------------------------------------------

# Extract unique raster values
unique_values <- sort(
  unique(na.omit(values(r_sediments)))
)

print(unique_values)

# Original sediment categories (Dutkiewicz et al., 2015)
lithology_classes <- c(
  "Gravel and coarser",
  "Sand",
  "Silt",
  "Clay",
  "Calcareous ooze",
  "Radiolarian ooze",
  "Diatom ooze",
  "Sponge spicules",
  "Mixed calcareous/siliceous ooze",
  "Shells and coral fragments",
  "Ash and volcanic sand/gravel",
  "Siliceous mud",
  "Fine-grained calcareous sediment"
)

# Verify the number of categories
if (length(unique_values) != length(lithology_classes)) {
  stop("The number of raster values does not match the sediment classes.")
}

# Assign category labels while preserving original raster values
levels(r_sediments) <- data.frame(
  value = unique_values,
  sediment_class = lithology_classes
)


# 4. Save intermediate sediment raster ------------------------------------

output_file <- here(
  "data", "interim", "seafloor_sediments",
  "seafloor_lithology.tif"
)

writeRaster(
  r_sediments,
  filename = output_file,
  overwrite = TRUE
)

message("Sediment raster saved to: ", output_file)


# 5. Visualize sediment classes -------------------------------------------

sediment_colors <- c(
  "#6b6a6a", "yellow", "#dbac15", "#744724f5",
  "#80cbe3", "#046804", "#a2de83", "#3f7578",
  "#7b2a80", "#E89ECE", "#d30909", "#dba15a",
  "#0931c3"
)

# Export map as SVG
svg(
  here("results", "figures", "seafloor_lithology.svg"),
  width = 10,
  height = 8
)

plot(
  r_sediments,
  col = sediment_colors,
  main = "Seafloor Lithology"
)

dev.off()
