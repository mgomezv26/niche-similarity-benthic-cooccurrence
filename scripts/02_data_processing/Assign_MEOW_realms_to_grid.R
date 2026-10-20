
library(dplyr)         # Manipulación de datos
library(sf)            # Datos espaciales
library(tidyr)         # Reorganización de datos
library(tidyverse)     # Conjunto de paquetes tidy

###===================================================================================================================================###
### DEFINE THE WORKING DIRECTORY
###===================================================================================================================================###

local = "__CONFIGURE_PATH_01__"
setwd(local)
save_path=paste0(local,"/01_DATA/01_GRIDS/01_GRID_PROCESSED")

# ------------------------------------------
# 1. Cargar grid base sin datos ambientales
# ------------------------------------------

grid_ocean <- st_read(paste0(local,"/01_DATA/01_GRIDS/grid_ocean_0.1deg_python.gpkg"))

# Si hay más de una geometría por cell_id, conservar solo la primera
grid_clean <- grid_ocean %>%
  group_by(cell_id) %>%
  slice(1) %>%
  ungroup()

head(grid_clean)

# NO HAY DUPLICADOS
#st_write(grid_with_env, paste0(save_path,"/grid_north_0_1_env_sediments_clean_new_vars.gpkg"), delete_dsn = TRUE)


# Crear grid reducido: solo cell_id + geometría
grid_geom <- grid_clean %>%
  select(cell_id, geom)

# Exportar grid base geométrico (para asignar REALMs)
#st_write(grid_geom, paste0(save_path,"/grid_north_0_1_geom_base_r.gpkg"), delete_dsn = TRUE) #RUTA MUY LARGA PARA GUARDARLO
#st_write(grid_geom, "grid_geom_base.gpkg", delete_dsn = TRUE)

plot(grid_geom$cell_id)
# ------------------------------------------
# 2. Añadir realms de MEOW
# ------------------------------------------

meow <- st_read(paste0(local,"/01_DATA/11_MEOW_LAYERS/MEOW/meow_ecos.shp"))
st_crs(meow)
st_crs(grid_geom)

# Comprobar geometrías inválidas
sum(!st_is_valid(meow))
sum(!st_is_valid(grid_geom))

# Corregir geometrías inválidas
grid_geom <- st_make_valid(grid_geom)

# Desactivar el uso de s2 para evitar problemas con geometrías complejas
sf_use_s2(FALSE)

# Realizar el spatial join para asignar REALM a cada celda del grid
grid_realms <- st_join(grid_geom, meow[, c("REALM", "RLM_CODE")], left = TRUE)

grid_realms_only <- grid_realms %>%
  filter(!is.na(REALM))

grid_realms_only_clean <- grid_realms_only %>%
  group_by(cell_id) %>%
  slice(1) %>%
  ungroup()

length(grid_realms_only_clean$cell_id)
length(unique(grid_realms_only_clean$cell_id))

st_write(grid_realms_only_clean, paste0(save_path,"/grid_geom_base_only_with_realms.gpkg"), delete_dsn = TRUE)

# grid_ocean_0.1deg_realms.gpkg -> editado en QGIS para eliminar celdas con geometria rara que salia, geometria rectangulares

###===================================================================================================================================###
### VARIABES OCEANOGRAFICAS
###===================================================================================================================================###

# Load grid base
grid_realms <- st_read(paste0(save_path,"/grid_geom_base_only_with_realms.gpkg"))

# ----------------------------------------
# 1. Load raster
# ----------------------------------------

library(terra)
library(sf)

r_stack <- rast(paste0(local, "/01_DATA/05_ENVIROMENTAL_VARIABLES/raster_standardized_vars_correct_new_vars.tif"))
names(r_stack) <- readRDS(paste0(local, "/01_DATA/05_ENVIROMENTAL_VARIABLES/layer_names_raster_standardized_vars_correct_new_vars.rds"))
names(r_stack)

vars_select<- names(r_stack)[names(r_stack) != "sediments"]
r_stack <- r_stack[[vars_select]]

# ----------------------------------------
# 2. Extract variables from the stack to each grid cell.
# ----------------------------------------

# Convert the grid to terra object for extraction
grid_vect <- vect(grid_realms)

# Extract mean values of each variable per cell (polygon)
env_vals <- terra::extract(r_stack, grid_vect, fun = mean, na.rm = TRUE)

# Join the extracted values to the grid
grid_with_env <- cbind(grid_realms, env_vals[, -1])  # quitamos ID duplicado
st_write(grid_with_env, paste0(save_path,"/grid_realms_0_1_env_r.gpkg"), delete_dsn = TRUE)


# it gives error when saving in dropbox, I save it in local
#save_path_local <- "__CONFIGURE_PATH_02__"
#st_write(grid_with_env, paste0(save_path_local, "/grid_north_0_1_env_r.gpkg"), delete_dsn = TRUE)


# ----------------------------------------
# 3. Sediments
# ----------------------------------------

# 3.1. Sediments size ---------------

#grid_with_env <- st_read(paste0(local,"/08_GRID_BASE/01_GRIDS/grid_north_0_1_env_r.gpkg"))

r_sediment_size <- r_stack[["sediment_size"]]

# 1. Convert the grid to SpatVector
grid_vect <- vect(grid_with_env)

# 2. Extract sediment values per cell.
sed_vals <- extract(r_sediment_size, grid_vect, fun = "modal", na.rm = TRUE)

# 3. Join to grid (by ID)
grid_vect$r_sediment_size <- sed_vals[,2]  # segunda columna contiene los valores extraídos

# 4. Verify
table(grid_vect$r_sediment_size, useNA = "ifany")

# 3.2. Sediments origin ---------------

r_sediment_origin <- r_stack[["z_origin"]]

# Extract sediment values per cell.
sed_vals <- extract(r_sediment_origin, grid_vect, fun = "modal", na.rm = TRUE)

# Join to grid (by ID)
grid_vect$r_sediment_origin <- sed_vals[,2]  # segunda columna contiene los valores extraídos

# Verify
table(grid_vect$r_sediment_origin, useNA = "ifany")
table(grid_vect$r_sediment_size, useNA = "ifany")

names(grid_vect)

# Delete rows with NaN in the column sediment_size
library(dplyr)


# Convert from SpatVector to sf
grid_sf <- sf::st_as_sf(grid_vect)
names(grid_sf)

# Verifica
table(grid_sf$r_sediment_size, useNA = "ifany")
summary(grid_sf$o2)

# Filter out only the rows where r_sediment_size is not NaN
grid_vect_clean <- grid_sf %>% filter(!is.na(r_sediment_size))
table(grid_vect_clean$r_sediment_size, useNA = "ifany")

table(grid_vect_clean$bathymetry, useNA = "ifany")

grid_vect_clean <- grid_vect_clean %>% filter(!is.na(bathymetry))
grid_vect_clean <- grid_vect_clean %>% filter(!is.na(chl))

summary(grid_vect_clean)

grid_vect_clean <- grid_vect_clean %>% select(-c(sediment_size, z_origin))

# Export grid with variables
st_write(grid_vect_clean,paste0(save_path,"/01_GRIDS_FINAL/grid_realms_0_1_env_clean.gpkg"), delete_dsn = TRUE)


###===================================================================================================================================###
### SPECIES DATA
###===================================================================================================================================###

# ----------------------------------------
# 1. species data
# ----------------------------------------

records <- read.csv(paste0(local,'/01_DATA/02_SPECIES_DATA/Data_Occurrence_period_2000_2020.csv'))

colnames(records)
head(records)
nrow(records) # 320906 records
length(unique(records$species)) # 173 sp


# Delete data with less than 10 records
records_filtered <- records %>%
  group_by(species) %>%
  filter(n() >= 10) %>%
  ungroup()

records_filtered <- as.data.frame(records_filtered)

length(unique(records_filtered$species)) # 162 sp
nrow(records_filtered) # 320857 records

species_data 	<- records_filtered %>%
  select("ID", "latitude", "longitude", "species")

write.csv(species_data, paste0(local,'/01_DATA/02_SPECIES_DATA/species_data.csv'))


species_data <- read.csv(paste0(local,"/01_DATA/02_SPECIES_DATA/species_data.csv"))

# ----------------------------------------
# 2. grid data
# ----------------------------------------

st_write(grid_vect_clean,paste0(save_path,"/01_GRIDS_FINAL/grid_realms_0_1_env_clean.gpkg"), delete_dsn = TRUE)




grid_sf <- st_read(paste0(save_path,"/01_GRIDS_FINAL/grid_realms_0_1_env_clean.gpkg"))
colnames(grid_sf)

grid_relams <- grid_sf %>%
  select(cell_id, REALM, RLM_CODE, geom)

st_write(grid_relams,paste0(save_path,"/01_GRIDS_FINAL/grid_realms_0_1_base.gpkg"), delete_dsn = TRUE)

### Assign species presence to the grid

# The union of the presences with the grid has been done with QGIS using the tool “Join attributes by location”.
grid_species_qgis <- st_read(paste0(save_path,"/grid_realms_0_1_species_qgis.gpkg"))
nrow(grid_species_qgis)
nrow(grid_sf)
summary(grid_species_qgis)

# Calculate the centroids of each grid cell
grid_species_qgis$centroid <- st_centroid(grid_species_qgis$geom)

# Verification: See the first calculated centroids.
head(grid_species_qgis$centroid)
head(grid_species_qgis)

# Extract the coordinates of the centroids (longitude and latitude).
centroid_coords <- st_coordinates(grid_species_qgis$centroid)

# Add coordinates as new columns
grid_species_qgis$longitude <- centroid_coords[, 1]
grid_species_qgis$latitude <- centroid_coords[, 2]

# Verification: See the first values of the new columns.
head(grid_species_qgis[c("longitude", "latitude")])
# Remove the ‘centroid’ column
grid_species_qgis <- grid_species_qgis %>% select(-centroid)
str(grid_species_qgis)
# Delete the ‘fid’ column
grid_species_qgis$fid <- NULL
# Save the file
st_write(grid_species_qgis, paste0(save_path,"/01_GRIDS_FINAL/grid_species_qgis_coords.gpkg"), delete_dsn = TRUE)
