
library(robis)
library(dplyr)
library(readxl)
library(sf)

###===================================================================================================================================###
### DOWNLOAD OBIS DATA
###===================================================================================================================================###


list_species <- read_excel("list_of_species_V0.xlsx", sheet = "species")
list = list_species$species

data_obis = data.frame()

for (species_name in list){
  species_data <- occurrence(species_name)
  
  # Verify if both have the same columns
  if (ncol(data_obis) != ncol(species_data)) {
    # Add missing columns in data_obis with NA values
    missing_cols <- setdiff(names(species_data), names(data_obis))
    data_obis[missing_cols] <- NA
    # Add missing columns in species_data with NA values
    missing_cols <- setdiff(names(data_obis), names(species_data))
    species_data[missing_cols] <- NA
  }
  
  data_obis <- rbind(data_obis, species_data) 
}

nrow(data_obis) # 1115692


###===================================================================================================================================###
### CHECK SPECIES
###===================================================================================================================================###

# data_obis <- read.csv("01_DATA/02_OBIS/obis_species_data_original.csv")
length(unique(data_obis$scientificName)) # 193

# species present in list_species but not present in the data downloaded from obis (data_obis)
missing_species <- setdiff(list_species$species, data_obis$scientificName)
missing_species

# ‘Antho dichotoma’ -- Synonym “Antho (Antho) dichotoma” has been downloaded.
# ‘Asbestopluma furcata’ -- Synonym ‘Asbestopluma (Asbestopluma) furcata’ has been downloaded.
# ‘Asbestopluma pennatula’ -- Synonym ‘Asbestopluma (Asbestopluma) pennatula’ has been downloaded.
# ‘Caryophyllia smithii’ -- Synonym ‘Caryophyllia (Caryophyllia) smithii’ has been downloaded.
# ‘Caulophacus arcticus’ -- Synonym ‘Caulophacus (Caulophacus) arcticus’ has been downloaded.
# ‘Chondrocladia grandis’ -- Synonym ‘Chondrocladia (Chondrocladia) grandis’ has been downloaded.
# ‘Hamacantha bowerbanki’ -- Synonym ‘Hamacantha (Vomerula) bowerbanki’ has been downloaded.
# ‘Hymedesmia paupertas’ -- Synonym ‘Hymedesmia (Hymedesmia) paupertas’ has been downloaded.
# ‘Leptasterias muelleri’ -- Synonyms ‘Leptasterias (Leptasterias) muelleri’ and ‘Leptasterias (Leptasterias) muelleri muelleri muelleri’ have been downloaded.
# ‘Lissodendoryx complicata’ -- Synonym ‘Lissodendoryx (Lissodendoryx) complicata’ has been downloaded.
# ‘Mycale lingua’ -- Synonym ‘Mycale (Mycale) lingua’ has been downloaded.
# ‘Porania pulvillus’ -- NOT DOWNLOADED ANYTHING BUT ON THEIR WEBSITE THERE ARE RECORDS https://obis.org/taxon/125166 in WoRMS Porania (Porania) pulvillus (O.F. Müller, 1776)
# Poraniomorpha tumida’ -- NOT DOWNLOADED ANYTHING BUT ON THEIR WEBSITE THERE ARE RECORDS in WoRMS Poraniomorpha (Poraniomorpha) tumida (Stuxberg, 1878)
# Zostera marina’ -- Downloaded synonym “Zostera subg. Zostera marina”.

# download data for Porania (Porania) pulvillus
Porania_pulvillus_data <- occurrence("Porania (Porania) pulvillus")
# write.csv(Porania_pulvillus_data, "01_DATA/02_OBIS/Porania_pulvillus_data.csv", row.names = FALSE)

# download data for Poraniomorpha (Poraniomorpha) tumida
Poraniomorpha_tumida_data <- occurrence("Poraniomorpha (Poraniomorpha) tumida")
# write.csv(Porania_pulvillus_data, "01_DATA/02_OBIS/Porania_pulvillus_data.csv", row.names = FALSE)

# Verify if both have the same columns and add missing columns with NA in each data
missing_cols <- setdiff(names(data_obis), names(Poraniomorpha_tumida_data))
Poraniomorpha_tumida_data[missing_cols] <- NA
missing_cols <- setdiff(names(data_obis), names(Porania_pulvillus_data))
Porania_pulvillus_data[missing_cols] <- NA

# combine with data_obis
data_obis <- rbind(data_obis, Porania_pulvillus_data, Poraniomorpha_tumida_data)
nrow(data_obis) # 1122738

missing_species <- setdiff(list_species$species, data_obis$scientificName)
missing_species # all the listed species are present now in data_obis

# There are now records for the two species that were missing from the original listing.
# Porania pulvillus’ -- “Porania (Porania) pulvillus”, “Porania (Porania) pulvillus”, “Porania (Porania) pulvillus pulvillus pulvillus” have been downloaded.
# Poraniomorpha tumida’ -- “Poraniomorpha (Poraniomorpha) tumida” has been downloaded.

# species present in data downloaded from obis but not present in list_species
missing_species_2 <- setdiff(data_obis$scientificName, list_species$species)
missing_species_2 # There are 36 species absent in list_species. See excel "02_EDA/02_OBIS/sp_miss_in_list_species.xlsx" for revision
write.csv(missing_species_2, '02_EDA/02_OBIS/sp_miss_in_list_species.csv',row.names=FALSE)

#############################################
# Species to be removed or modified after excel revision "sp_miss_in_list_species.xlsx"

# "Craniella cranium f. microspira" Name not accepted. This form no longer belongs to the species “Craniella cranium (Müller, 1776)”. 
# It becomes the species --> Craniella microspira Van Soest, 2024
# Modification to be made: Removed Craniella cranium f. microspira

data_obis <- data_obis %>% filter(scientificName != "Craniella cranium f. microspira")
nrow(data_obis) # 1122730


name_changes <- read_excel("list_of_species_V0.xlsx", sheet = "OBIS_STANDARD")
head(name_changes)
name_map <- setNames(name_changes$standard_name, name_changes$original_name)
# Reemplazar nombres en la columna `scientificName`
data_obis <- data_obis %>%
  mutate(scientificName = recode(scientificName, !!!name_map))

length(unique(data$scientificName)) # 175

rm(list, Porania_pulvillus_data, Poraniomorpha_tumida_data, species_name, missing_cols, missing_species, missing_species_2)

###===================================================================================================================================###
### PREVIOUS MODIFICATIONS AND EDA
###===================================================================================================================================###

colnames(data_obis)
nrow(data_obis) # 1122730

fields <- c('id', 'occurrenceID', 'phylum', 'class', 'order', 'family', 'genus', 'species',
            'taxonRank', 'scientificName', 'scientificNameAuthorship', 'aphiaID', 'originalScientificName',
            'country', 'locality', 'stateProvince',
            'decimalLatitude', 'decimalLongitude',
            'year', 'month', 'day', 'eventDate', 'date_year',
            'depth', 'verbatimDepth', 'bathymetry', 'waterBody', 'sss', 'sst',
            'occurrenceStatus', 'basisOfRecord', 'recordedBy', 'institutionCode',
            'georeferenceVerificationStatus','coordinatePrecision')

data <- data_obis %>% select(all_of(fields))

colSums(is.na(data))

################################
## basisOfRecord

unique(data$basisOfRecord) # type of occurrences
table(data$basisOfRecord) # Number of records for each basisOfRecord

# Number of records for each type of basisOfRecord
#                 120.5                  121.5               121.6833 
#                     1                      2                      1 
#                121.75                    122                  122.5
#                     1                      5                      2
#                   123                      D      Human observation
#                     2                      2                  26518
#      humanobservation       HumanObservation         LivingSpecimen
#                   429                 273854                     10
#    machineobservation     MachineObservation        MATERIAL_SAMPLE
#                     3                  63738                    226
#        MaterialSample NomenclaturalChecklist             Occurrence
#                 43672                     45                 696792
#     Preservedspecimen      PreservedSpecimen                      S
#                  1716                  15570                    141

# Select occurences with this type of basisOfRecord 
data <- data %>% 
  filter(basisOfRecord %in% c('Occurrence','HumanObservation', 'Human observation','MATERIAL_SAMPLE', 'MaterialSample', 'humanobservation'))

nrow(data) # 1041491

################################
## taxonRank

unique(data$taxonRank)
table(data$taxonRank)

#   Especie    species    Species    SPECIES Subspecies    Variety
#         1      66625      41782        130         13          3

sum(is.na(data$taxonRank)) # 932937

# No filters have been applied taking into account the taxonRank field because all records are at species, subspecies or variety level. 
# However, if detected, this field has many values (932,937), so they are ignored and kept as all records seem to be at species level.


###===================================================================================================================================### 
### GEOGRAPHIC
###===================================================================================================================================### 

library(CoordinateCleaner)
nrow(data) # 1041491

# 1. Check coordinates values: ----
flags <- clean_coordinates(x = data,
                           lon = "decimalLongitude",
                           lat = "decimalLatitude",
                           species = "species",
                           tests = c("validity", "equal",
                                     "zeros", "duplicates"))

# Testing coordinate validity
# Flagged 0 records.
# Testing equal lat/lon
# Flagged 24 records.
# Testing zero coordinates
# Flagged 51 records.
# Testing duplicates
# Flagged 478739 records.
# Flagged 478783 of 1041491 records, EQ = 0.46.

data <- clean_coordinates(x = data,
                          lon = "decimalLongitude",
                          lat = "decimalLatitude",
                          species = "species",
                          tests = c("validity", "equal",
                                    "zeros",
                                    "duplicates"),
                          value = "clean")

nrow(data) # 562708


# 2. Check coordinates precision: ----
## Function to count number of decimals:
decimal.num.count <- function(x) {
  stopifnot(class(x) == "character")
  x <- ifelse(grepl("\\.", x), sub(".*\\.(.*)", "\\1", x), "")
  nchar(x)
}

# Apply function to latitude and longitude fields
latDigits <- decimal.num.count(as.character(data$decimalLatitude))
data <- cbind(data, latDigits)
lonDigits <- decimal.num.count(as.character(data$decimalLongitude))
data <- cbind(data, lonDigits)

# Filter coordinates with 1 or more digit places
data <- data[latDigits > 0 & lonDigits > 0, ]
nrow(data) # 560377


# 3. Check coordinates values with rounded decimals: ----

data$LatRound<- round(data$decimalLatitude, 2)
data$LongRound <- round(data$decimalLongitude, 2)

flags <- clean_coordinates(x = data,
                           lon = "LongRound",
                           lat = "LatRound",
                           species = "species",
                           tests = c("validity", "equal", "duplicates"))

# Testing coordinate validity
# Flagged 0 records.
# Testing equal lat/lon
# Flagged 2 records.
# Testing duplicates
# Flagged 239876 records.
# Flagged 239878 of 560377 records, EQ = 0.43.

data <- clean_coordinates(x = data,
                          lon = "LongRound",
                          lat = "LatRound",
                          species = "species",
                          tests = c("validity", "equal", "duplicates"),
                          value = "clean")
nrow(data) # 320499


# 4. Check position of coordinates: ----

# # Are coordinates placed in correct habitat (sea / land)?
data <- read.csv('01_DATA/02_OBIS/data_clean_coordinates_round.csv')
data_sf <- st_as_sf(data, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326)

base_africa <- st_read("01_DATA/shapefiles/capas_basemap/base_africa.shp")
base_asia <- st_read("01_DATA/shapefiles/capas_basemap/base_asia.shp")
base_antarctic <- st_read("01_DATA/shapefiles/capas_basemap/base_antarctic.shp")
base_australian <- st_read("01_DATA/shapefiles/capas_basemap/base_australian.shp")
base_europe <- st_read("01_DATA/shapefiles/capas_basemap/base_europe.shp")
base_s_america <- st_read("01_DATA/shapefiles/capas_basemap/base_s_america.shp")
n_america <- st_read("01_DATA/shapefiles/capas_basemap/n_america.shp")
base_canada <- st_read("01_DATA/shapefiles/capas_basemap/base_canada.shp")

# Polygon validity test
sum(!st_is_valid(base_europe)) # Correct invalid geometries in basemap
base_europe <- st_make_valid(base_europe) # Correct invalid geometries in basemap

# st_intersects returns a logical array if we use sparse = FALSE
inter_matrix <- st_intersects(data_sf,base_africa, sparse = FALSE)
inter_matrix <- st_intersects(data_sf,base_asia, sparse = FALSE)
inter_matrix <- st_intersects(data_sf,base_antarctic, sparse = FALSE)
inter_matrix <- st_intersects(data_sf,base_australian, sparse = FALSE)
inter_matrix <- st_intersects(data_sf,base_europe, sparse = FALSE)
inter_matrix <- st_intersects(data_sf,base_s_america, sparse = FALSE)
inter_matrix <- st_intersects(data_sf,n_america, sparse = FALSE)
inter_matrix <- st_intersects(data_sf,base_canada, sparse = FALSE)

# Create a logical vector that is TRUE if the record intersects (at least one polygon).
land_flags <- apply(inter_matrix, 1, any)

records_land_africa <- data_sf[land_flags, ]
records_land_asia <- data_sf[land_flags, ]
records_land_antarctic <- data_sf[land_flags, ]
records_land_australian <- data_sf[land_flags, ]
records_land_europe <- data_sf[land_flags, ]
records_land_s_america <- data_sf[land_flags, ]
records_land_canada <- data_sf[land_flags, ]
records_land_n_america_c <- data_sf[land_flags, ]

write.csv(records_land_africa, '01_DATA/02_OBIS/records_sea_land/records_land_africa.csv')
write.csv(records_land_asia, '01_DATA/02_OBIS/records_sea_land/records_land_asia.csv')
write.csv(records_land_antarctic, '01_DATA/02_OBIS/records_sea_land/records_land_antarctic.csv')
write.csv(records_land_australian, '01_DATA/02_OBIS/records_sea_land/records_land_australian.csv')
write.csv(records_land_s_america, '01_DATA/02_OBIS/records_sea_land/records_s_america.csv')
write.csv(records_land_europe, '01_DATA/02_OBIS/records_sea_land/records_land_europe.csv')
write.csv(records_land_canada, '01_DATA/02_OBIS/records_sea_land/records_land_canada.csv')
write.csv(records_land_n_america_c, '01_DATA/02_OBIS/records_sea_land/records_land_n_america_c.csv')

records_land_africa <- read.csv('01_DATA/02_OBIS/records_sea_land/records_land_africa.csv')
records_land_asia <- read.csv('01_DATA/02_OBIS/records_sea_land/records_land_asia.csv')
records_land_antarctic <- read.csv('01_DATA/02_OBIS/records_sea_land/records_land_antarctic.csv')
records_land_australian <- read.csv('01_DATA/02_OBIS/records_sea_land/records_land_australian.csv')
records_land_s_america <- read.csv('01_DATA/02_OBIS/records_sea_land/records_s_america.csv')
records_land_europe <- read.csv('01_DATA/02_OBIS/records_sea_land/records_land_europe.csv')
records_land_canada <- read.csv('01_DATA/02_OBIS/records_sea_land/records_land_canada.csv')
records_land_n_america_c <- read.csv('01_DATA/02_OBIS/records_sea_land/records_land_n_america_c.csv')

# Combine all dataframes in one
data_land <- rbind(records_land_africa,
                   records_land_asia,
                   records_land_antarctic,
                   records_land_australian,
                   records_land_s_america,
                   records_land_canada,
                   records_land_n_america_c,
                   records_land_europe)

rm(records_land_africa, records_land_asia, records_land_antarctic, records_land_australian, 
   records_land_s_america, records_land_canada, records_land_n_america_c, records_land_europe)

colnames(data_land)
data_land <- data_land %>% select(X)
data_land <- dplyr::rename(data_land, 'id' = 'X')
write.csv(data_land, '01_DATA/02_OBIS/records_sea_land/data_land.csv')

# Ground records are deleted using the id field by the anti_join() function.
common_ids <- intersect(data$id, data_land$id)
length(common_ids) # 42238
data_sea <- anti_join(data, data_land, by = "id")
nrow(data_sea) # 278261


###===================================================================================================================================###
### TEMPORAL
###===================================================================================================================================### 

data <- read.csv('01_DATA/02_OBIS/data_sea_base_map.csv')

nrow(data) # 278261

str(data$year)  # Ver el tipo de dato

# sum(is.na(data$year)) # there are 29286 NA in year
# max(data$year, na.rm = TRUE) # 2024
# min(data$year, na.rm = TRUE) # 1776

# sum(is.na(data$eventDate)) # there are 9475 NA in eventDate
# sum(is.na(data$date_year)) # there are 9475 NA in date_year


library(lubridate)

# Convert ‘eventDate’ to Date format
data$eventDate <- as.Date(data$eventDate, format="%Y-%m-%d")

# Condición para actualizar 'year' solo si es NA
#data$year <- ifelse(is.na(data$year), year(data$eventDate), data$year)

# Priority: 1) date_year, 2) eventDate
data$year <- ifelse(is.na(data$year), 
                    ifelse(!is.na(data$date_year), data$date_year, year(data$eventDate)), 
                    data$year)

# Verification
# sum(is.na(data$year))  # 7483
# max(data$year, na.rm = TRUE) # 2024
# min(data$year, na.rm = TRUE) # 1758

data <- data %>% filter(!is.na(year))
# nrow(data) # 271508
data <- data %>% filter(year >= 1950)
# nrow(data) # 267047

data$date <- as.Date(paste(data$day, data$month, data$year, sep = "/"), format = "%d/%m/%Y")

# 4. Guardar datos procesados
write.csv(
  occurrences_clean,
  here("data", "interim",
       "OBIS_data_sea_base_map_1950.csv"),
  row.names = FALSE
)

###===================================================================================================================================###
### DUPLICATES
###===================================================================================================================================### 

library(coordinateCleaner)
dataDuplic <- cc_dupl(data, 
                      lon = 'decimalLongitude',  
                      lat = 'decimalLatitude', 
                      additions = c('scientificName', 'recordedBy', 'year'))

# Testing duplicates
# Removed 0 records.

dataDuplic <- cc_dupl(data, 
                      lon = 'decimalLongitude',  
                      lat = 'decimalLatitude', 
                      additions = c('year', 'month'))
# Testing duplicates
# Removed 0 records.
