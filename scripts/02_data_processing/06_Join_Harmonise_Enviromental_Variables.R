library(dplyr)
library(tidyverse)
library(terra)
library(stringr)
library(reshape2)
library(raster)

###===================================================================================================================================###
### DEFINE THE WORKING DIRECTORY
###===================================================================================================================================###

local = "__CONFIGURE_PATH_01__"
setwd(local)
save_path=paste0(local,"/05_ENVIROMENTAL_VARIABLES/03_Variables_Processed")


###===================================================================================================================================###
### LOAD ENVIROMENTAL VARIABLES
###===================================================================================================================================###

Bio_ORACLE_raster <- rast(paste0(local, "/05_ENVIROMENTAL_VARIABLES/01_DATA/BIO_ORACLE/raster_stack_biooracle_2000_2020.tif"))
sediments_raster <- rast(paste0(local, "/05_ENVIROMENTAL_VARIABLES/01_DATA/Seafloor_sediments/seafloor_lithology_dummy.tif"))
CMEMS_chl_raster <- rast(paste0(local, "/05_ENVIROMENTAL_VARIABLES/02_Python_Copernicus_Marine_Toolbox_API/00_Downloaded/30m_depth/chl_mean/chl_mean_2000_2020_v0.tif"))


# See resolution (pixel size)
res(Bio_ORACLE_raster) # 0.05 0.05
res(sediments_raster) # 0.1 0.1
res(CMEMS_chl_raster) # 0.25 0.25

# See extension (spatial limits)
ext(Bio_ORACLE_raster) # SpatExtent : -180.000006104363, 180.000006104363, -89.9999984736971, 89.9999984736971 (xmin, xmax, ymin, ymax)
ext(sediments_raster) # SpatExtent : -180.05, 180.05, -90.05, 90.05 (xmin, xmax, ymin, ymax)
ext(CMEMS_chl_raster) # SpatExtent : -180.125, 179.875, -80.125, 90.125 (xmin, xmax, ymin, ymax)

# See projection (CRS)
crs(Bio_ORACLE_raster, describe=TRUE)
crs(sediments_raster, describe=TRUE)
crs(CMEMS_chl_raster, describe=TRUE)

summary(CMEMS_chl_raster)
###===================================================================================================================================###
### STEPS TO HARMONISE THE LAYERS
###===================================================================================================================================###

# 1. Use Bio-ORACLE as a reference --------------------------------------------------------
res_ref <- res(Bio_ORACLE_raster)
ext_ref <- ext(Bio_ORACLE_raster)

# 2. Adjust the extent of the other layers --------------------------------------------------------
sediments_raster <- crop(sediments_raster, ext_ref)
CMEMS_chl_raster <- crop(CMEMS_chl_raster, ext_ref)

# 3. Resample the layers with lower resolution to match Bio-ORACLE. --------------------------------------------------------
sediments_raster <- resample(sediments_raster, Bio_ORACLE_raster, method = "near")  # ‘Near’ method for categorical data
CMEMS_chl_raster <- resample(CMEMS_chl_raster, Bio_ORACLE_raster, method = "bilinear")  # ‘Bilinear’ method for continuous data


res(Bio_ORACLE_raster) # 0.05 0.05
res(sediments_raster) # 0.05 0.05
res(CMEMS_chl_raster) # 0.05 0.05

ext(Bio_ORACLE_raster) # SpatExtent : -180.000006104363, 180.000006104363, -89.9999984736971, 89.9999984736971 (xmin, xmax, ymin, ymax)
ext(sediments_raster) # SpatExtent : -180.000006104363, 180.000006104363, -89.9999984736971, 89.9999984736971 (xmin, xmax, ymin, ymax)
ext(CMEMS_chl_raster) # SpatExtent : -180.000006104363, 180.000006104363, -89.9999984736971, 89.9999984736971 (xmin, xmax, ymin, ymax)

# 4. Create the final SpatRaster --------------------------------------------------------
stack_final <- c(Bio_ORACLE_raster, CMEMS_chl_raster, sediments_raster)

# 5. Check that the layers are compatible --------------------------------------------------------
print(stack_final)
names(stack_final)
stack_final

summary(stack_final)


###===================================================================================================================================###
### FILTER VARIABLES
###===================================================================================================================================###

# Select the Bio-ORACLE layers of average values
vars_mean <- c("bathymetry_mean", "o2_mean","ph_mean",
                "phyc_mean", "po4_mean", "so_mean", 
                "sws_mean", "thetao_mean", "chl_mean_2000_2020_v0", "z")

# Create the new raster stack
stack_mean <- subset(stack_final, vars_mean)

# Verificar el resultado
print(stack_mean)
names(stack_mean)
summary(stack_mean)

# Export
writeRaster(stack_mean,
            filename = paste0(save_path, "/r_stack_mean.tif"),
            overwrite = TRUE)

writeRaster(stack_final,
            filename = paste0(save_path, "/r_stack_all.tif"),
            overwrite = TRUE)



###===================================================================================================================================###
### STANDARDISE VARIABLES USING Z-SCORES
###===================================================================================================================================###

# Conversion from terra SpatRaster to raster RasterLayer
stack_mean_2 <- lapply(1:nlyr(stack_mean), function(i) {
  raster(stack_mean[[i]])
})

names(stack_mean_2) <- c("bathymetry_mean", "o2_mean","ph_mean","phyc_mean", "po4_mean", "so_mean", 
                "sws_mean", "thetao_mean", "chl_mean_2000_2020_v0", "z")

stack_mean_2 <- stack(stack_mean_2)
stack_mean_2

continuous_layers <- subset(stack_mean_2, c("bathymetry_mean", "o2_mean","ph_mean","phyc_mean", "po4_mean", "so_mean", 
                "sws_mean", "thetao_mean", "chl_mean_2000_2020_v0"))


# z-transform climate layers to make axes comparable
for (i in 1:nlayers(continuous_layers))
{
  continuous_layers[[i]] <- 
  (continuous_layers[[i]] - cellStats(continuous_layers[[i]], 'mean')) /
  cellStats(continuous_layers[[i]], 'sd') 
}


# Create a new stack with the standardised layers and the (unstandardised) sediment layers.
sediments_layer <- subset(stack_mean_2, "z")
res(sediments_layer)

stack_standardized <- c(continuous_layers, sediments_layer)
class(stack_standardized)

stack_standardized <- stack(stack_standardized)
class(stack_standardized)

names(stack_standardized)
# Export
writeRaster(stack_standardized,
            filename = paste0(save_path, "/r_stack_standardized.tif"),
            overwrite = TRUE)


# save names
layer_names <- names(stack_standardized)
saveRDS(names(stack_standardized), paste0(save_path, "/layer_names_r_stack_standardized.rds"))



###===================================================================================================================================###
### RENAME AND RECLASSIFY VARIABLESS
###===================================================================================================================================###

# load raster base
r_stack <- rast(paste0(save_path,"/r_stack_standardized.tif"))
names(r_stack) <- readRDS(paste0(save_path, "/layer_names_r_stack_standardized.rds"))

names(r_stack)

# ----------------------------------------
# 1. Reclasificar la variable z
# ----------------------------------------

# Extraer la capa de sedimentos
z_raster <- r_stack[["z"]]

# Tabla: valor original → orden del tamaño del sedimento
reclass_table_size_z <- matrix(c(
  1, 5,
  2, 3,
  3, 1,
  4, 2,
  5, 1,
  6, 1,
  7, 1,
  8, 3,
  9, 1,
  10, 4,
  11, 5,
  12, 1,
  13, 2
), ncol = 2, byrow = TRUE)

z_size <- classify(z_raster, rcl = reclass_table_size_z)

names(z_size)
names(z_size) <- c("sediment_size")

# ----------------------------------------
# 2. Crear una nueva variable que identifique el origen de la variable z (Sedimentos)
# ----------------------------------------

# Paso 1: Reclasificación numérica (1 = Inorgánico, 2 = Orgánico)
reclass_table_origin_code <- matrix(c(
  1, 1,
  2, 1,
  3, 1,
  4, 1,
  5, 1,
  6, 2,
  7, 2,
  8, 2,
  9, 1,
  10, 2,
  11, 1,
  12, 1,
  13, 1
), ncol = 2, byrow = TRUE)

z_origin_code <- classify(z_raster, rcl = reclass_table_origin_code)

names(z_origin_code)
names(z_origin_code) <- c("z_origin")

# Asignar nombres a las categorías
levels(z_origin_code) <- data.frame(
  value = c(1, 2),
  origin = c("Inorgánico", "Orgánico")
)
plot(z_origin_code)



# ----------------------------------------
# 3. Unir las nuevas variables de sedimentos al raster
# ----------------------------------------

names(r_stack)
r_stack <- c(r_stack, z_size, z_origin_code)

names(r_stack)[names(r_stack) == "z"] <- "sediments"
names(r_stack)[names(r_stack) == "bathymetry_mean"] <- "bathymetry"
names(r_stack)[names(r_stack) == "o2_mean"] <- "o2"
names(r_stack)[names(r_stack) == "ph_mean"] <- "ph"
names(r_stack)[names(r_stack) == "phyc_mean"] <- "phyc"
names(r_stack)[names(r_stack) == "po4_mean"] <- "po4"
names(r_stack)[names(r_stack) == "so_mean"] <- "so"
names(r_stack)[names(r_stack) == "sws_mean"] <- "sws"
names(r_stack)[names(r_stack) == "thetao_mean"] <- "thetao"
names(r_stack)[names(r_stack) == "chl_mean_2000_2020_v0"] <- "chl"

names(r_stack)

# Export
writeRaster(r_stack,
            filename = paste0(save_path, "/raster_standardized_vars_correct_new_vars.tif"),
            overwrite = TRUE)

# save names
saveRDS(names(r_stack), paste0(save_path, "/layer_names_raster_standardized_vars_correct_new_vars.rds"))
