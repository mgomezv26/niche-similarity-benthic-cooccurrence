
### LOAD LIBRARIES 
library(rgbif)
library(dplyr)
library(readxl)
library(ggplot2)
library(maps)
library(viridis)
library(CoordinateCleaner)
library(sf)

library(here)

# Read GBIF data
list_species <- read_excel(
  here("data", "list_of_species.xlsx")
)

list_species <- read_excel("list_of_species_V0.xlsx", sheet = "species")
str(list_species)

length(unique(list_species$species)) #There are 175 species in our firts list

###===================================================================================================================================###
### DOWNLOAD GBIF DATA
###===================================================================================================================================###

GBIF_USER=Sys.getenv("GBIF_USER")
GBIF_PWD=Sys.getenv("GBIF_PWD")
GBIF_EMAIL=Sys.getenv("GBIF_EMAIL")

# list of species (accepted names and synonyms) from previous taxonomical knowledge and query databases
list = list_species$species

gbif_taxon_keys <- name_backbone_checklist(list) %>% # match to backbone
  filter(!matchType == "NONE") %>% # get matched names
  pull(usageKey)

occ_download(pred_in("taxonKey", gbif_taxon_keys),
              pred_in("occurrenceStatus","PRESENT"), # avoid absences
              pred("hasCoordinate", TRUE), # only records with coordinates values
              pred("hasGeospatialIssue", FALSE), # records with no geospatial issue
              pred_not(pred_in("BASIS_OF_RECORD", # e.g. discard fossils
                                c("FOSSIL_SPECIMEN"))),
              format = "SIMPLE_CSV",
              #pred_gte("year", 1970), # records from 1970 onwards
              user = GBIF_USER,
              pwd = GBIF_PWD,
              email = GBIF_EMAIL)

occData <- occ_download_get(occ_download) |>
  occ_download_import()

# 4) information about download
occ_download_wait('0000207-250214102907787') # Download key

# status: running
# status: succeeded
# download is done, status: succeeded
# <<gbif download metadata>>
# Status: SUCCEEDED
# DOI: 10.15468/dl.m4cm94
# Format: SIMPLE_CSV
# Download key: 0000207-250214102907787
# Created: 2025-02-14T13:49:22.779+00:00
# Modified: 2025-02-14T14:01:46.462+00:00
# Download link: https://api.gbif.org/v1/occurrence/download/request/0000207-250214102907787.zip
# Total records: 1253124

# 5) Assign the dataset to an object
data <- occ_download_get('0000207-250214102907787') %>% 
  occ_download_import()

# 6) Check species downloaded
missing_species <- setdiff(list_species$species, data$species) # species present in list_species but not present in the data downloaded from gbif (data)
missing_species 
# "Metacallophyllis laciniata" --> Corresponds to the "Metacallophyllis spec." they are synonyms.The synonym is accepted in WoRMS. 
# However, in GBIF it is with the name of the synonym, when merging the GBIF and OBIS data it will be renamed as “Metacallophyllis laciniata” to harmonize both data sets.


missing_species_2 <- setdiff( data$species, list_species$species) # species present in data but not present in list_species
missing_species_2
# "Metacallophyllis spec". Corresponds with "Metacallophyllis laciniata".


# Therefore, occurrences for the 175 species of the original list ("list_of_species_V0.xlsx", sheet = "species") have been downloaded from GBIF.


###===================================================================================================================================###
### PREVIOUS MODIFICATIONS AND EDA
###===================================================================================================================================###

colnames(data) # names of the fields

fields <- c("gbifID","phylum", "class", "order", "family", "genus", "species", 
            "taxonRank", "scientificName",
            "countryCode", "locality", "stateProvince",
            "decimalLatitude",	"decimalLongitude", "coordinatePrecision",
            "day", "month", "year","eventDate", "depth",
            "occurrenceStatus", "basisOfRecord", "recordedBy", "institutionCode", "issue")

data <- data[ , fields, with = FALSE]

rm(fields)
colSums(is.na(data))

data$date <- paste(data$day, data$month, data$year, sep = '/')
#write.csv(data, "01_DATA/03_GBIF/df_gbif_original.csv")

nrow(data) #1253124

# EDA related to records ===============================================================================================================

unique(data$basisOfRecord) # type of occurrences
table(data$basisOfRecord) # Number of records for each basisOfRecord

#"HUMAN_OBSERVATION" 906187
#"PRESERVED_SPECIMEN" 118273
#"MATERIAL_SAMPLE" 176936
#"MATERIAL_CITATION" 1479 -> eliminate
#"OBSERVATION" 195
#"MACHINE_OBSERVATION" 36009 -> eliminate, automated process
#"OCCURRENCE" 13993
#"LIVING_SPECIMEN" 52 -> eliminate

data <- data %>% filter(basisOfRecord != c('MATERIAL_CITATION','LIVING_SPECIMEN', 'MACHINE_OBSERVATION'))

nrow(data) #1240603

###===================================================================================================================================###
### TAXONOMIC
###===================================================================================================================================###

nrow(data) #1240603

unique(data$taxonRank)
table(data$taxonRank)

#"SPECIES" 1232320
#"SUBSPECIES" 852
#"UNRANKED" 2226 --> These records do not have a scientific name, they have an identifier from the BOLD (Barcode of Life Data System) database which gives DNA data. They are deleted
#"VARIETY" 4926
#"FORM" 279

#UNRANKED <- data %>% filter (taxonRank == "UNRANKED") # There are 2226
#View(UNRANKED)

data <- data %>% filter (taxonRank != "UNRANKED")
nrow(data) # 1238377

#rm(UNRANKED)

# Create a checklist with scientific names
checklist <- data[ ,c("phylum", "class", "order","family", "genus", "species", "taxonRank", "scientificName")]
checklist <- data.frame(unique(checklist)) # remove duplicated entries
checklist <- checklist %>%
  arrange(phylum, class, order, family, genus, species)

write.table(checklist, '02_EDA/checklist.csv', sep="\t", row.names=FALSE)

checklist_group <- checklist %>% group_by(phylum, class, order, family, genus, species) %>%
  summarise(n = n()) %>%
  arrange(phylum, class, order, family, genus,species)


#### GBIF tax backbone ####
list <- checklist$scientificName
gbif_stand <- data.frame()

for (i in list){
  gbif_check <- name_backbone(i)
  gbif_stand <- dplyr::bind_rows(gbif_stand, gbif_check)
}

gbif_stand <- gbif_stand[ , c('status', 'matchType', 'species')]

gbif_stand <- dplyr::rename(gbif_stand, 'gbif_status' = 'status',
                            'gbif_matchType' = 'matchType',
                            'gbif_species' = 'species')

checklist <- cbind(checklist, gbif_stand)

unique(checklist$gbif_status)
table(checklist$gbif_status)
#"ACCEPTED" 202
#"SYNONYM" 535
#"DOUBTFUL" 1


# Filter only Accepted names
checklist <- checklist %>% filter(gbif_status !="DOUBTFUL")

accepted_scientificName <- checklist %>% 
  filter(taxonRank == "SPECIES" & gbif_status == "ACCEPTED") %>%
  select(species, scientificName)

length(unique(accepted_scientificName$species)) #There are 174 phylums

# species present in checklist_group but not present in accepted_scientificName
missing_species_2 <- setdiff( checklist_group$species, accepted_scientificName$species)
missing_species_2
# It states that the species Metacallophyllis spec is missing.
# This species is listed as ‘Metacallophyllis laciniata’.
# Its accepted name in WORMS is Metacallophyllis laciniata (Hudson) A.Vergés & L.Le Gall, 2017.
# GBIF states that it is synonymous with ‘Metacallophyllis spec (Hudson) A.Vergés & L.Le Gal’ but this is incorrect according to WORMS.
# The scientific name ‘Metacallophyllis laciniata (Hudson) A.Vergés & L.Le Gall, 2017’ should be added to the records of the following species:
# Metacallophyllis laciniata (there is no record as gbif considers it to be called ‘Metacallophyllis spec’).
# Metacallophyllis spec

accepted_scientificName <- rbind(accepted_scientificName, data.frame(
  species = "Metacallophyllis spec", 
  scientificName = "Metacallophyllis laciniata (Hudson) A.Vergés & L.Le Gall, 2017"
))


# Join accepted scientificName
data <- data %>%
  left_join(accepted_scientificName %>% rename(accepted_scientificName = scientificName), by = "species")


###===================================================================================================================================### 
### GEOGRAPHIC
###===================================================================================================================================### 

nrow(data) #1238377

# 1. Check coordinates values: ----

flags <- clean_coordinates(x = data,
                            lon = "decimalLongitude",
                            lat = "decimalLatitude",
                            species = "species",
                            tests = c("validity", "equal",
                                      "zeros", "duplicates"))

#Testing coordinate validity
#Flagged 0 records.
#Testing equal lat/lon # Latitude and longitude present the exact same value
#Flagged 13 records.
#Testing zero coordinates # Latitude or longitude values equals to zero
#Flagged 31 records.
#Testing duplicates
#Flagged 552430 records.
#Flagged 552459 of 1238377 records, EQ = 0.45.

#summary(flags)

data <- clean_coordinates(x = data,
                          lon = "decimalLongitude",
                          lat = "decimalLatitude",
                          species = "species",
                          tests = c("validity", "equal",
                                    "zeros",
                                    "duplicates"),
                          value = "clean")

nrow(data) # 685918

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
nrow(data) # 682871

# 3. Check coordinates values with rounded decimals: ----

data$LatRound<- round(data$decimalLatitude, 2)
data$LongRound <- round(data$decimalLongitude, 2)

flags <- clean_coordinates(x = data,
                            lon = "LongRound",
                            lat = "LatRound",
                            species = "species",
                            tests = c("validity", "equal", "duplicates"))

data <- clean_coordinates(x = data,
                          lon = "LongRound",
                          lat = "LatRound",
                          species = "species",
                          tests = c("validity", "equal", "duplicates"),
                          value = "clean")

nrow(data) # 389417

rm(accepted_scientificName, checklist, checklist_group, flags, gbif_check, gbif_stand, list_species, latDigits, lonDigits)


#------------------------------
# 4. Check position of coordinates: ----

# Using Base Map to filter ----

data<- read.csv('01_DATA/03_GBIF/data_clean_coordinates_v1.csv')
data_sf <- st_as_sf(data, coords = c("decimalLongitude", "decimalLatitude"), crs = 4326)

base_africa <- st_read("01_DATA/shapefiles/capas_basemap/base_africa.shp")
base_asia <- st_read("01_DATA/shapefiles/capas_basemap/base_asia.shp")
base_antarctic <- st_read("01_DATA/shapefiles/capas_basemap/base_antarctic.shp")
base_australian <- st_read("01_DATA/shapefiles/capas_basemap/base_australian.shp")
base_europe <- st_read("01_DATA/shapefiles/capas_basemap/base_europe.shp")
#base_n_america <- st_read("01_DATA/shapefiles/capas_basemap/base_n_america.shp")
base_s_america <- st_read("01_DATA/shapefiles/capas_basemap/base_s_america.shp")
n_america <- st_read("01_DATA/shapefiles/capas_basemap/n_america.shp")
base_canada <- st_read("01_DATA/shapefiles/capas_basemap/base_canada.shp")

#st_crs(basemap) # WGS 84 ID["EPSG",4326]]
#st_crs(data_sf)

sum(!st_is_valid(base_europe)) # Polygon validity test
base_europe <- st_make_valid(base_europe) # Correct invalid geometries in basemap

# st_intersects returns a logical array if we use sparse = FALSE
inter_matrix <- st_intersects(data_sf,n_america, sparse = FALSE)
# Create a logical vector that is TRUE if the record intersects (at least one polygon).
land_flags <- apply(inter_matrix, 1, any)

records_land_africa <- data_sf[land_flags, ]
records_land_asia <- data_sf[land_flags, ]
records_land_antarctic <- data_sf[land_flags, ]
records_land_australian <- data_sf[land_flags, ]
records_land_n_america <- data_sf[land_flags, ]
records_land_s_america <- data_sf[land_flags, ]
records_land_europe <- data_sf[land_flags, ]
records_land_canada <- data_sf[land_flags, ]
records_land_n_america_c <- data_sf[land_flags, ]

# write.csv(records_land_africa, '01_DATA/records_sea_land/records_land_africa.csv')
# write.csv(records_land_asia, '01_DATA/records_sea_land/records_land_asia.csv')
# write.csv(records_land_antarctic, '01_DATA/records_sea_land/records_land_antarctic.csv')
# write.csv(records_land_australian, '01_DATA/records_sea_land/records_land_australian.csv')
# write.csv(records_land_s_america, '01_DATA/records_sea_land/records_s_america.csv')
# #write.csv(records_land_n_america, '01_DATA/records_sea_land/records_land_n_america.csv')
# write.csv(records_land_europe, '01_DATA/records_sea_land/records_land_europe.csv')
# write.csv(records_land_canada, '01_DATA/records_sea_land/records_land_canada.csv')
# write.csv(records_land_n_america_c, '01_DATA/records_sea_land/records_land_n_america_c.csv')

records_land_africa <- read.csv('01_DATA/records_sea_land/records_land_africa.csv')
records_land_asia <- read.csv('01_DATA/records_sea_land/records_land_asia.csv')
records_land_antarctic <- read.csv('01_DATA/records_sea_land/records_land_antarctic.csv')
records_land_australian <- read.csv('01_DATA/records_sea_land/records_land_australian.csv')
records_land_s_america <- read.csv('01_DATA/records_sea_land/records_s_america.csv')
#records_land_n_america <- read.csv('01_DATA/records_sea_land/records_land_n_america.csv')
records_land_europe <- read.csv('01_DATA/records_sea_land/records_land_europe.csv')
records_land_canada <- read.csv('01_DATA/records_sea_land/records_land_canada.csv')
records_land_n_america_c <- read.csv('01_DATA/records_sea_land/records_land_n_america_c.csv')

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
data_land <- dplyr::rename(data_land, 'gbifID' = 'X')
write.csv(data_land, '01_DATA/records_sea_land/data_land.csv')

# Ground records are deleted using the ‘gbifID’ field by the anti_join() function.
common_ids <- intersect(data$gbifID, data_land$gbifID)
#length(common_ids) # 81976
data_sea <- anti_join(data, data_land, by = "gbifID")
#nrow(data_sea) # 307441


###===================================================================================================================================###
### TEMPORAL
###===================================================================================================================================### 

library(lubridate)

data <- read.csv('01_DATA/03_GBIF/data_sea_base_map.csv')
# str(data)
# nrow(data) # 307441

sum(is.na(data$year)) # there are 8447 NA in year
max(data$year, na.rm = TRUE) # 2025
min(data$year, na.rm = TRUE) # 1690

data$date <- as.Date(data$date, format="%d/%m/%Y") 
# sum(is.na(data$date)) # there are 39260 wrong or invalid dates

data$eventDate <- as.Date(data$eventDate, format = "%Y-%m-%d") 
# sum(is.na(data$eventDate)) # there are 28483 NA 

data$year <- ifelse(is.na(data$year), year(data$eventDate), data$year)
# sum(is.na(data$year)) # there are 6889 NA in year


# delete records without a year
data <- data[!is.na(data$year), ]
nrow(data) # 300552

# sum(is.na(data$month)) # 16906
# sum(is.na(data$day)) # 32371

data$day <- ifelse(is.na(data$day), day(data$eventDate), data$day)
data$month <- ifelse(is.na(data$month), month(data$eventDate), data$month)

# sum(is.na(data$month)) # 11502
# sum(is.na(data$day)) # 20080

data$date <- as.Date(paste(data$day, data$month, data$year, sep = "/"), format = "%d/%m/%Y")
# sum(is.na(data$date)) # there are 20080 NA

data <- data %>% filter(year >= 1950)
# nrow(data) # 287181


write.csv(
  occurrences_clean,
  here("data", "interim",
       "GBIF_data_sea_base_map_1950.csv"),
  row.names = FALSE
)

###===================================================================================================================================###
### DUPLICATES
###===================================================================================================================================### 

library(coordinateCleaner)

dataDuplic <- cc_dupl(data, lon = 'decimalLongitude', lat = 'decimalLatitude', additions = c('scientificName', 'recordedBy', 'year'))

dataDuplic <- cc_dupl(data, 
                      lon = 'decimalLongitude',  
                      lat = 'decimalLatitude', 
                      additions = c('year', 'month'))
#Testing duplicates
#Removed 0 records.