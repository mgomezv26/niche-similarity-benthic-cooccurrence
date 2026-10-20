############################################
# LIBRERÍAS
############################################

library(dplyr)
library(sf)
library(hypervolume)
library(tidyr)
library(parallel)

############################################
# RUTAS
############################################

local <- "__CONFIGURE_PATH_01__"

data_dir  <- paste0(local, "/01_DATA/01_GRIDS/01_GRID_PROCESSED/01_GRIDS_FINAL")
hv_dir    <- paste0(local, "/03_Hypervolumes")
save_path <- paste0(local, "/03_Hypervolumes/02_Shoener")

setwd(local)

if (!dir.exists(save_path)) dir.create(save_path, recursive = TRUE)

############################################
# PARÁMETROS
############################################

var_axes <- c("PC1", "PC2", "PC3", "PC4", "PC5", "PC6")

# Reducción del espacio ambiental
digits_round <- 1

# Número objetivo de bins a muestrear
n_target_bins <- 100000

# Núcleos para paralelizar
n_cores <- max(1, parallel::detectCores() - 1)

message("Usando ", n_cores, " núcleos.")
message("digits_round = ", digits_round)
message("n_target_bins = ", n_target_bins)

set.seed(123)

############################################
# 1. CARGAR GRID AMBIENTAL
############################################

grid_realms_env <- st_read(
  paste0(data_dir, "/grid_env_realm_with_PCA6_axes.gpkg"),
  quiet = TRUE
)

data_env <- grid_realms_env %>%
  sf::st_drop_geometry() %>%
  distinct(cell_id, .keep_all = TRUE) %>%
  dplyr::select(cell_id, all_of(var_axes))

message("Número total de celdas ambientales originales: ", nrow(data_env))

############################################
# 2. CONSTRUIR BINS AMBIENTALES Y MUESTREAR
############################################

env_bins_full <- data_env %>%
  mutate(across(all_of(var_axes), ~ round(.x, digits_round))) %>%
  group_by(across(all_of(var_axes))) %>%
  summarise(
    weight_n_cells = n(), # es el número de celdas reales del grid original que caen en ese bin ambiental.
    cell_id_rep = first(cell_id),
    .groups = "drop"
  ) %>%
  mutate(bin_id = row_number()) %>%
  dplyr::select(bin_id, cell_id_rep, weight_n_cells, all_of(var_axes))

message("Número de bins ambientales antes del muestreo: ", nrow(env_bins_full))

# Muestreo de bins ponderado por disponibilidad ambiental
if (nrow(env_bins_full) > n_target_bins) {
  env_bins <- env_bins_full %>%
    slice_sample(
      n = n_target_bins,
      weight_by = weight_n_cells # Selecciona más frecuentemente los ambientes que realmente son más abundantes en el sistema.
    ) %>%
    mutate(bin_id = row_number())
} else {
  env_bins <- env_bins_full
}

message("Número de bins ambientales tras muestreo: ", nrow(env_bins))

saveRDS(
  env_bins,
  file.path(save_path, paste0("env_bins_sampled_round_", digits_round, "_n_", nrow(env_bins), ".rds"))
)

write.csv(
  env_bins,
  file.path(save_path, paste0("env_bins_sampled_round_", digits_round, "_n_", nrow(env_bins), ".csv")),
  row.names = FALSE
)

env_points_mat <- as.matrix(env_bins[, var_axes])

############################################
# 3. CARGAR DATOS DE ESPECIES Y FILTRAR
############################################

grid_realms_species <- st_read(
  paste0(data_dir, "/grid_species_qgis_coords.gpkg"),
  quiet = TRUE
)

data_species <- grid_realms_species %>%
  sf::st_drop_geometry()

message("Número inicial de especies: ", length(unique(data_species$species)))

species_valid <- data_species %>%
  group_by(species) %>%
  summarise(n_cells = n_distinct(cell_id), .groups = "drop") %>%
  filter(n_cells >= 10) %>%
  pull(species)

data_species <- data_species %>%
  filter(species %in% species_valid)

message("Número de especies tras filtro >=10 celdas: ",
        length(unique(na.omit(data_species$species))))

data_species_with_all_vars <- left_join(data_species, data_env, by = "cell_id") %>%
  filter(!is.na(species)) %>%
  distinct(cell_id, species, .keep_all = TRUE)

cat_list_Species <- sort(unique(data_species_with_all_vars$species))
num_cat_Species <- length(cat_list_Species)

message("Número final de especies: ", num_cat_Species)
message("Número de ejes ambientales: ", length(var_axes))

############################################
# 4. CARGAR LISTA DE HIPERVOLÚMENES
############################################

load(file.path(hv_dir, "hv_list_all_species.RData"))

if (!exists("hv_list_Species")) {
  stop("No se ha cargado el objeto 'hv_list_Species' desde hv_list_all_species.RData")
}

message("Número de hipervolúmenes en hv_list_Species: ", length(hv_list_Species@HVList))

if (length(hv_list_Species@HVList) < num_cat_Species) {
  warning("La lista de hipervolúmenes tiene menos elementos que el número de especies esperado.")
}

############################################
# 5. EVALUAR HIPERVOLÚMENES EN BINS COMUNES (PARALELO)
############################################

message("Iniciando evaluación paralela de hipervolúmenes...")

cl <- makeCluster(n_cores)

clusterExport(cl, varlist = c(
  "hv_list_Species",
  "cat_list_Species",
  "num_cat_Species",
  "env_points_mat",
  "env_bins"
), envir = environment())

clusterEvalQ(cl, {
  library(hypervolume) # cada núcleo carga hypervolume
  NULL
})

z_list <- parLapply(cl, seq_len(num_cat_Species), function(i) {
  
  sp_name <- cat_list_Species[i]
  hv <- hv_list_Species@HVList[[i]]
  
  if (is.null(hv)) {
    warning(paste("Hipervolumen NULL para:", sp_name))
    return(NULL)
  }
  
  out <- tryCatch({
    
    dens_common <- hypervolume_estimate_probability(
      hv,
      points = env_points_mat
    )
    
    dens_common[is.na(dens_common)] <- 0
    dens_common[dens_common < 0] <- 0
    
    # Ponderación por número de celdas reales representadas
    dens_weighted <- dens_common * env_bins$weight_n_cells
    
    total_dens <- sum(dens_weighted)
    
    if (total_dens == 0) {
      warning(paste("La suma de densidades ponderadas es 0 para:", sp_name))
      z <- rep(0, nrow(env_bins))
    } else {
      z <- dens_weighted / total_dens
    }
    
    data.frame(
      species = sp_name,
      bin_id = env_bins$bin_id,
      cell_id_rep = env_bins$cell_id_rep,
      weight_n_cells = env_bins$weight_n_cells,
      z = z
    )
    
  }, error = function(e) {
    warning(paste("Error con", sp_name, ":", conditionMessage(e)))
    return(NULL)
  })
  
  out
})

stopCluster(cl)

z_list_clean <- z_list[!sapply(z_list, is.null)]

message("Número de especies con z calculada correctamente: ", length(z_list_clean))

if (length(z_list_clean) == 0) {
  stop("No se ha podido calcular z para ninguna especie.")
}

z_df <- bind_rows(z_list_clean)

############################################
# 6. COMPROBAR NORMALIZACIÓN
############################################

check_z <- z_df %>%
  group_by(species) %>%
  summarise(sum_z = sum(z), .groups = "drop")

print(check_z)

check_z_bad <- check_z %>%
  filter(abs(sum_z - 1) > 1e-6)

if (nrow(check_z_bad) > 0) {
  warning("Hay especies cuya suma de z no es ~1. Revisa check_z_bad.")
  print(check_z_bad)
}

############################################
# 7. GUARDAR z_ij
############################################

saveRDS(
  z_df,
  file.path(save_path, paste0("schoener_z_on_common_bins_weighted_round_", digits_round,
                              "_n_", nrow(env_bins), ".rds"))
)

write.csv(
  z_df,
  file.path(save_path, paste0("schoener_z_on_common_bins_weighted_round_", digits_round,
                              "_n_", nrow(env_bins), ".csv")),
  row.names = FALSE
)

############################################
# 8. PASAR z A MATRIZ bins x especies
############################################

species_ok <- sort(unique(z_df$species))
n_species_ok <- length(species_ok)
n_bins <- nrow(env_bins)

message("Construyendo matriz Z de tamaño: ", n_bins, " bins x ", n_species_ok, " especies")

Z_mat <- matrix(0, nrow = n_bins, ncol = n_species_ok)
colnames(Z_mat) <- species_ok
rownames(Z_mat) <- env_bins$bin_id

for (k in seq_along(species_ok)) {
  sp <- species_ok[k]
  
  z_sp <- z_df %>%
    filter(species == sp) %>%
    arrange(bin_id)
  
  Z_mat[, k] <- z_sp$z
}

############################################
# 9. CALCULAR SCHOENER'S D EFICIENTEMENTE
############################################

message("Calculando distancias Manhattan entre especies...")

manhattan_dist <- as.matrix(dist(t(Z_mat), method = "manhattan"))

# Schoener D = 1 - 0.5 * L1
D_mat <- 1 - 0.5 * manhattan_dist

# Seguridad numérica
D_mat[D_mat < 0] <- 0
D_mat[D_mat > 1] <- 1

############################################
# 10. PASAR MATRIZ D A FORMATO LARGO
############################################

D_results_df <- as.data.frame(as.table(D_mat), stringsAsFactors = FALSE) %>%
  rename(
    sp1 = Var1,
    sp2 = Var2,
    schoener_D = Freq
  ) %>%
  filter(sp1 < sp2)

############################################
# 11. GUARDAR RESULTADOS FINALES
############################################

saveRDS(
  D_mat,
  file.path(save_path, paste0("schoener_D_matrix_round_", digits_round,
                              "_n_", nrow(env_bins), ".rds"))
)

saveRDS(
  D_results_df,
  file.path(save_path, paste0("schoener_D_pairs_round_", digits_round,
                              "_n_", nrow(env_bins), ".rds"))
)

write.csv(
  D_results_df,
  file.path(save_path, paste0("schoener_D_pairs_round_", digits_round,
                              "_n_", nrow(env_bins), ".csv")),
  row.names = FALSE
)

message("✅ Cálculo de Schoener's D completado correctamente.")

head(D_results_df)
