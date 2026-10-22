

"The chlorophyll data used in this study were obtained from the ‘Global Ocean Biogeochemistry Hindcast’ dataset (DOI: https://doi.org/10.48670/moi-00019) provided by Copernicus Marine Service."
"The download was performed via the Copernicus Python API using the subset option, which allows the selection of data in time, space and variables."

###===================================================================================================================================###
### LOAD PACKAGES
###===================================================================================================================================###

# Python version: 3.12

import copernicusmarine # Version 2.0.1
import xarray as xr # Version 2025.1.2
import pandas as pd # Version 2.2.3
import matplotlib.pyplot as plt # Version 3.10.0
import numpy as np # Version 2.2.1


###===================================================================================================================================###
### CHLOROPHYLL - PHYTOPLANKTON CORRELATION
###===================================================================================================================================###


# 1 Data Download ----------------------------------------------

copernicusmarine.subset(
   dataset_id = "cmems_mod_glo_bgc_my_0.25deg_P1M-m",
   variables = ["chl", "phyc"],
   start_datetime = "2000-01-01T00:00:00",
   end_datetime = "2000-12-01T23:59:59",
   minimum_longitude = -180,
   maximum_longitude = 180, 
   minimum_latitude = -90,
   maximum_latitude = 90,
   minimum_depth=0,
   maximum_depth=1,
)

dataset = xr.open_dataset('cmems_mod_glo_bgc_my_0.25deg_P1M-m_chl-phyc_180.00W-179.75E_80.00S-90.00N_0.51m_2000-01-01-2000-12-01.nc')
print(dataset)

## Select the variables of interest
chl = dataset["chl"]
phyc = dataset["phyc"]

## Remove the ‘depth’ dimension
chl = chl.squeeze(dim="depth")
phyc = phyc.squeeze(dim="depth")

## Calculate correlation over time
correlation_map = xr.corr(chl, phyc, dim="time")

# 2. Display the correlation map ------------------------------------

plt.figure(figsize=(10, 6))
correlation_map.plot(cmap="coolwarm", vmin=-1, vmax=1)
plt.title("Chlorophyll - Phytoplankton Correlation")
plt.show()

# 3. Calculate the overall correlation
chl_values = chl.values.reshape(12, -1) 
phyc_values = phyc.values.reshape(12, -1)

## Filter NaN values
mask = ~np.isnan(chl_values[0]) & ~np.isnan(phyc_values[0])
chl_filtered = chl_values[:, mask]
phyc_filtered = phyc_values[:, mask]

## Calculate the overall correlation
global_corr = np.corrcoef(chl_filtered.flatten(), phyc_filtered.flatten())[0, 1]
print(f"Chlorophyll - Phytoplankton Global Correlation: {global_corr:.3f}")


###===================================================================================================================================###
### ANALYSIS OF DEPTH LEVELS FOR ONE MONTH
###===================================================================================================================================###

# 1 Data Download ----------------------------------------------

copernicusmarine.subset(
   dataset_id = "cmems_mod_glo_bgc_my_0.25deg_P1M-m",
   variables = ["chl", "phyc"],
   start_datetime = "2000-01-01T00:00:00",
   end_datetime = "2000-01-31T23:59:59",
   minimum_longitude = -180,
   maximum_longitude = 180, 
   minimum_latitude = -90,
   maximum_latitude = 90,
)

dataset = xr.open_dataset('cmems_mod_glo_bgc_my_0.25deg_P1M-m_chl-phyc_180.00W-179.75E_80.00S-90.00N_0.51-5902.06m_2000-01-01.nc')
print(dataset)

print(dataset['depth'].values)

# 2. Count valid values (not NaN) per depth --------------------------------------

count_per_depth = dataset['chl'].count(dim=['latitude', 'longitude', 'time'])

## plot
count_per_depth.plot(marker='o', linestyle='-')
plt.title("Number of valid data per depth")
plt.xlabel("Depth (m)")
plt.ylabel("Number of valid data")
plt.grid()
plt.show()

print(count_per_depth)

depth_values = dataset['depth'].values
depth_values_df = np.c_[depth_values, count_per_depth]
depth_values_df = pd.DataFrame(depth_values_df)

depth_values_df.to_csv('depth_values_df.csv', index=False)



###===================================================================================================================================###
### CHLOROPHYLL DATA DOWNLOAD AT A DEPTH OF 30m
###===================================================================================================================================###

copernicusmarine.subset(
   dataset_id = "cmems_mod_glo_bgc_my_0.25deg_P1M-m",
   variables = ["chl"],
   start_datetime = "2020-01-01T00:00:00", # Change year
   end_datetime = "2020-12-01T23:59:59", # Change year
   minimum_longitude = -180,
   maximum_longitude = 180, 
   minimum_latitude = -90,
   maximum_latitude = 90,
   minimum_depth=30,
   maximum_depth=31,
)