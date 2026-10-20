### LOAD LIBRARIES 
library(dplyr)
library(hypervolume)
library(tidyverse)


###===================================================================================================================================###
### DEFINE THE WORKING DIRECTORY
###===================================================================================================================================###

local = "__CONFIGURE_PATH_01__"
hv_dir=paste0(local,"/03_Hypervolumes")
save_path=paste0(hv_dir,"/06_Hipervolume_results")
setwd(local)

###===================================================================================================================================###
### LOAD HYPERVOLUMES
###===================================================================================================================================###

load(paste0(hv_dir,"/hv_list_all_species.RData"))
class(hv_list_Species)

#saw the 1st hv of the list
hv_list_Species[[1]]
hv_list_Species[[1]]

###===================================================================================================================================###
### CALCULATE INDIVIDUAL VOLUMES
###===================================================================================================================================###

# get individual volumes
invidual_volumes_df <- data.frame(volume = round(get_volume(hv_list_Species), 4),
                        species = sapply(hv_list_Species@HVList, function(x) x@Name))

head(invidual_volumes_df)
# save results
write.csv(invidual_volumes_df, paste0(save_path,"/individual_volumes_all_species.csv"), row.names = FALSE)

###===================================================================================================================================###
### CALCULATE PAIRWISE OVERLAP BETWEEN HYPERVOLUMES
###===================================================================================================================================###

species_names <- sapply(hv_list_Species@HVList, function(x) x@Name)
n_species <- length(species_names)
n_species
class(species_names)
species_hv_df <- data.frame(species = species_names, hv_index = 1:n_species)
write.csv(species_hv_df, paste0(save_path,"/species_hv_names.csv"), row.names = FALSE)

results <- data.frame(
    sp1 = character(),
    sp2 = character(),
    jaccard = numeric(), # Jaccard similarity index
    sorensen = numeric(), # Sorensen similarity index
    frac_unique_1 = numeric(), # fraction of unique volume of species 1
    frac_unique_2 = numeric(), # fraction of unique volume of species 2
    intersection_volume = numeric(), # Volume of the intersection
    union_volume = numeric(), # total volume of the union of both hypervolumes
    distance = numeric(), # Euclidean distance between centroids
    stringsAsFactors = FALSE
)

for (i in 1:(length(hv_list_Species@HVList) - 1)) {  # Ajustar el rango del primer bucle
    for (j in (i + 1):length(hv_list_Species@HVList)) {
        # Imprimir los índices para depuración
        cat("i:", i, "j:", j, "\n")

        # The hypervolumes of the species pairs to go in hypervolume_set
        hv1 <- hv_list_Species[[i]]
        hv2 <- hv_list_Species[[j]]

        # Extract names from hypervolumes using indexes
        name_hv1 <- species_names[[i]]
        name_hv2 <- species_names[[j]]

        # Print species  pairs
        print(paste("Par de especies:", name_hv1, "y", name_hv2))

        # aplicar la funcion hypervolume_set
        hv_set = hypervolume_set(hv1, hv2, check.memory=FALSE)
        # Calculate pairwise overlap
        overlap <- hypervolume_overlap_statistics(hv_set)
        # Calculate the euclidian distance with hypervolume_distance
        hv_distance <- hypervolume_distance(hv1,hv2, type = "centroid", num.points.max = 1000, check.memory = TRUE)
        

        # Calculate metrics
        hv_set <- hypervolume_set(hv1, hv2, check.memory = FALSE) 
        overlap <- hypervolume_overlap_statistics(hv_set)
        hv_distance <- hypervolume_distance(hv1, hv2, type = "centroid", num.points.max = 1000) # euclidian distance with hypervolume_distance
        
        # Extract intersection and union volumes
        intersection_volume <- hv_set@HVList$Intersection@Volume
        union_volume <- hv_set@HVList$Union@Volume


        # Add results to the dataframe
        results <- rbind(
            results,
            data.frame(
                sp1 = name_hv1,
                sp2 = name_hv2,
                jaccard = overlap["jaccard"],
                sorensen = overlap["sorensen"],
                frac_unique_1 = overlap["frac_unique_1"],
                frac_unique_2 = overlap["frac_unique_2"],
                intersection_volume = intersection_volume,
                union_volume = union_volume,
                distance = hv_distance
            )
        )
    }
}

head(results)
# Save results
write.csv(results, paste0(save_path,"/pairwise_hypervolume_overlap_all_species.csv"), row.names = FALSE)