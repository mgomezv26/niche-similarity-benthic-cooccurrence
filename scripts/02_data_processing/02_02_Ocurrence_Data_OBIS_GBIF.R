
library(dplyr)
library(readxl)
library(here)

###===================================================================================================================================###
### LOAD DATA
###===================================================================================================================================### 

GBIF_data <- read.csv(
  here("data", "interim", "GBIF_data_sea_base_map_1950.csv")
)

OBIS_data <- read.csv(
  here("data", "interim", "OBIS_data_clean_dates_1950.csv")
)

###===================================================================================================================================###
### OCCURRENCE DATA INTEGRATION AND NORMALIZATION
###===================================================================================================================================###

nrow(GBIF_data) # 287181
#colnames(GBIF_data)

nrow(OBIS_data) # 267047
#colnames(OBIS_data)

gbif_data <- GBIF_data %>%
  select(ID = gbifID, latitude = decimalLatitude, longitude = decimalLongitude, species, scientificName = accepted_scientificName, year, date) %>%
  mutate(source = "GBIF")

obis_data <- OBIS_data %>%
  select(ID = id, latitude = decimalLatitude, longitude = decimalLongitude, species = scientificName, scientificName = scientificName, year, date) %>%
  mutate(source = "OBIS")

colnames(gbif_data)
colnames(obis_data)

rm(OBIS_data, GBIF_data)


#################################
### Check species

list_species <- read_excel("list_of_species_V0.xlsx", sheet = "species")

length(unique(gbif_data$species)) # 173 sp
length(unique(obis_data$species)) # 171 sp
length(unique(list_species$species)) # 175 sp

#gbif_species <- as.data.frame(sort(unique(gbif_data$species)))
#obis_species <- as.data.frame(sort(unique(obis_data$species)))

# species present in gbif_data but not present in obis_data
missing_species <- setdiff(gbif_data$species, obis_data$species)
missing_species

# Acesta excavata’ # many records were from MachineObservation and with the same coordinates but different year. the rest of basisOfRecordno had information for the date.
# ‘Clavularia borealis’ # only 1 record from 1978
# ‘Metacallophyllis spec’ # Actually it is ‘Metacallophyllis laciniata’, in gbif it is not well named. It is renamed below
# ‘Sagartia viduata’ # No dates for the 26 records in obis.

# Rename species in gbif_data
gbif_data$species[gbif_data$species == "Metacallophyllis spec"] <- "Metacallophyllis laciniata"

# species present in obis_data but not present in gbif_data
missing_species_2 <- setdiff(obis_data$species, gbif_data$species)
missing_species_2

# "Thuiaria obsoleta" # has been removed during cleaning


# Join accepted scientificName in obis_data
accepted_scientificName <- read.csv('02_EDA/01_GBIF/accepted_scientificName.csv')

obis_data <- obis_data %>%
  left_join(accepted_scientificName %>% rename(accepted_scientificName = scientificName), by = "species")

length(unique(obis_data$accepted_scientificName)) # 171

obis_data <- obis_data %>%
  select(ID, latitude, longitude, species, scientificName = accepted_scientificName, year, date, source)

#################################
### Join data and cleaning

combined_data <- rbind(gbif_data, obis_data)
length(unique(combined_data$species)) # 175
length(unique(combined_data$scientificName)) # 175
nrow(combined_data) # 554228

combined_data <- combined_data %>%
  distinct(species, latitude, longitude, .keep_all = TRUE)

nrow(combined_data) # 524981

# Alignment of the time period with the oceanographic varibales ------------------------

data <- read.csv("01_DATA/01_PROCESSED_DATA/combine_data_drop_duplicates.csv")
nrow(data) # 524981

data <- data %>% filter(year >= 2000)
data <- data %>% filter(year <= 2020)

nrow(data) # 320906

write.csv(
  occurrences_clean,
  here("data", "processed",
       "Data_Occurrence_period_2000_2020.csv"),
  row.names = FALSE
)