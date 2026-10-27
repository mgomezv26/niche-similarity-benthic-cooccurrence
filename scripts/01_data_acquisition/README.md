# 01 — Adquisición y preparación de datos originales

Esta carpeta contiene los scripts utilizados para obtener los registros de ocurrencia de especies bentónicas y preparar los datos ambientales procedentes de fuentes externas.

Los datos utilizados en el estudio proceden principalmente de **GBIF, OBIS, Bio-ORACLE, Copernicus Marine Service y cartografía de sedimentos marinos**.

El objetivo de esta etapa es conservar las fuentes originales y preparar los productos necesarios para el procesamiento ambiental y espacial posterior.

## 1. Scripts

| Script | Función | Productos principales |
| --- | --- | --- |
| `01_01_GBIF_download.R` | Descarga de registros de ocurrencia de especies desde GBIF. | Datos originales de ocurrencias GBIF |
| `01_02_OBIS_download.R` | Descarga de registros de ocurrencia de especies desde OBIS. | Datos originales de ocurrencias OBIS |
| `01_03_Enviromental_Variables.R` | Preparación de variables ambientales de Bio-ORACLE y cartografía de sedimentos. | Rásteres ambientales intermedios |
| `01_04_Download_Copernicus.py` | Descarga de datos de clorofila de Copernicus Marine Service para el periodo de estudio. | Archivos oceanográficos originales de Copernicus |

Los scripts se han reorganizado y renombrado para mantener una nomenclatura coherente con las demás etapas del proyecto.

## 2. Fuentes de datos

### 2.1. GBIF — Global Biodiversity Information Facility

**Script:** `01_01_GBIF_download.R`

GBIF proporciona registros de presencia de especies procedentes de colecciones científicas, observaciones y otras fuentes de biodiversidad.

Los registros descargados constituyen una de las fuentes principales para construir la base de datos de ocurrencias del estudio.

La depuración, armonización y combinación con los registros OBIS se realiza posteriormente en `02_data_processing/`.

### 2.2. OBIS — Ocean Biodiversity Information System

**Script:** `01_02_OBIS_download.R`

OBIS proporciona registros georreferenciados de especies marinas.

Estos datos complementan los registros procedentes de GBIF y permiten ampliar la cobertura espacial de las ocurrencias de organismos bentónicos.

La integración entre ambas fuentes se realiza en los scripts de procesamiento de ocurrencias de la etapa 02.

### 2.3. Bio-ORACLE

**Script:** `01_03_Enviromental_Variables.R`

Bio-ORACLE proporciona variables ambientales marinas utilizadas para caracterizar las condiciones ecológicas de los organismos bentónicos.

El estudio utiliza datos ambientales correspondientes a los periodos:

- 2000–2010.
- 2010–2020.

Los productos de ambos periodos se combinan para representar las condiciones ambientales del intervalo de estudio.

Entre las variables consideradas se encuentran la batimetría, oxígeno disuelto, pH, productividad, nutrientes, salinidad, velocidad de las corrientes y temperatura.

La selección final de predictores y su armonización espacial se realiza posteriormente en `02_03_Join_Harmonise_Enviromental_Variables.R`.

### 2.4. Sedimentos marinos

**Script:** `01_03_Enviromental_Variables.R`

Se incorpora información sobre la composición del sustrato marino a partir de una clasificación de litología del fondo oceánico.

La fuente original contiene categorías de sedimento que posteriormente permiten derivar variables relacionadas con:

- El tamaño del sedimento.
- El origen orgánico o inorgánico del material.

Las clases de sedimento se tratan como información categórica durante su procesamiento espacial.

### 2.5. Copernicus Marine Service

**Script:** `01_04_Download_Copernicus.py`

Copernicus Marine Service proporciona los datos de concentración de clorofila utilizados en el estudio como indicador de las condiciones de productividad marina.

El periodo de referencia es **2000–2020**.

Los productos descargados se procesan posteriormente para obtener una representación temporal media compatible con las demás variables ambientales.

La transformación exacta de los archivos originales de Copernicus hasta el ráster medio final debe comprobarse y documentarse antes de considerar esta etapa completamente reproducible.

## 3. Organización de los datos

Los archivos originales e intermedios se organizan mediante la siguiente estructura:

```text
data/
├── raw/
│   ├── occurrences/
│   ├── bio_oracle/
│   │   ├── 2000_2010/
│   │   └── 2010_2020/
│   └── seafloor_sediments/
│
└── interim/
    ├── bio_oracle/
    │   └── raster_stack_biooracle_2000_2020.tif
    └── cmems/
        └── chl_mean_2000_2020_v0.tif
```

Los archivos de ocurrencias originales se conservan en `data/raw/occurrences/`.

Los archivos NetCDF originales de Bio-ORACLE y sedimentos se mantienen separados de los rásteres derivados.

**Nota:** esta estructura documenta la organización prevista de los productos. Las rutas exactas de descarga de GBIF, OBIS y Copernicus deben contrastarse con los scripts y sus configuraciones antes de ejecutar nuevamente el flujo.

## 4. Metodología general

### Descarga de registros de ocurrencia

Los scripts de GBIF y OBIS obtienen los registros georreferenciados correspondientes a las especies consideradas en el estudio.

En esta fase se conservan los datos de origen. Las operaciones de depuración y armonización se realizan en la siguiente etapa.

### Preparación de variables de Bio-ORACLE

Los datos ambientales de los periodos 2000–2010 y 2010–2020 se combinan para obtener las variables representativas del intervalo temporal de estudio.

Los rásteres resultantes se utilizan posteriormente como referencia para armonizar los datos de clorofila y sedimentos.

### Preparación de clorofila

Los datos de clorofila procedentes de Copernicus se utilizan para obtener un producto medio correspondiente al periodo 2000–2020.

El procesamiento histórico desde los archivos descargados hasta el ráster medio todavía no está completamente documentado.

### Preparación de sedimentos

La clasificación original de litología se conserva para su transformación posterior en las variables categóricas utilizadas en el análisis ambiental.

## 5. Dependencias y flujo de procesamiento

**Etapa actual:**

`01_data_acquisition/`

**Etapa posterior:**

`02_data_processing/`

Los scripts de la etapa 02 utilizan los productos obtenidos aquí para:

1. Procesar los registros originales de ocurrencia.
2. Unificar los datos procedentes de GBIF y OBIS.
3. Preparar y armonizar los predictores ambientales.
4. Evaluar la correlación entre variables ambientales.
5. Generar los rásteres ambientales definitivos.

Posteriormente, `03_spatial_processing/` extrae estos valores a las celdas marinas de 0,1°.

## 6. Reproducibilidad y estado

Los scripts se han organizado siguiendo las fuentes de datos utilizadas en el manuscrito.

**Estado actual: código reorganizado, pendiente de ejecución integral y validación frente a los productos históricos.**

Antes de considerar reproducida esta etapa, será necesario comprobar:

- Las consultas y parámetros utilizados en las descargas de GBIF y OBIS.
- Los filtros temporales y taxonómicos aplicados.
- La correspondencia entre los registros descargados y los archivos originales conservados.
- Las variables y periodos temporales de Bio-ORACLE.
- Los parámetros utilizados para descargar los datos de Copernicus.
- El procedimiento de obtención de la clorofila media para 2000–2020.
- La correspondencia entre las categorías originales de sedimento y las variables derivadas.
- Las versiones y referencias de los productos ambientales originales.

Los datos originales de gran tamaño se conservan actualmente fuera del repositorio Git, en el almacenamiento externo del proyecto.

El repositorio contiene los scripts necesarios para documentar y reconstruir el procedimiento, pero **no se ha certificado todavía la reproducción exacta de los productos históricos**.
