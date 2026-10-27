
# ============================================================
# ANALISIS RESIDUOS LOCALES
# ============================================================

# Reorganizado desde 04_Analisis_residuos_locales.R.
# Los calculos y parametros originales se conservan sin validacion numerica.

library(tidyverse)
library(dplyr)
library(scales)
library(here)

# ============================================================
# 1. RUTAS RELATIVAS AL REPOSITORIO
# ============================================================

local_cooccurrence <- here("data", "processed", "local_analyses", "norway", "cooccurrence_matrices")
residuals_dir <- here("results", "local_analyses", "expected_vs_observed")

# Entrada derivada para el analisis ambiental de Noruega (07_04).
processed_dir <- here("data", "processed", "local_analyses", "norway")
# Estadisticas y figura del analisis local.
results_dir <- here("results", "local_analyses", "residuals")
figures_dir <- file.path(results_dir, "figures")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

required_inputs <- c(
  file.path(local_cooccurrence, "presence_absence_5m.csv"),
  file.path(local_cooccurrence, "presence_absence_40m.csv"),
  file.path(local_cooccurrence, "presence_absence_400m.csv"),
  file.path(residuals_dir, "residuals_diff_obs_exp.csv")
)
missing_inputs <- required_inputs[!file.exists(required_inputs)]
if (length(missing_inputs) > 0L) {
  stop("Faltan archivos de entrada:\n", paste(missing_inputs, collapse = "\n"))
}

# ============================================================
# 2. CARGAR MATRICES PRESENCIA-AUSENCIA LOCALES
# ============================================================

pa_5m_raw <- read.csv(
  file.path(local_cooccurrence, "presence_absence_5m.csv")
)

pa_40m_raw <- read.csv(
  file.path(local_cooccurrence, "presence_absence_40m.csv")
)

pa_400m_raw <- read.csv(
  file.path(local_cooccurrence, "presence_absence_400m.csv")
)

head(pa_400m_raw)
summary(pa_5m_raw)
# ============================================================
# 3. CARGAR RESIDUOS LOCALES
# ============================================================

local_residuals <- read.csv(
  file.path(residuals_dir, "residuals_diff_obs_exp.csv")
)

head(local_residuals)
summary(local_residuals)
length(unique(pa_5m_raw$X)) # 85179

# ============================================================
# 4. FUNCIONES AUXILIARES
# ============================================================

clean_sp_names <- function(x) {
  x %>%
    as.character() %>%
    trimws() %>%
    gsub("\\.", " ", .) %>%
    gsub("_", " ", .) %>%
    gsub("\\s+", " ", .)
}

# matrices de presencia: SampID × species
fix_pa_matrix <- function(df) { 
  
  df <- as.data.frame(df)
  
  rownames(df) <- df$X
  
  df <- df %>%
    select(-X)
  
  colnames(df) <- clean_sp_names(colnames(df))
  
  mat <- as.matrix(df)
  mode(mat) <- "numeric"
  
  return(mat)
}

# ============================================================
# 5. FI MATRICES
# ============================================================

pa_5m <- fix_pa_matrix(pa_5m_raw)
pa_40m <- fix_pa_matrix(pa_40m_raw)
pa_400m <- fix_pa_matrix(pa_400m_raw)
head(pa_400m)

# ============================================================
# 6. CLEAN NAMES IN RESIDUALS AND RESCALE
# ============================================================

local_residuals$sp1 <- clean_sp_names(local_residuals$sp1)
local_residuals$sp2 <- clean_sp_names(local_residuals$sp2)

head(local_residuals)
# Se conserva la eliminacion de la primera columna del CSV historico.
# Revisar su correspondencia con el formato exportado por 07_02 antes de ejecutar.
local_residuals <- local_residuals[ ,-1]
names(local_residuals)

local_residuals <-local_residuals%>%
  mutate(expected_prob  = (residual + 1) / 2)

head(local_residuals)

# ============================================================
# 7. CALCULATE MEAN EXPECTED PROBABILITY PER SAMPID
# ============================================================

calculate_community_expected_prob <- function(pa_mat,
                                              residual_df,
                                              scale_name) {
  
  residual_df_scale <- residual_df %>%
    filter(scale == scale_name)
  
  results <- lapply(rownames(pa_mat), function(samp) {
    
    spp_present <- names(which(pa_mat[samp, ] == 1))
    
    if(length(spp_present) < 2) {
      return(data.frame(
        SampID = samp,
        scale = scale_name,
        n_species = length(spp_present),
        n_pairs = 0,
        mean_expected_prob = NA,
        median_expected_prob = NA,
        sd_expected_prob = NA
      ))
    }
    
    pairs <- combn(spp_present, 2)
    
    residual_values <- apply(pairs, 2, function(pair) {
      
      spA <- pair[1]
      spB <- pair[2]
      
      match_row <- residual_df_scale %>%
        filter(
          (sp1 == spA & sp2 == spB) |
            (sp1 == spB & sp2 == spA)
        )
      
      if(nrow(match_row) == 0) {
        return(NA_real_)
      } else {
        return(match_row$expected_prob[1])
      }
    })
    
    data.frame(
      SampID = samp,
      scale = scale_name,
      n_species = length(spp_present),
      n_pairs = sum(!is.na(residual_values)),
      mean_expected_prob = mean(residual_values, na.rm = TRUE),
      median_expected_prob = median(residual_values, na.rm = TRUE),
      sd_expected_prob = sd(residual_values, na.rm = TRUE)
    )
  })
  
  bind_rows(results)
}


# ============================================================
# 8. RESIDUOS COMUNITARIOS POR ESCALA
# ============================================================

community_5m <- calculate_community_expected_prob(pa_5m, local_residuals, "5m")
community_40m <- calculate_community_expected_prob(pa_40m, local_residuals, "40m")
community_400m <- calculate_community_expected_prob(pa_400m, local_residuals, "400m")

community_resid_all <- bind_rows(
  community_5m,
  community_40m,
  community_400m
)

head(community_resid_all)

table(community_resid_all$scale)

# 400m   40m    5m 
# 1664 18286 85179 

n_communiy <- community_resid_all %>%
  group_by(scale) %>%
  summarise(
    total = n(),
    no_pairs = sum(n_pairs == 0),
    with_pairs = sum(n_pairs > 0),
    pct_no_pairs = round(100 * mean(n_pairs == 0), 2)
  )

n_communiy

write.csv(n_communiy, file.path(results_dir, "info_n_community.csv"),row.names = F)

# # A tibble: 3 × 5
# scale total no_pairs with_pairs pct_no_pairs
# <chr> <int>    <int>      <int>        <dbl>
#  400m   1664      182       1482         10.9
#  40m   18286     6832      11454         37.4
#  5m    85179    59308      25871         69.6


# FILTRAR COMUNIDADES SIN PARES
community_resid_all_filt <- community_resid_all %>%
  filter(n_pairs > 0)

summary(community_resid_all_filt$mean_expected_prob)
head(community_resid_all_filt)

write.csv(community_resid_all_filt, file.path(processed_dir, "community_expected_cooccurrence_probability_all_filt.csv"),row.names = F)


kruskal.test(
  mean_expected_prob ~ scale,
  data = community_resid_all_filt
)




# PLOT

colors <- c(
  "5m"   = "#80cdc1",
  "40m"  = "#a6cee3",
  "400m" = "#ba8bc9ff"
)

community_resid_all_filt$scale <- factor(
  community_resid_all_filt$scale,
  levels = c("5m", "40m", "400m")
)

boxplot <- ggplot(
  community_resid_all_filt,
  aes(
    x = scale,
    y = mean_expected_prob,
    fill = scale
  )
) +
  geom_violin(
    trim = TRUE,
    alpha = 0.35,
    color = NA,
    scale = "width"
  ) +
  geom_boxplot(
    width = 0.12,
    color = "black",
    outlier.shape = NA,
    linewidth = 0.6
  ) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  scale_fill_manual(values = colors) +
  labs(
    y = "Mean pairwise expected co-occurrence probability",
    x = "Spatial scale"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none",
    axis.title.y = element_text(size = 12, face = "bold"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 12),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank()
  )

boxplot

ggsave(file.path(figures_dir, "Mean_expected_cooccurrence_probability_boxplot.png"), plot = boxplot, width = 7, height = 5, units = "in", dpi = 600)

