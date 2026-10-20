
library(dplyr)         # Manipulación de datos
library(fastDummies)   # Para crear variables dummy
library(ggplot2)       # Gráficos
library(hypervolume)   # Hipervolúmenes de nicho
library(purrr)         # Programación funcional
library(sf)            # Datos espaciales
library(tidyr)         # Reorganización de datos
library(tidyverse)     # Conjunto de paquetes tidy

###===================================================================================================================================###
### DEFINE THE WORKING DIRECTORY
###===================================================================================================================================###

local = "__CONFIGURE_PATH_01__"
data_dir = paste0(local,"/01_DATA/01_GRIDS/01_GRID_PROCESSED/01_GRIDS_FINAL")
save_path=paste0(local,"/03_Hypervolumes")
setwd(local)

###===================================================================================================================================###
### LOAD DATA ENV
###===================================================================================================================================###

grid_realms_env <- st_read(paste0(data_dir,"/grid_env_realm_with_PCA6_axes.gpkg"))
#  convertir a df
data_env <- grid_realms_env %>% 
  sf::st_drop_geometry()

###===================================================================================================================================###
### LOAD DATA SPECIES
###===================================================================================================================================###

grid_realms_species <- st_read(paste0(data_dir,"/grid_species_qgis_coords.gpkg"))

data_species <- grid_realms_species %>% 
  sf::st_drop_geometry()

length(unique(data_species$species)) # 162 sp

# Filtrar especies con menos de 10 cuadriculas de presencia

species_counts <- data_species %>%
  group_by(species) %>%
  summarise(n_cells = n_distinct(cell_id)) %>%
  arrange(n_cells)
species_counts

species_valid <- data_species %>%
  group_by(species) %>%
  summarise(n_cells = n_distinct(cell_id)) %>%
  filter(n_cells >= 10) %>%
  pull(species)

data_species <- data_species %>%
  filter(species %in% species_valid)

length(unique(na.omit(data_species$species))) # 146 sp
colSums(is.na(data_species))


###===================================================================================================================================###
### JOIN DATA
###===================================================================================================================================###

colnames(data_env)
colnames(data_species)

data_env <- data_env %>% select(-REALM, -RLM_CODE)
data_species_with_all_vars <- left_join(data_species, data_env, by = "cell_id")
head(data_species_with_all_vars)

length(unique(data_species_with_all_vars$species)) # 146 sp porque hay celdas sin especies

colnames(data_species_with_all_vars)

data_species_with_all_vars <- data_species_with_all_vars %>%
  filter(!is.na(species))
length(unique(data_species_with_all_vars$species)) # 144 sp

###===================================================================================================================================###
### HYPERVOLUME
###===================================================================================================================================###

data_species_with_all_vars <- distinct(data_species_with_all_vars, cell_id, species, .keep_all = TRUE)

species_list <- sort(unique(data_species_with_all_vars$species)) #144SP
species_list

# species_list_test <- species_list[1:1]
# data_test <- data_species_with_all_vars %>%
#   filter(species %in% c(species_list_test))
# data_hv <- data_test
# colnames(data_hv)

data_hv <- data_species_with_all_vars

var_axes <- c("PC1", "PC2","PC3","PC4", "PC5", "PC6")
num_var <- length(var_axes)
message(paste("Number of environmental axes:", num_var))

cat_list_Species <- sort(unique(data_hv$species))
num_cat_Species <- length(cat_list_Species)
message(paste("Number of species:", num_cat_Species))
message(paste("Species names:", cat_list_Species))

# Crear lista vacía de clase HypervolumeList
hv_list_Species <- new("HypervolumeList")
hv_list_Species@HVList <- vector(mode = "list", length = num_cat_Species)


# lista o dataframe para pdf normalizada
pdf_list <- vector("list", length = num_cat_Species)


for (i in seq_len(num_cat_Species)) {
  
  sp_name <- cat_list_Species[i]
  message(paste0("Calculando hipervolumen (gaussian) para: ", sp_name, " (", i, "/", num_cat_Species, ")"))
  
  # Subconjunto de datos
  data_Species <- data_hv[data_hv$species == sp_name, var_axes]
  
  # Hipervolumen GAUSSIANO
  hv <- hypervolume_gaussian(
    data = data_Species,
    name = sp_name,
    kde.bandwidth = estimate_bandwidth(data_Species, method = "silverman"),
    verbose = TRUE
  )
  
  # === Guardar hipervolumen original ===
  saveRDS(hv, file = file.path(save_path, paste0("hypervolume_", sp_name, ".rds")))
  hv_list_Species@HVList[[i]] <- hv
  
  # === Calcular pdf normalizada ===
  dens <- hv@ValueAtRandomPoints
  probs <- dens / sum(dens, na.rm = TRUE)
  
  pdf_list[[i]] <- data.frame(
    species = sp_name,
    hv_index = i,
    hv@RandomPoints,   # coordenadas ambientales de los puntos
    prob = probs        # probabilidad relativa (pdf)
  )
}


# Guardar la lista geométrica (igual que antes)
save(hv_list_Species, file = file.path(save_path, "hv_list_all_species.RData"))
message("✅ Hipervolúmenes gaussianos guardados correctamente.")

# Guardar las pdf normalizadas para análisis probabilísticos
pdf_df <- do.call(rbind, pdf_list)
saveRDS(pdf_df, file = file.path(save_path, "hv_probabilities_all_species.rds"))
write.csv(pdf_df, file = file.path(save_path, "hv_probabilities_all_species.csv"), row.names = FALSE)
message("✅ Probabilidades normalizadas guardadas correctamente.")


# hv <- hv_list_Species@HVList[[1]]
# range(hv@ValueAtRandomPoints)
# 
# # Normalizar
# hv@ValueAtRandomPoints <- hv@ValueAtRandomPoints / sum(hv@ValueAtRandomPoints)
# sum(hv@ValueAtRandomPoints)  # ≈ 1
# 
# hist(hv@ValueAtRandomPoints, breaks = 100, main = "Densidad estimada", xlab = "ValueAtRandomPoints")


