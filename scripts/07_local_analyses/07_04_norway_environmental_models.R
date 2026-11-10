# ============================================================================
# 07_04_norway_environmental_models.R
# ============================================================================

# Local environmental relationships with expected co-occurrence (5, 40, 400 m).
# Scientific model formulae, filters, and AIC selection retained from source.
# Historical numerical equivalence has NOT been validated.
# Output: correlation CSV, model summary CSV, coefficient plot PDF and PNG.
# Model selection (dredge), VIF and importance heatmap are calculated in memory,
# as in the original script; they are not exported.

library(here)
library(dplyr)
library(readr)
library(terra)
library(tibble)
library(corrplot)
library(car)
library(ggplot2)
library(broom)
library(MuMIn)
library(tidyr)

# ============================================================
# R AND PACKAGE VERSIONS
# ============================================================
# Versions from the current runtime, not the historical analysis environment.

cat("R version:", R.version.string, "\n") # R version: 4.5.1 (2025-06-13 ucrt)

cat("Versions of the libraries used:\n")
cat("here:", as.character(packageVersion("here")), "\n") # here: 1.0.2
cat("dplyr:", as.character(packageVersion("dplyr")), "\n") # dplyr: 1.1.4
cat("readr:", as.character(packageVersion("readr")), "\n") # readr: 2.1.5
cat("terra:", as.character(packageVersion("terra")), "\n") # terra: 1.8.54
cat("tibble:", as.character(packageVersion("tibble")), "\n") # tibble: 3.3.0
cat("corrplot:", as.character(packageVersion("corrplot")), "\n") # corrplot: 0.95
cat("car:", as.character(packageVersion("car")), "\n") # car: 3.1.3
cat("ggplot2:", as.character(packageVersion("ggplot2")), "\n") # ggplot2: 4.0.0
cat("broom:", as.character(packageVersion("broom")), "\n") # broom: 1.0.10
cat("MuMIn:", as.character(packageVersion("MuMIn")), "\n") # MuMIn: 1.48.11
cat("tidyr:", as.character(packageVersion("tidyr")), "\n") # tidyr: 1.3.1
cat("magrittr:", as.character(packageVersion("magrittr")), "\n") # magrittr: 2.0.3

# Paths relative to repository root (the .here marker).
# The expected-cooccurrence table is an INPUT from another local workflow,
# not produced by this script. Verify its generating script before execution.

env_file <- here("data", "raw", "local_analyses", "norway", "environmental", "env_full-001.tif")
prob_file <- here("data", "processed", "local_analyses", "norway",
                  "community_expected_cooccurrence_probability_all_filt.csv")
sample_files <- c(
  "5m" = here("data", "raw", "local_analyses", "norway", "samples", "5m", "sample_info_5m_ready.csv"),
  "40m" = here("data", "raw", "local_analyses", "norway", "samples", "40m", "sample_info_40m_ready.csv"),
  "400m" = here("data", "raw", "local_analyses", "norway", "samples", "400m", "sample_info.csv")
)
output_dir <- here("results", "local_analyses", "norway", "environmental_models")
figures_dir <- file.path(output_dir, "figures")
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

inputs <- c(env_file, prob_file, sample_files)
missing_inputs <- inputs[!file.exists(inputs)]
if (length(missing_inputs) > 0L) {
  stop("Missing required input files:\n", paste(missing_inputs, collapse = "\n"))
}

# ============================================================
# OCEANOGRAPHIC VARIABLES
# ============================================================

env <- rast(env_file)

env_sel <- env[[c(
  "bathy200_sed",
  "mud",
  "sand",
  "gravel",
  "rock",
  "temp_mean",
  "salt_mean",
  "spd_mean",
  "Dissolved.oxygen.Mean",
  "Chlorophyll.Mean",
  "qslope9",
  "wbtgm_i2o8f1"
)]]

# ============================================================
# 2. MEAN EXPECTED CO-OCURRENCE PROBABILITY DATA
# ============================================================

mean_prob_df <- read_csv(prob_file, show_col_types = FALSE)

mean_prob_5m <- mean_prob_df%>% filter(scale=="5m")
mean_prob_40m <- mean_prob_df%>% filter(scale=="40m")
mean_prob_400m <- mean_prob_df%>% filter(scale=="400m")

mean_prob_df

summary(mean_prob_df$mean_expected_prob)

# ============================================================
# 3. 5M 
# ============================================================

sample_5m <- read_csv(sample_files[["5m"]], show_col_types = FALSE)

coords_5m <- sample_5m %>%
  rename(
    SampID = ID_5,
    X = X_5m,
    Y = Y_5m
  ) %>%
  semi_join(
    mean_prob_5m,
    by = "SampID"
  ) %>%
  select(SampID, X, Y)

# extract data from the raster
env_5m <- terra::extract(
  env_sel,
  as.matrix(coords_5m[, c("X", "Y")])
)

env_5m <- bind_cols(
  coords_5m,
  env_5m[, -1]
)
head(env_5m)

# Join oceanographic variables + mean probability
mean_prob_5m_env <- mean_prob_5m %>%
  left_join(env_5m, by = "SampID")

nrow(mean_prob_5m)
nrow(mean_prob_5m_env)

colSums(is.na(mean_prob_5m_env))

# inspect null values to see whether they are in the same columns
mean_prob_5m_env %>%
  summarise(across(
    c(bathy200_sed, mud, sand, gravel, rock,
      temp_mean, salt_mean, spd_mean,
      Dissolved.oxygen.Mean,
      Chlorophyll.Mean,
      qslope9, wbtgm_i2o8f1),
    ~ sum(is.na(.))
  ))

sum(!complete.cases(
  mean_prob_5m_env[, c(
    "bathy200_sed",
    "mud",
    "sand",
    "gravel",
    "rock",
    "temp_mean",
    "salt_mean",
    "spd_mean",
    "Dissolved.oxygen.Mean",
    "Chlorophyll.Mean",
    "qslope9",
    "wbtgm_i2o8f1"
  )]
))


mean_prob_5m_env_filt <- mean_prob_5m_env %>%
  filter(
    complete.cases(
      bathy200_sed,
      mud,
      sand,
      gravel,
      rock,
      temp_mean,
      salt_mean,
      spd_mean,
      Dissolved.oxygen.Mean,
      Chlorophyll.Mean,
      qslope9,
      wbtgm_i2o8f1
    )
  )

head(mean_prob_5m_env_filt)

summary(mean_prob_5m_env_filt$mean_expected_prob)

hist(mean_prob_5m_env_filt$mean_expected_prob,
     breaks = 50)

# ============================================================
# 4. 40 M 
# ============================================================

sample_40m <- read_csv(sample_files[["40m"]], show_col_types = FALSE)

coords_40m <- sample_40m %>%
  rename(
    SampID = ID_40,
    X = X_40m,
    Y = Y_40m
  ) %>%
  semi_join(
    mean_prob_40m,
    by = "SampID"
  ) %>%
  select(SampID, X, Y)

# extract data from the raster
env_40m <- terra::extract(
  env_sel,
  as.matrix(coords_40m[, c("X", "Y")])
)

env_40m <- bind_cols(
  coords_40m,
  env_40m[, -1]
)
head(env_40m)

# Join oceanographic variables + mean probability
mean_prob_40m_env <- mean_prob_40m %>%
  left_join(env_40m, by = "SampID")

nrow(mean_prob_40m)
nrow(mean_prob_40m_env)

colSums(is.na(mean_prob_40m_env))

# inspect null values to see whether they are in the same columns
mean_prob_40m_env %>%
  summarise(across(
    c(bathy200_sed, mud, sand, gravel, rock,
      temp_mean, salt_mean, spd_mean,
      Dissolved.oxygen.Mean,
      Chlorophyll.Mean,
      qslope9, wbtgm_i2o8f1),
    ~ sum(is.na(.))
  ))

sum(!complete.cases(
  mean_prob_40m_env[, c(
    "bathy200_sed",
    "mud",
    "sand",
    "gravel",
    "rock",
    "temp_mean",
    "salt_mean",
    "spd_mean",
    "Dissolved.oxygen.Mean",
    "Chlorophyll.Mean",
    "qslope9",
    "wbtgm_i2o8f1"
  )]
))


mean_prob_40m_env_filt <- mean_prob_40m_env %>%
  filter(
    complete.cases(
      bathy200_sed,
      mud,
      sand,
      gravel,
      rock,
      temp_mean,
      salt_mean,
      spd_mean,
      Dissolved.oxygen.Mean,
      Chlorophyll.Mean,
      qslope9,
      wbtgm_i2o8f1
    )
  )

head(mean_prob_40m_env_filt)

summary(mean_prob_40m_env_filt$mean_expected_prob)

hist(mean_prob_40m_env_filt$mean_expected_prob,
     breaks = 50)


# ============================================================
# 5. 400 M 
# ============================================================

sample_400m <- read_csv(sample_files[["400m"]], show_col_types = FALSE)

coords_400m <- sample_400m %>%
  rename(
    SampID = ID_400,
    X = X_400m,
    Y = Y_400m
  ) %>%
  semi_join(
    mean_prob_400m,
    by = "SampID"
  ) %>%
  select(SampID, X, Y)

# extract data from the raster
env_400m <- terra::extract(
  env_sel,
  as.matrix(coords_400m[, c("X", "Y")])
)

env_400m <- bind_cols(
  coords_400m,
  env_400m[, -1]
)
head(env_400m)

# Join oceanographic variables + mean probability
mean_prob_400m_env <- mean_prob_400m %>%
  left_join(env_400m, by = "SampID")

nrow(mean_prob_400m)
nrow(mean_prob_400m_env)

colSums(is.na(mean_prob_400m_env))

# inspect null values to see whether they are in the same columns
mean_prob_400m_env %>%
  summarise(across(
    c(bathy200_sed, mud, sand, gravel, rock,
      temp_mean, salt_mean, spd_mean,
      Dissolved.oxygen.Mean,
      Chlorophyll.Mean,
      qslope9, wbtgm_i2o8f1),
    ~ sum(is.na(.))
  ))

sum(!complete.cases(
  mean_prob_400m_env[, c(
    "bathy200_sed",
    "mud",
    "sand",
    "gravel",
    "rock",
    "temp_mean",
    "salt_mean",
    "spd_mean",
    "Dissolved.oxygen.Mean",
    "Chlorophyll.Mean",
    "qslope9",
    "wbtgm_i2o8f1"
  )]
))


mean_prob_400m_env_filt <- mean_prob_400m_env %>%
  filter(
    complete.cases(
      bathy200_sed,
      mud,
      sand,
      gravel,
      rock,
      temp_mean,
      salt_mean,
      spd_mean,
      Dissolved.oxygen.Mean,
      Chlorophyll.Mean,
      qslope9,
      wbtgm_i2o8f1
    )
  )

head(mean_prob_400m_env_filt)

summary(mean_prob_400m_env_filt$mean_expected_prob)

hist(mean_prob_400m_env_filt$mean_expected_prob,
     breaks = 50)


# ============================================================
# 5. COMBINE ALL 
# ============================================================


mean_prob_all <- bind_rows(
  mean_prob_5m_env_filt,
  mean_prob_40m_env_filt,
  mean_prob_400m_env_filt
)

kruskal.test(
  mean_expected_prob ~ scale,
  data = mean_prob_all
)

# ============================================================
# 6. CORRELATION MATRIX BETWEEN VARIABLES
# ============================================================

env_vars_all <- mean_prob_all %>%
  select(
    bathy200_sed, mud, sand, gravel, rock,
    temp_mean, salt_mean, spd_mean,
    Dissolved.oxygen.Mean, Chlorophyll.Mean,
    qslope9, wbtgm_i2o8f1
  )

cor_all <- cor(env_vars_all, use = "pairwise.complete.obs")

round(cor_all, 2)

write.csv(cor_all, file.path(output_dir, "cor_vars_sel.csv"))

colnames(cor_all) <- c(
  "Bathymetry",
  "Mud",
  "Sand",
  "Gravel",
  "Rock",
  "Temperature",
  "Salinity",
  "Current velocity",
  "Dissolved oxygen",
  "Chlorophyll",
  "Slope",
  "Seafloor roughness"
)

rownames(cor_all) <- colnames(cor_all)

plot <- corrplot(
  cor_all,
  method = "circle",
  col = colorRampPalette(
    c("#BCE7E1", "white", "#8db9e2")
  )(200),
  type = "upper",
  order = "hclust",
  tl.col = "black",
  tl.cex = 1.1,
  tl.srt = 45,
  addCoef.col = "black",
  number.cex = 0.6,
  diag = FALSE
)

plot


# VIF

lm_full_all <- lm(
  mean_expected_prob ~
    bathy200_sed +
    mud +
    sand +
    gravel +
    rock +
    temp_mean +
    salt_mean +
    spd_mean +
    Dissolved.oxygen.Mean +
    Chlorophyll.Mean +
    qslope9 +
    wbtgm_i2o8f1,
  data = mean_prob_all
)

vif_values <- vif(lm_full_all)

sort(vif_values, decreasing = TRUE)


# temp_mean Dissolved.oxygen.Mean                   mud                gravel      Chlorophyll.Mean                  sand 
# 9.487076              8.831468              4.751870              3.645434              3.583128              3.283035 
# rock             salt_mean          bathy200_sed               qslope9          wbtgm_i2o8f1              spd_mean 
# 2.548505              2.301888              2.160184              1.665666              1.421776              1.384028 



# ============================================================
# 7. MODELS WITH STANDARDIZED VARIABLES
# ============================================================

mean_prob_all_mod <- mean_prob_all %>%
  rename(
    Bathymetry = bathy200_sed,
    Mud = mud,
    Sand = sand,
    Gravel = gravel,
    Rock = rock,
    Temperature = temp_mean,
    Salinity = salt_mean,
    Current_speed = spd_mean,
    Chlorophyll = Chlorophyll.Mean,
    Slope = qslope9,
    Seafloor_roughness = wbtgm_i2o8f1
  )

vars_model <- c(
  "Bathymetry",
  "Mud",
  "Sand",
  "Gravel",
  "Rock",
  "Temperature",
  "Salinity",
  "Current_speed",
  "Chlorophyll",
  "Slope",
  "Seafloor_roughness"
)


# Standardize predictors
mean_prob_all_std <- mean_prob_all_mod %>%
  mutate(
    across(
      all_of(vars_model),
      ~ as.numeric(scale(.x))
    )
  )

formula_local_std <- mean_expected_prob ~
  Bathymetry +
  Mud +
  Sand +
  Gravel +
  Rock +
  Temperature +
  Salinity +
  Current_speed +
  Chlorophyll +
  Slope +
  Seafloor_roughness

# Combined model to check VIF
lm_all_std <- lm(
  formula_local_std,
  data = mean_prob_all_std
)

car::vif(lm_all_std)

# Models by scale
lm_5m_std <- lm(formula_local_std,
                data = filter(mean_prob_all_std, scale == "5m"))

lm_40m_std <- lm(formula_local_std,
                 data = filter(mean_prob_all_std, scale == "40m"))

lm_400m_std <- lm(formula_local_std,
                  data = filter(mean_prob_all_std, scale == "400m"))

summary(lm_5m_std)
summary(lm_40m_std)
summary(lm_400m_std)



# ============================================================
# 8. Model summary table
# ============================================================

model_summary <- data.frame(
  scale = c("5 m", "40 m", "400 m"),
  n_communities = c(
    nrow(filter(mean_prob_all_std, scale == "5m")),
    nrow(filter(mean_prob_all_std, scale == "40m")),
    nrow(filter(mean_prob_all_std, scale == "400m"))
  ),
  R2 = c(
    summary(lm_5m_std)$r.squared,
    summary(lm_40m_std)$r.squared,
    summary(lm_400m_std)$r.squared
  ),
  adj_R2 = c(
    summary(lm_5m_std)$adj.r.squared,
    summary(lm_40m_std)$adj.r.squared,
    summary(lm_400m_std)$adj.r.squared
  )
)

model_summary
write.csv(model_summary,
          file.path(output_dir, "model_summary_local_environment_scaled.csv"),
          row.names = FALSE)



# ============================================================
# 9. Main Ecography-style figure: standardized coefficients
# ============================================================
# ============================================================
# Extract coefficients from the 3 models
# ============================================================

coef_df <- bind_rows(
  broom::tidy(lm_5m_std, conf.int = TRUE) %>%
    mutate(scale = "5 m"),
  
  broom::tidy(lm_40m_std, conf.int = TRUE) %>%
    mutate(scale = "40 m"),
  
  broom::tidy(lm_400m_std, conf.int = TRUE) %>%
    mutate(scale = "400 m")
) %>%
  filter(term != "(Intercept)")

# ============================================================
# Rename variables
# ============================================================

coef_df$term <- factor(
  coef_df$term,
  levels = c(
    "Bathymetry",
    "Mud",
    "Sand",
    "Gravel",
    "Rock",
    "Temperature",
    "Salinity",
    "Current_speed",
    "Chlorophyll",
    "Slope",
    "Seafloor_roughness"
  ),
  labels = c(
    "Bathymetry",
    "Mud",
    "Sand",
    "Gravel",
    "Rock",
    "Temperature",
    "Salinity",
    "Current speed",
    "Chlorophyll",
    "Slope",
    "Seafloor roughness"
  )
)

coef_df$scale <- factor(
  coef_df$scale,
  levels = c("5 m", "40 m", "400 m")
)

# ============================================================
# Colors for the article
# ============================================================

colors <- c(
  "5 m"   = "#80cdc1",
  "40 m"  = "#a6cee3",
  "400 m" = "#ba8bc9"
)

# ============================================================
# Ecography-style figure
# ============================================================

coef_plot <- ggplot(
  coef_df,
  aes(
    x = estimate,
    y = term,
    colour = scale
  )
) +
  
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    colour = "grey50",
    linewidth = 0.5
  ) +
  
  geom_errorbarh(
    aes(
      xmin = conf.low,
      xmax = conf.high
    ),
    position = position_dodge(width = 0.7),
    height = 0.2,
    linewidth = 0.7
  ) +
  
  geom_point(
    position = position_dodge(width = 0.7),
    size = 3
  ) +
  
  scale_colour_manual(values = colors) +
  
  labs(
    x = "Standardized coefficient",
    y = NULL,
    colour = "Scale"
  ) +
  
  theme_classic(base_size = 13) +
  
  theme(
    legend.position = "top",
    axis.text.y = element_text(size = 11),
    axis.text.x = element_text(size = 11),
    axis.title.x = element_text(size = 14, face = "bold"),
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 10)
  )

coef_plot



ggsave(
  file.path(figures_dir, "Environmental_effects_coefplot.pdf"),
  coef_plot,
  width = 8,
  height = 6
)

ggsave(
  file.path(figures_dir, "Environmental_effects_coefplot.png"),
  coef_plot,
  width = 8,
  height = 6,
  dpi = 600
)


summary(lm_5m_std)
summary(lm_40m_std)
summary(lm_400m_std)

# ============================================================
# 10. MODEL SELECTION (AIC)
# ============================================================

old_na_action <- getOption("na.action")
options(na.action = "na.fail")

#---------------------------------------------
# Scale 5 m ----------------------------------
#---------------------------------------------

data_5m_std <- mean_prob_all_std %>%
  filter(scale == "5m")

lm_5m_std <- lm(
  formula_local_std,
  data = data_5m_std
)

dd_5m <- dredge(lm_5m_std)

head(dd_5m)

subset(dd_5m, delta < 2)

sw(dd_5m)

#---------------------------------------------
# Scale 40 m ---------------------------------
#---------------------------------------------

data_40m_std <- mean_prob_all_std %>%
  filter(scale == "40m")

lm_40m_std <- lm(
  formula_local_std,
  data = data_40m_std
)

dd_40m <- dredge(lm_40m_std)

subset(dd_40m, delta < 2)
sw(dd_40m)

#---------------------------------------------
# Scale 400 m --------------------------------
#---------------------------------------------

data_400m_std <- mean_prob_all_std %>%
  filter(scale == "400m")

lm_400m_std <- lm(
  formula_local_std,
  data = data_400m_std
)

dd_400m <- dredge(lm_400m_std)

subset(dd_400m, delta < 2)
sw(dd_400m)

#---------------------------------------------
# Importance  --------------------------------
#---------------------------------------------
imp_5m <- sw(dd_5m)
imp_40m <- sw(dd_40m)
imp_400m <- sw(dd_400m)

imp_df <- data.frame(
  Variable = names(imp_5m),
  Importance_5m = as.numeric(imp_5m),
  Importance_40m = as.numeric(imp_40m[names(imp_5m)]),
  Importance_400m = as.numeric(imp_400m[names(imp_5m)])
)

imp_df






#--------------------------------


imp_5m <- sw(dd_5m)
imp_40m <- sw(dd_40m)
imp_400m <- sw(dd_400m)

all_vars <- unique(c(
  names(imp_5m),
  names(imp_40m),
  names(imp_400m)
))

imp_df <- data.frame(
  Variable = all_vars,
  `5 m` = as.numeric(imp_5m[all_vars]),
  `40 m` = as.numeric(imp_40m[all_vars]),
  `400 m` = as.numeric(imp_400m[all_vars])
)

imp_df[is.na(imp_df)] <- 0

imp_long <- imp_df %>%
  pivot_longer(
    cols = c(X5.m, X40.m, X400.m),
    names_to = "Scale",
    values_to = "Importance"
  ) %>%
  mutate(
    Scale = dplyr::recode(
      Scale,
      X5.m = "5 m",
      X40.m = "40 m",
      X400.m = "400 m"
    ),
    Scale = factor(Scale, levels = c("5 m", "40 m", "400 m")),
    Variable = gsub("_", " ", Variable)
  )

importance_plot <- ggplot(
  imp_long,
  aes(
    x = Scale,
    y = reorder(Variable, Importance),
    fill = Importance
  )
) +
  geom_tile(colour = "white") +
  scale_fill_gradient(
    low = "white",
    high = "#80cdc1",
    limits = c(0, 1)
  ) +
  labs(
    x = "Spatial scale",
    y = NULL,
    fill = "Relative\nimportance"
  ) +
  theme_minimal(base_size = 12)

importance_plot


# Restore the session option changed for MuMIn::dredge().
options(na.action = old_na_action)
