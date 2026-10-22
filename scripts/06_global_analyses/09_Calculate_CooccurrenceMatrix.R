library(sf)
library(tidyr)
library(dplyr)

###===================================================================================================================================###
### DEFINE THE WORKING DIRECTORY
###===================================================================================================================================###
local = "__CONFIGURE_PATH_01__"
data_dir = paste0(local,"/01_DATA/01_GRIDS/01_GRID_PROCESSED/01_GRIDS_FINAL")
save_path=paste0(local,"/04_Coocurrence")
setwd(local)


###===================================================================================================================================###
### CO-OCCURRENCE MATRIX
###===================================================================================================================================###

# Load grid with presence data
#grid_species_qgis <- st_read(paste0(save_path,"01_GRIDS/01_GRID_PROCESSED/grid_species_qgis_coords_v2.gpkg"))
grid_realms_species <- st_read(paste0(data_dir,"/grid_species_qgis_coords.gpkg"))

  # Calculate number of cells per species (without losing geometry)
species_counts <- grid_realms_species %>%
  st_drop_geometry() %>%
  group_by(species) %>%
  summarise(n_cells = n_distinct(cell_id)) %>%
  arrange(n_cells)

# Select species with at least 10 occurrences
species_valid <- species_counts %>%
  filter(n_cells >= 10) %>%
  pull(species)

# Filter the original grid while maintaining geometry
grid_species_filtered <- grid_realms_species %>%
  filter(species %in% species_valid)

# Comprobar resultados
length(unique(grid_species_filtered$species))  # 147 sp
length(unique(na.omit(grid_species_filtered$species))) # 146 sp

###===================================================================================================================================###
### Absolute co-occurrence matrix 
###===================================================================================================================================###

#Number of shared grid cells
# ----------------------------------------
# 1. Create the attendance table:
# ----------------------------------------

# 1.1 Filtering the rows with species presence
tabla_presencia_count <- grid_species_filtered %>%
  filter(!is.na(species)) %>%
  st_drop_geometry() %>%  
  group_by(cell_id, species) %>%
  summarise(presencia_total = n(), .groups = "drop")
head(tabla_presencia_count)


# 1.2 Pivoting: cells as rows, species as columns
matriz_coocurrencia <- tabla_presencia_count %>%
  pivot_wider(names_from = species, values_from = presencia_total, values_fill = list(presencia_total = 0))
head(matriz_coocurrencia)


# 1.3 Convert to matrix (without cell_id)
matriz_binaria <- as.matrix(matriz_coocurrencia[,-1])
rownames(matriz_binaria) <- matriz_coocurrencia$cell_id
str(matriz_binaria)

# 1.4 Make sure that everything is numeric (in case there are characters)
matriz_binaria <- apply(matriz_binaria, 2, as.numeric)
# Binary matrix in which each cell has the total number of occurrences for each species.

str(matriz_binaria)


# ----------------------------------------
# 2. Calculate co-occurrence matrix between species.
# ----------------------------------------
# Calculate co-occurrence between species
matriz_pa <- (matriz_binaria > 0) * 1
cooc_matrix <- t(matriz_pa) %*% matriz_pa


# Añadir nombres a las filas y columnas de la matriz
colnames(cooc_matrix) <- colnames(matriz_binaria)
rownames(cooc_matrix) <- colnames(matriz_binaria)

# Verificación
#head(cooc_matrix)

summary(as.vector(cooc_matrix))
sum(cooc_matrix == 0) / length(cooc_matrix)

# mirar distribución de “a” (co-ocurrencias reales)
hist(cooc_matrix[upper.tri(cooc_matrix)], breaks = 50)







# ----------------------------------------
# 3. Exportar - Matriz de co-ocurrencia absoluta
# ----------------------------------------

# Convert the matrix to data.frame in long format
cooc_df <- as.data.frame(as.table(cooc_matrix))

# Export
write.csv(cooc_df,  paste0(save_path, "/cooc_matrix_long_format.csv"), row.names = FALSE)
write.csv(cooc_matrix,  paste0(save_path, "/cooc_matrix_square.csv"))
saveRDS(cooc_matrix,  paste0(save_path, "/cooc_matrix.rds"))


#Number of shared grid cells
# Pairwise absolute co-occurrence matrix showing the number of grid cells (50 Km resolution) where each pair of benthic species was observed together. 
#Diagonal values indicate the total number of cells where each species occurred individually


###===================================================================================================================================###
### Co-occurrence dissimilarity matrix 
###===================================================================================================================================###
# Presence–absence similarity across grid cells

# ------------------------------------------
# JACCARD DISTANCE MATRIX
# ------------------------------------------

library(vegan)

# Transpose the binary matrix (species in columns, cells in rows)
matriz_binaria_transpuesta <- t(matriz_binaria)
#head(matriz_binaria_transpuesta)

# Calculate Jaccard's distance between species (by column)
jaccard_dist <- vegdist(matriz_binaria_transpuesta, method = "jaccard", binary = TRUE)

# Convert to square matrix
jaccard_matrix <- as.matrix(jaccard_dist)

# Verification of the Jaccard matrix
round(jaccard_matrix, 3)

# Convert Jaccard distance matrix to data frame (long format)
jaccard_df <- as.data.frame(as.table(jaccard_matrix))

# 0 = distribuciones muy similares
# 1 = distribuciones muy distintas

# Export
write.csv(jaccard_df, paste0(save_path,"/jaccard_distance_matrix_long_format.csv"), row.names = FALSE)
write.csv(jaccard_matrix, paste0(save_path,"/jaccard_distance_matrix_square.csv"))
saveRDS(jaccard_matrix,paste0(save_path, "/jaccard_distance_matrix.rds"))


summary(as.vector(jaccard_matrix))
hist(as.vector(jaccard_matrix), main="Jaccard dist")

jaccard_vals <- jaccard_matrix[upper.tri(jaccard_matrix)]
mean(jaccard_vals == 1) # el 47% de los pares no comparten ninguna celda




