
### ===================================================================================================================== ###
###                             COPERNICUS MARINE SERVICE
### ===================================================================================================================== ###


"In order to obtain representative long-term values, chlorophyll mean values were calculated using QGIS for three periods: 2000-2010, 2010-2020 and 2000-2020. 
Finally, using the QGIS ‘Sample raster values’ tool, the species presence records were associated with the rasters for the three periods. 
The number of records per species available in the chlorophyll data is analysed below."

library(dplyr)
library(tidyverse)
library(readxl)

### DEFINE THE WORKING DIRECTORY ----------------------------------------------------------------------------

local = "__CONFIGURE_PATH_01__"
setwd(local)

### LOAD DATA ----------------------------------------------------------------------------

data_30m <- read.csv("chl_records_species_2000_2020_30m_depth.csv")

nrow(data_30m) # 249214
colnames(data_30m)
ncol(data_30m) # 6
head(data_30m)

colSums(is.na(data_30m)) # There are 84588 records without chl values
249214 - 84588 # 164626

data_05m <- read.csv("chl_records_species_2000_2020_1_depth.csv")
nrow(data_05m) # 275113
ncol(data_05m) # 5
head(data_05m)

colSums(is.na(data_05m)) # There are 43883 records without chl values
275113 - 43883 # 231230

nrow(data_30m) # 249214

data_30m <- data_30m %>%
  select("ID", "latitude", "longitude", "species", "chl1")
head(data_30m)

length(unique(data_30m$species)) # 162 sp

### EDA DATA ----------------------------------------------------------------------------

records_per_species_30m <-data_30m %>%
  group_by(species) %>%
  summarise(count = sum(!is.na(ID) & !is.na(latitude) & !is.na(longitude) & !is.na(chl1))) %>%
  arrange(count)


records_per_species_05m <-data_05m %>%
  group_by(species) %>%
  summarise(count = sum(!is.na(ID) & !is.na(latitude) & !is.na(longitude) & !is.na(chl_1))) %>%
  arrange(count)

unique(records_per_species_30m$species)

missing_species <- setdiff(records_per_species_30m$species, records_per_species_05m$species) 
missing_species 

missing_species_2 <- setdiff(records_per_species_05m$species, records_per_species_30m$species)
missing_species_2















###===================================================================================================================================###
### CORRELATION BETWEEN THE ENVIROMENTAL VARIABLES
###===================================================================================================================================###

data_env <- read.csv(paste0(save_path,"/records_env_no_na.csv"))
colnames(data_env)

data_env  <- data_env[6:41]
str(data_env)

## 1. Manual correlation of variables --------------------------------------------------------------------------------------------------

# Calculate the correlation between the variables
Correlation <- cor(data_env, use = "pairwise.complete.obs", method = "pearson")

# Export csv
write.table(Correlation, paste0(save_path, "/Correlation_env.csv"), sep = ",", row.names = TRUE, col.names = TRUE)

# Plot
Correlation.dist <- as.dist(1 - abs(Correlation)) # Create a distance matrix (inverse of correlation)
Correlation.average <- hclust(Correlation.dist, method = "average") # Perform hierarchical clustering analysis

# Save the graphic as a JPEG file
jpeg(paste0(save_path, "/Correlation_env.jpg", width = 2800, height = 1000))
plot(Correlation.average)  # Dendrogram plot
dev.off()


Correlation_melted <- melt(Correlation)
colnames(Correlation_melted) <- c("Var1", "Var2", "Correlation")

# Creating the heat map with ggplot2
ggplot(Correlation_melted, aes(x = Var1, y = Var2, fill = Correlation)) +
  geom_tile() + 
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, 
                       name = "Correlación") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), 
        axis.text.y = element_text(angle = 45, hjust = 1)) +
  labs(title = "Heat Map of Correlations between Environmental Variables")

# Save the heat map as a PNG file
ggsave(paste0(save_path, "/Heatmap_Correlation_env.png", width = 10, height = 8, dpi = 300))

ggsave(paste0(save_path, "/Heatmap_Correlation_env.png"), 
       width = 10, height = 8, dpi = 300)


# -----------------------------------------------
# Correlation only with mean data

cols =  c("bathymetry_mean", "dfe_mean", "no3_mean", "o2_mean", "ph_mean", "phyc_mean", "po4_mean", "si_mean", "so_mean", "swd_mean", "sws_mean", "thetao_mean")

colnames(data_env)
data_env_mean <- data_env %>%
  select(all_of(cols))

# Calculate the correlation between the variables
Correlation <- cor(data_env_mean, use = "pairwise.complete.obs", method = "pearson")

# Export csv
write.table(Correlation, paste0(save_path, "/Correlation_env_mean.csv"), sep = ",", row.names = TRUE, col.names = TRUE)

# Plot
Correlation.dist <- as.dist(1 - abs(Correlation)) # Create a distance matrix (inverse of correlation)
Correlation.average <- hclust(Correlation.dist, method = "average") # Perform hierarchical clustering analysis

# Save the graphic as a JPEG file
jpeg(paste0(save_path, "/Correlation_env_mean.jpg", width = 2800, height = 1000))
plot(Correlation.average)  # Dendrogram plot
dev.off()


Correlation_melted <- melt(Correlation)
colnames(Correlation_melted) <- c("Var1", "Var2", "Correlation")

# Create the heat map with ggplot2
ggplot(Correlation_melted, aes(x = Var1, y = Var2, fill = Correlation)) +
  geom_tile() +  
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, 
                       name = "Correlación") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), 
        axis.text.y = element_text(angle = 45, hjust = 1)) +
  labs(title = "Heat Map of Correlations between Environmental Variables")

# Save the heat map as a PNG file
ggsave(paste0(save_path, "/Heatmap_Correlation_env_mean.png"), 
       width = 10, height = 8, dpi = 300)















# -----------------------------------------------------

# Plot GGally

ggpairs(df_sample, 
        columns = 5:15, 
        aes(alpha = 0.5),
        upper = list(continuous = wrap("cor", size = 2.5))) 

pairs(df_sample_cor)
