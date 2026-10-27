
library(tidyverse)
library(dplyr)
library(vegan)
library(janitor)
library(readxl)
library(ggplot2)

# ============================================================
# 1. DEFINE PATHS
# ============================================================

local = "__CONFIGURE_PATH_01__"
#local = "__CONFIGURE_PATH_02__"

data_dir_5m = paste0(local, "/data/5m")
data_dir_40m = paste0(local, "/data/40m")
data_dir_400m = paste0(local, "/data/400m")
list_global_species = paste0(local, "/species_hv_names_tax.xlsx")

setwd(local)

species_hv_names <- read_excel(list_global_species, 
    sheet = "species_hv_names")
head(species_hv_names)


# ============================================================
# 3. LOAD DATA
# ============================================================

dens_5m   <- read_csv(paste0(data_dir_5m, "/species_densities.csv"), locale = locale(decimal_mark = "."))
head(dens_5m)
#dens_5m$density_n100m2[4]
dens_40m  <- read_csv(paste0(data_dir_40m, "/species_densities.csv"), locale = locale(decimal_mark = "."))
head(dens_40m)
dens_400m <- read_csv(paste0(data_dir_400m, "/species_densities.csv"), locale = locale(decimal_mark = "."))
head(dens_400m)

species_hv_names <- read_excel(list_global_species, 
    sheet = "species_hv_names")
head(species_hv_names)
#each SampID = one sampling unit
#each row = one species present in that unit
#density_n100m2 = abundance/density

# ============================================================
# 4. INSPECT COLUMNS
# ============================================================

names(dens_5m)
names(dens_40m)
names(dens_400m)
names(species_hv_names)

glimpse(dens_5m)

# ============================================================
# 5. LIST OF SPECIES TO RETAIN
# ============================================================

species_keep <- species_hv_names %>%
  pull(species) %>%
  unique() %>%
  sort()
species_keep
# ============================================================
# 6. CHECK MATCHES WITH NORWAY
# ============================================================

intersect_5m <- intersect(unique(dens_5m$clean_taxonomy), species_keep)
intersect_40m <- intersect(unique(dens_40m$clean_taxonomy), species_keep)
intersect_400m <- intersect(unique(dens_400m$clean_taxonomy), species_keep)

length(intersect_5m) # 110
length(intersect_40m) # 109
length(intersect_400m) # 99

sort(intersect_5m)
sort(intersect_40m)
sort(intersect_400m)

#sort(unique(dens_5m$clean_taxonomy))[1:50]
#sort(unique(dens_400m$clean_taxonomy))[1:50]


# ============================================================
# 7. FUNCTION TO CREATE A PRESENCE-ABSENCE MATRIX
# ============================================================

create_pa_matrix <- function(dens_df, species_keep) {
  
  pa_df <- dens_df %>%
    filter(clean_taxonomy %in% species_keep) %>%
    mutate(presence = 1) %>%
    distinct(SampID, clean_taxonomy, presence) %>%
    pivot_wider(
      names_from = clean_taxonomy,
      values_from = presence,
      values_fill = 0
    ) %>%
    arrange(SampID)
  
  pa_mat <- pa_df %>%
    column_to_rownames("SampID") %>%
    as.matrix()
  
  return(pa_mat)
}

# ============================================================
# 8. PRESENCE-ABSENCE MATRICES BY SCALE
# ============================================================

# Calculate the base presence-absence matrix. Rows are SampID and columns are species
# This is the presence-absence matrix, not the co-occurrence matrix. The co-occurrence matrix is calculated from this presence-absence matrix
#Used to:
# - describe communities
# - calculate distances
# - calculate co-occurrence


pa_5m   <- create_pa_matrix(dens_5m, species_keep)
pa_40m  <- create_pa_matrix(dens_40m, species_keep)
pa_400m <- create_pa_matrix(dens_400m, species_keep)

dim(pa_5m)
dim(pa_40m)
dim(pa_400m)

# ============================================================
# 9. EXAMINE LOCAL SPECIES OCCUPANCY
# ============================================================

# Occupancy = number of samples occupied by each species
# number of SampID in which a species occurs
occ_5m <- colSums(pa_5m)
occ_40m <- colSums(pa_40m)
occ_400m <- colSums(pa_400m)

summary(occ_5m)
summary(occ_40m)
summary(occ_400m)

#> summary(occ_5m)
#    Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
#    1.00    18.25   179.50  1091.38  1085.25 14051.00 


# Interpretation:
# - some species occur in only 1 sample: rare species
# - the typical species occurs in ~180 samples
# - some extremely common species occur in >14000 samples

# ============================================================
# 10. FILTER VERY RARE SPECIES
# ============================================================

min_occ <- 5

pa_5m_filt <- pa_5m[, colSums(pa_5m) >= min_occ, drop = FALSE]
pa_40m_filt <- pa_40m[, colSums(pa_40m) >= min_occ, drop = FALSE]
pa_400m_filt <- pa_400m[, colSums(pa_400m) >= min_occ, drop = FALSE]

dim(pa_5m_filt) # 95 sp
dim(pa_40m_filt) # 96 sp
dim(pa_400m_filt) # 77 sp

# ============================================================
# 11. JACCARD DISTANCE MATRICES BETWEEN SPECIES
# ============================================================
# vegdist directly returns: 1-Jaccard, i.e., 
#the Jaccard distance between each pair of species. 
#Jaccard distance is a measure of dissimilarity ranging from 0 to 1, 
#where 0 indicates that the species have identical distributions (co-occur in all samples) and 
#1 indicates that the species do not co-occur in any sample.

jaccard_5m <- vegdist(
  t(pa_5m_filt),
  method = "jaccard",
  binary = TRUE
)

jaccard_40m <- vegdist(
  t(pa_40m_filt),
  method = "jaccard",
  binary = TRUE
)

jaccard_400m <- vegdist(
  t(pa_400m_filt),
  method = "jaccard",
  binary = TRUE
)

jaccard_5m_mat <- as.matrix(jaccard_5m)
jaccard_40m_mat <- as.matrix(jaccard_40m)
jaccard_400m_mat <- as.matrix(jaccard_400m)

# 0 = very similar distributions
# 1 = very different distributions

head(jaccard_5m_mat)


# ============================================================
# 12. DESCRIPTIVE CO-OCCURRENCE MATRICES
# number of SampID shared by each pair of species
# ============================================================

shared_5m <- t(pa_5m_filt) %*% pa_5m_filt
shared_40m <- t(pa_40m_filt) %*% pa_40m_filt
shared_400m <- t(pa_400m_filt) %*% pa_400m_filt

shared_5m[1:5, 1:5]
shared_40m[1:5, 1:5]
shared_400m[1:5, 1:5]

# ============================================================
# 13. SAVE RESULTS
# ============================================================

save_path <- paste0(local, "/01_outputs/cooccurrence_matrices")
dir.create(save_path, recursive = TRUE, showWarnings = FALSE)

write.csv(pa_5m_filt,   paste0(save_path, "/presence_absence_5m.csv"))
write.csv(pa_40m_filt,  paste0(save_path, "/presence_absence_40m.csv"))
write.csv(pa_400m_filt, paste0(save_path, "/presence_absence_400m.csv"))

write.csv(jaccard_5m_mat,   paste0(save_path, "/jaccard_distance_5m.csv"))
write.csv(jaccard_40m_mat,  paste0(save_path, "/jaccard_distance_40m.csv"))
write.csv(jaccard_400m_mat, paste0(save_path, "/jaccard_distance_400m.csv"))
  
write.csv(shared_5m,   paste0(save_path, "/shared_samples_5m.csv"))
write.csv(shared_40m,  paste0(save_path, "/shared_samples_40m.csv"))
write.csv(shared_400m, paste0(save_path, "/shared_samples_400m.csv"))


dim(pa_5m_filt)
dim(pa_40m_filt)
dim(pa_400m_filt)

summary(colSums(pa_5m_filt))
summary(colSums(pa_40m_filt))
summary(colSums(pa_400m_filt))

summary(jaccard_5m_mat[upper.tri(jaccard_5m_mat)])
summary(jaccard_40m_mat[upper.tri(jaccard_40m_mat)])
summary(jaccard_400m_mat[upper.tri(jaccard_400m_mat)])

mean(jaccard_5m_mat[upper.tri(jaccard_5m_mat)] == 1)
mean(jaccard_40m_mat[upper.tri(jaccard_40m_mat)] == 1)
mean(jaccard_400m_mat[upper.tri(jaccard_400m_mat)] == 1)



jaccard_df_scales <- bind_rows(
  data.frame(scale = "5 m", value = jaccard_5m_mat[upper.tri(jaccard_5m_mat)]),
  data.frame(scale = "40 m", value = jaccard_40m_mat[upper.tri(jaccard_40m_mat)]),
  data.frame(scale = "400 m", value = jaccard_400m_mat[upper.tri(jaccard_400m_mat)])
)

ggplot(jaccard_df_scales, aes(x = value, fill = scale)) +
  geom_histogram(
    bins = 50,
    alpha = 0.5,
    position = "identity"
  ) +
  
  theme_classic() +
  
  labs(
    x = "Jaccard distance among species",
    y = "Frequency"
  )


ggplot(jaccard_df_scales, aes(x = value, color = scale)) +
  
  stat_ecdf(size = 1.2) +
  
  theme_classic() +
  
  labs(
    x = "Jaccard distance",
    y = "Cumulative proportion"
  )



# Distribution of Jaccard distances by scale
# prefer boxplot + jitter

jaccard_df_scales <- bind_rows(
  data.frame(scale = "5 m", value = jaccard_5m_mat[upper.tri(jaccard_5m_mat)]),
  data.frame(scale = "40 m", value = jaccard_40m_mat[upper.tri(jaccard_40m_mat)]),
  data.frame(scale = "400 m", value = jaccard_400m_mat[upper.tri(jaccard_400m_mat)])
)

ggplot(jaccard_df_scales,
       aes(x = scale, y = value, fill = scale)) +
  
  geom_boxplot(outlier.shape = NA, alpha = 0.7) +
  
  geom_jitter(
    width = 0.15,
    alpha = 0.03,
    size = 0.8
  ) +
  
  theme_classic() +
  
  labs(
    x = "Spatial scale",
    y = "Jaccard distance among species"
  )





head(jaccard_df_scales)

jaccard_df_scales$scale <- factor(
  jaccard_df_scales$scale,
  levels = c("5 m", "40 m", "400 m")
)

colors <- c(
  "5 m"   = "#80cdc1",
  "40 m"  = "#a6cee3",
  "400 m" = "#ba8bc9ff"
)

# ============================================================
# PROPORTION OF PAIRS WITH JACCARD = 1
# ============================================================

jaccard_summary <- jaccard_df_scales %>%
  group_by(scale) %>%
  summarise(
    n_pairs = n(),
    prop_jaccard_1 = mean(value == 1),
    perc_jaccard_1 = round(prop_jaccard_1 * 100, 1),
    median = median(value),
    q1 = quantile(value, 0.25),
    q3 = quantile(value, 0.75)
  )

jaccard_summary

perc_5m <- jaccard_summary$perc_jaccard_1[jaccard_summary$scale == "5 m"]
perc_40m <- jaccard_summary$perc_jaccard_1[jaccard_summary$scale == "40 m"]
perc_400m <- jaccard_summary$perc_jaccard_1[jaccard_summary$scale == "400 m"]

caption_text <- paste0(
  "Distribution of pairwise Jaccard distances among benthic species ",
  "across local spatial scales. ",
  "The proportion of species pairs with complete spatial segregation ",
  "(Jaccard distance = 1) decreased with increasing spatial scale ",
  "(5 m: ", perc_5m, "%; ",
  "40 m: ", perc_40m, "%; ",
  "400 m: ", perc_400m, "%)."
)

caption_text

# ============================================================
  # BOXPLOTS
# ============================================================

boxplot <- ggplot(jaccard_df_scales, aes(x = scale, y = value, fill = scale)) +
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
  scale_fill_manual(values = colors) +
  coord_cartesian(ylim = c(0.975, 1.0005)) +
  labs(
    y = "Jaccard distance among species",
    x = "Spatial scale"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none",
    axis.title.y = element_text(size = 14),
    axis.text = element_text(size = 12),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank()
  )

boxplot
ggsave("boxplot_local_scale_0975.png", plot = boxplot, width = 14, height = 10, units = "in", dpi = 600)



boxplot <- ggplot(jaccard_df_scales, aes(x = scale, y = value, fill = scale)) +
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
  scale_fill_manual(values = colors) +
  coord_cartesian(ylim = c(0.94, 1.0005)) +
  labs(
    y = "Jaccard distance among species",
    x = "Spatial scale"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none",
    axis.title.y = element_text(size = 14),
    axis.text = element_text(size = 12),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank()
  )

boxplot

ggsave("boxplot_local_scale_094.png", plot = boxplot, width = 14, height = 10, units = "in", dpi = 600)




