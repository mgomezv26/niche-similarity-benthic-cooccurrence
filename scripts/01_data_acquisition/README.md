# 01 — Adquisición de datos

Finalidad: conservar el código de adquisición original de registros biológicos y de variables CMEMS.

| Script | Entradas | Salidas previstas en el código |
| --- | --- | --- |
| 01_GBIF_download.R | list_of_species_V0.xlsx, servicios GBIF, capas cartográficas de limpieza | CSV de descarga, taxonomía, coordenadas y registros marinos GBIF |
| 02_OBIS_donwload.R | Libro de especies y equivalencias OBIS, servicios OBIS, capas cartográficas | CSV de registros OBIS y diagnósticos de limpieza |
| 05_Download_Copernicus.py | Servicios CMEMS y archivos ambientales de los bloques originales | Subconjuntos ambientales y depth_values_df.csv |


Los tres campos de autenticación GBIF se leen mediante Sys.getenv: GBIF_USER, GBIF_PWD y GBIF_EMAIL. Ningún valor original de esos campos se publica. CMEMS puede requerir autenticación externa propia; no se incorpora configuración local.

Persisten rutas relativas, entradas externas y salidas con nombres originales. La correspondencia entre nombres y productos se documenta como procedencia, sin preparar una ejecución automatizada. No se han modificado filtros ni se ha comprobado la ejecución de las copias.
