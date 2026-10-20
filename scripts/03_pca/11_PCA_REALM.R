
º

###===================================================================================================================================###
### DEFINE THE WORKING DIRECTORY
###===================================================================================================================================###


local = "__CONFIGURE_PATH_01__"
setwd(local)
data_dir = paste0(local,"/01_DATA/01_GRIDS/01_GRID_PROCESSED/01_GRIDS_FINAL")
#save_path=paste0(local,"/01_DATA/01_GRIDS/01_GRID_PROCESSED")



###===================================================================================================================================###
### LOAD DATA ENV
###===================================================================================================================================###

grid_realms_env <- st_read(paste0(data_dir,"/grid_realms_0_1_env_clean.gpkg"))
data_env <- grid_realms_env %>% 
  sf::st_drop_geometry()

colnames(data_env)

colSums(is.na(data_env))

#estandarizar la variable del tamaño de sedimento ya que tiene valores del 1 al 5
data_env$r_sediment_size_z <- scale(data_env$r_sediment_size)


###===================================================================================================================================###
### CORRELACION Y PCA
###===================================================================================================================================###

# seleccionar variables numericas que se quieren analizar, las  variables oceanograficas

vars_numeric <- data_env[, c("bathymetry", "o2", "ph", "phyc", 
                              "po4", "so", "sws", "thetao", 
                              "chl", "r_sediment_size_z")]

###===================================================================================================================================###
### 2. PCA
###===================================================================================================================================###
pca_env <- prcomp(vars_numeric, scale. = FALSE)  # No escalar porque ya están estandarizadas

# Resumen de la varianza explicada
summary(pca_env)
pca_env

# Gráfico de autovalores (scree plot)
fviz_eig(pca_env, addlabels = TRUE)

# Gráfico de variables (cómo contribuye cada variable a los ejes)
fviz_pca_var(pca_env, col.var = "contrib", 
              gradient.cols = c("#80146E", "#4F87BF", "#48C2BE"),
              repel = TRUE)



###===================================================================================================================================###
### 3. CRITERIO DE BROKEN STICK
###===================================================================================================================================###

# Autovalores (varianza por eje)
eig_vals <- pca_env$sdev^2

# Proporción de varianza explicada
prop_exp <- eig_vals / sum(eig_vals)

# Modelo Broken Stick
bs <- bstick(length(eig_vals))

# Combinar en un data.frame
pca_variance <- data.frame(
  Axis = 1:length(eig_vals),
  Eigenvalue = eig_vals,
  Proportion = prop_exp,
  BrokenStick = bs
)

# Visualización
ggplot(pca_variance, aes(x = Axis)) +
  geom_line(aes(y = Proportion), color = "blue", linewidth = 1) +
  geom_point(aes(y = Proportion), color = "blue", size = 2) +
  geom_line(aes(y = BrokenStick), color = "red", linetype = "dashed") +
  geom_point(aes(y = BrokenStick), color = "red", size = 2) +
  labs(title = "Criterio de Broken Stick - PCA ambiental",
        y = "Proporción de varianza explicada",
        x = "Componente principal") +
  theme_minimal()

# Ejes a conservar según Broken Stick
pca_variance$retener <- pca_variance$Proportion > pca_variance$BrokenStick
pca_variance

# Opcional: quedarte solo con los ejes que expliquen > 5 % de varianza
retained_axes <- which(pca_variance$retener & pca_variance$Proportion > 0.05)
retained_axes
pca_variance


#===========================================================================
# Gráfico de autovalores / Scree plot

ggplot(pca_variance, aes(x = Axis)) +
  geom_bar(aes(y = Proportion), stat = "identity", fill = "steelblue") +
  geom_line(aes(y = BrokenStick), color = "red", linetype = "dashed") +
  geom_point(aes(y = BrokenStick), color = "red", size = 2) +
  labs(y = "Proporción de varianza explicada", x = "Componente principal",
        title = "Varianza explicada y modelo Broken Stick") +
  theme_minimal()

library(ggplot2)

# Asegúrate de tener los valores listos
# (ya generados previamente)
# pca_variance <- data.frame(Axis, Eigenvalue, Proportion, BrokenStick)

# Convertir a porcentajes
pca_variance$Proportion_pct <- pca_variance$Proportion * 100
pca_variance$BrokenStick_pct <- pca_variance$BrokenStick * 100

svg_file <- paste0(local, "/PCA_variance_BS.svg")
svg(svg_file, width = 8, height = 6, family = "sans")

# Crear figura
ggplot(pca_variance, aes(x = Axis)) +
  # Barras de varianza explicada observada
  geom_bar(aes(y = Proportion_pct), stat = "identity",
            fill = "#D6EAEF", width = 0.7, alpha = 0.8) +
  
  # Línea negra que une los valores observados
  geom_line(aes(y = Proportion_pct), color = "#2EA4C2", linewidth = 0.8) +
  geom_point(aes(y = Proportion_pct), color = "#2EA4C2", size = 2) +
  
  # Línea y puntos del modelo Broken Stick
  geom_line(aes(y = BrokenStick_pct), color = "#80146E", linetype = "dashed", linewidth = 0.8) +
  geom_point(aes(y = BrokenStick_pct), color = "#80146E", size = 2) +
  
  # Etiquetas de porcentaje sobre las barras
  geom_text(aes(y = Proportion_pct + 1, 
                label = paste0(round(Proportion_pct, 1), "%")),
            size = 3.5, color = "black") +
  
  # Ejes y tema
  labs(title = "Explained variance and the Broken Stick model – Environmental PCA",
        x = "Main component",
        y = "Percentage of variance explained") +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    panel.grid.minor = element_blank()
  ) +
  
  # Límites del eje Y
  ylim(0, max(pca_variance$Proportion_pct) + 5) +
  
  # Leyenda manual
  annotate("text", x = max(pca_variance$Axis) - 3, 
            y = max(pca_variance$BrokenStick_pct) - 2, 
            label = "Broken Stick Model", color = "#80146E", size = 3.5, hjust = 0) +
  annotate("text", x = 2, y = max(pca_variance$Proportion_pct) - 2, 
            label = "Observed variance", color = "#2EA4C2", size = 3.5, hjust = 0)
dev.off()

#===========================================================================
# Biplots (variables vs componentes)
library(factoextra)

# Variables (dirección y correlación)
fviz_pca_var(pca_env, axes = c(1, 2), col.var = "contrib",
              gradient.cols = c("#80146E", "#4F87BF", "#48C2BE"),
              repel = TRUE, title = "PCA ambiental - variables (PC1 vs PC2)")

fviz_pca_var(pca_env, axes = c(3, 4), col.var = "contrib",
              gradient.cols =c("#80146E", "#4F87BF", "#48C2BE"),
              repel = TRUE, title = "PCA ambiental - variables (PC3 vs PC4)")

#===========================================================================
# 4.Correlación de variables con cada componente
#===========================================================================

# Extraer cargas (loadings)
loadings <- as.data.frame(pca_env$rotation)

# Pasar a formato largo
loadings_long <- loadings %>%
  mutate(Variable = rownames(loadings)) %>%
  pivot_longer(cols = starts_with("PC"), names_to = "Componente", values_to = "Carga") %>%
  filter(Componente %in% paste0("PC", 1:6))

# Crear paleta discreta a partir de la continua Purple–Yellow
palette_purple_yellow <- paletteer_c("grDevices::Purple-Yellow", 30)
palette_6 <- palette_purple_yellow[c(1, 6, 12, 18, 22, 29)]


# Gráfico
ggplot(loadings_long, aes(x = Variable, y = Carga, fill = Componente)) +
  geom_bar(stat = "identity", position = "dodge", color = "grey30") +
  
  # 🔹 Líneas guía en ±0.5
  geom_hline(yintercept = c(-0.5, 0.5), linetype = "dotted", color = "grey40") +
  
  coord_flip() +
  scale_fill_manual(values = palette_6) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.y = element_text(size = 11, color = "black"),
    axis.text.x = element_text(size = 10),
    legend.position = "top",
    legend.title = element_blank(),
    plot.title = element_text(face = "bold", hjust = 0.5)
  ) +
  labs(
    title = "Contribution of environmental variables to the first six PCA axes",
    y = "Loading (correlation with component)", 
    x = ""
  )


#===========================================================================
# Tabla completa de cargas
#===========================================================================
# Crear tabla de cargas (loadings)
loadings_table <- round(pca_env$rotation[, 1:6], 3)  # primeros 6 ejes, redondeo a 3 decimales
loadings_table


# Añadir columna de variable
loadings_table <- data.frame(Variable = rownames(loadings_table), loadings_table)

# Mostrar la tabla ordenada por PC1
loadings_table <- loadings_table[order(-abs(loadings_table$PC1)), ]

# Visualizar
print(loadings_table)

write.csv(loadings_table, file = paste0(local, "/PCA_env_loadings_table.csv"), row.names = FALSE)

#===========================================================================
# Tabla resumida por eje (top variables por componente)
#===========================================================================

loadings_long <- loadings_table %>%
  as.data.frame() %>%
  tibble::rownames_to_column("Variable") %>%
  pivot_longer(cols = starts_with("PC"), 
               names_to = "Componente", 
               values_to = "Carga") %>%
  group_by(Componente) %>%
  arrange(desc(abs(Carga))) %>%
  slice_head(n = 3) # top 3 variables por eje

loadings_long

write.csv(loadings_long, file = paste0(local, "/PCA_env_top3_variables_per_component.csv"), row.names = FALSE)

library(ggplot2)
library(tidyr)
library(dplyr)
library(paletteer)

# Extraer cargas (loadings)
loadings <- as.data.frame(pca_env$rotation)

# Pasar a formato largo
loadings_long <- loadings %>%
  mutate(Variable = rownames(loadings)) %>%
  pivot_longer(cols = starts_with("PC"),
                names_to = "Componente",
                values_to = "Carga") %>%
  filter(Componente %in% paste0("PC", 1:6))

# Paleta Tropic
palette_tropic <- paletteer_c("grDevices::RdBu", 30)

# Gráfico tipo heatmap
ggplot(loadings_long, aes(x = Componente, y = Variable, fill = Carga)) +
  geom_tile(color = "white") +
  scale_fill_gradientn(colors = palette_tropic,
                        limits = c(-1, 1),
                        name = "Correlation") +
  theme_minimal(base_size = 13) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        axis.text.y = element_text(size = 10),
        panel.grid = element_blank(),
        plot.title = element_text(face = "bold", hjust = 0.5)) +
  labs(title = "Variable loadings on the first six PCA axes",
        x = "Main component",
        y = "Oceanographic variable")


paletteer_c("grDevices::RdBu", 30)

###===================================================================================================================================###
### 5. UNIR LOS 6 PRIMEROS EJES DE LA PCA AL GRID
###===================================================================================================================================###

# Extraer las coordenadas PCA (scores para cada celda)
pca_scores <- as.data.frame(pca_env$x)

# Seleccionar los 6 primeros ejes manualmente
retained_axes <- 1:6
pca_scores_sel <- pca_scores[, retained_axes, drop = FALSE]

# Renombrar columnas
colnames(pca_scores_sel) <- paste0("PC", retained_axes)

# Unir los scores al dataframe original (sin geometría)
data_env_with_pca <- cbind(data_env, pca_scores_sel)

head(data_env_with_pca)

# Volver a unir la geometría al grid
grid_env_with_pca <- cbind(grid_realms_env, pca_scores_sel)

# Guardar el grid con los ejes de PCA añadidos
output_path <- paste0(data_dir, "/grid_env_realm_with_PCA6_axes.gpkg")
st_write(grid_env_with_pca, output_path, delete_layer = TRUE)
