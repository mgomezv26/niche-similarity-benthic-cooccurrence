### ===================================================================================================================== ###
###                          DATA PROCESSING OF BIO-ORACLE OCEANOGRAPHIC VARIABLES
### ===================================================================================================================== ###

"
The following oceanographic variables correspond to the mean depth of the benthic layer and are available in Bio-ORACLE. 
They have been downloaded for the current conditions. The selected periods are 2000–2010 and 2010–2020.

- Ocean temperature (thetao)
- Salinity (so)
- Sea water velocity (sws)
- Sea water direction (swd)
- Nitrate (no3)
- Phosphate (po4)
- Silicate (si)
- Dissolved molecular oxygen (02)
- Iron (dfe)
- Primary productivity (phyc)
- pH (ph)
- Bathymetry (bathymetry)
"

## 1. Load data and process it ---------------------------------------------------------------------------------------------

library(terra)

directory_2000 <- "01_DATA/BIO_ORACLE/01_original_rasters/2000_2010"
directory_2010 <- "01_DATA/BIO_ORACLE/01_original_rasters/2010_2020"

files_2000 <- list.files(directory_2000, pattern = "\\.nc$", full.names = TRUE)
files_2010 <- list.files(directory_2010, pattern = "\\.nc$", full.names = TRUE)

raster_stack_2000 <- rast(files_2000)
raster_stack_2010 <- rast(files_2010)

raster_stack_2000
raster_stack_2010

names(raster_stack_2000)
names(raster_stack_2010)

# Rearrange the raster layers in the same order
raster_stack_2000 <- raster_stack_2000[[order(names(raster_stack_2000))]]
raster_stack_2010 <- raster_stack_2010[[order(names(raster_stack_2010))]]

# Calculate the average between the two decades
raster_stack_mean <- (raster_stack_2000 + raster_stack_2010) / 2
names(raster_stack_mean)
print(raster_stack_mean)

crs(raster_stack_mean)
crs(raster_stack_mean, describe = TRUE)
crs(raster_stack_mean) <- "EPSG:4326"

# Export file
writeRaster(raster_stack_mean, "01_DATA/BIO_ORACLE/raster_stack_biooracle_2000_2020.tif", overwrite = TRUE)


## 2. Plot the data --------------------------------------------------------------------------------------------------------

library(tmap)
plot(raster_stack_mean, main = "oceanographic variables 2000-2020")
plot(raster_stack_mean, main = names(raster_stack_mean), nc = 3)

for (i in 1:nlyr(raster_stack_mean)) {
  plot(raster_stack_mean[[i]], main = names(raster_stack_mean)[i])
}

library(tmap)
tmap_mode("plot")
tm_shape(raster_stack_mean) + tm_raster()


## 3. Gif the data  ---------------------------------------------------------------------------------------------

library(raster)
library(tmap)
library(animation)

# output file
output_gif <- "oceanographic_variables_2000_2020.gif"

# Create a gif
saveGIF({
  for (i in 1:nlyr(raster_stack_mean)) {
    # Toma la capa individual
    current_layer <- raster_stack_mean[[i]]
    
    # Create the map for that layer
    p <- tm_shape(current_layer) + 
      tm_raster(palette = "viridis", style = "cont", title = names(raster_stack_mean)[i]) +
      tm_layout(main.title = names(raster_stack_mean)[i])  # Título dinámico
    
    # show gif
    print(p)
  }
}, movie.name = output_gif, interval = 0.5, width = 1200, height = 800)



### ===================================================================================================================== ###
###                             Seafloor sediments in the world's ocean [dataset]
### ===================================================================================================================== ###

"
Dutkiewicz, A., Müller, R. D., O’Callaghan, S., & Jónasson, H. (2015). Census of seafloor sediments in the world’s ocean. Geology, 43(9), 795-798. https://doi.org/10.1130/G36883.1
https://doi.pangaea.de/10.1594/PANGAEA.932412?utm_source=chatgpt.com
"

library(terra)

## 1. Load data and process it ---------------------------------------------------------------------------------------------

r <- rast("01_DATA/Seafloor_sediments/seabed_lithology_v1.nc")
print(r)
names(r)

writeRaster(r, "01_DATA/Seafloor_sediments/seafloor_lithology_dummy.tif", overwrite = TRUE)

# Extract unique values from the raster
unique_values <- sort(unique(values(r)), na.last = TRUE)
unique_values <- unique_values[!is.na(unique_values)]  # Elimina NA
print(unique_values)

# Definition of lithologies according to data from (Dutkiewicz et al., 2015).
litology_classes <- c("Gravel and coarser", "Sand", "Silt", "Clay", "Calcareous ooze", 
                      "Radiolarian ooze", "Diatom ooze", "Sponge spicules", 
                      "Mixed calcareous/siliceous ooze", "Shells and coral fragments", 
                      "Ash and volcanic sand/gravel", "Siliceous mud", "Fine-grained calcareous sediment")

r_sediments <- r

# Verification of the number of values matches the number of classes
if(length(unique_values) == length(litology_classes)) {
  # Assign lithology names to the unique values of the raster
  values(r_sediments) <- factor(values(r_sediments), levels = unique_values, labels = litology_classes)
} else {
  warning("El número de valores únicos no coincide con el número de litologías definidas.")
}


## 2. Plot data ---------------------------------------------------------------------------------------------

# Export map in a svg file
svg("01_DATA/Seafloor_sediments/seafloor_lithology_plot.svg", width = 10, height = 8)

# Define colors
colors <- c("#6b6a6a", "yellow", "#dbac15", "#744724f5", "#80cbe3", "#046804", "#a2de83", "#3f7578", 
            "#7b2a80", "#E89ECE", "#d30909", "#dba15a", "#0931c3")
# plot map
plot(r_sediments, col = colors, main = "Seafloor Lithology")
dev.off()

# Export raster
writeRaster(r_sediments, "01_DATA/Seafloor_sediments/seafloor_lithology.tif", overwrite = TRUE)
