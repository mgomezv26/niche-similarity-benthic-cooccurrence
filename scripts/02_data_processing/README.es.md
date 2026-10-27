# 03 — Procesamiento espacial

**Idioma: [English](README.md) | [Español](README.es.md)**

Esta carpeta contiene los scripts responsables de construir la cuadrícula oceánica global de 0,1°, asignar las regiones biogeográficas MEOW, extraer las variables ambientales y asociar los registros de ocurrencia de las especies bentónicas a las celdas espaciales.

El objetivo es generar una estructura espacial común para los análisis posteriores de nicho ambiental, PCA, hipervolúmenes y coocurrencia.

## 1. Scripts

| Script | Función | Salida principal |
| --- | --- | --- |
| `03_01_create_ocean_grid.py` | Genera la cuadrícula global de 0,1° y elimina las celdas que intersectan tierra. | `grid_ocean_0.1deg.gpkg` |
| `03_02_assign_meow_realms.R` | Asigna las regiones biogeográficas MEOW a las celdas oceánicas. | `grid_meow_0.1deg.gpkg` |
| `03_03_extract_environmental.R` | Extrae las variables ambientales a las celdas del grid y elimina las celdas sin información ambiental requerida. | `grid_meow_env_clean_0.1deg.gpkg` |
| `03_04_assign_species_to_grid.R` | Asigna los registros de ocurrencia de las especies a las celdas espaciales. | `species_grid_assignments.gpkg` |

Los scripts `03_02`, `03_03` y `03_04` proceden de la reorganización del antiguo archivo `Assign_MEOW_realms_to_grid.R`, que combinaba distintas operaciones espaciales y ambientales.

## 2. Datos de entrada

### Cuadrícula oceánica

El script `03_01_create_ocean_grid.py` utiliza:

- `data/interim/environmental/r_stack_standardized.tif`: ráster de referencia para definir la extensión espacial.
- `data/raw/geography/basemap2.shp`: cartografía terrestre utilizada para excluir las celdas que intersectan tierra.

La cuadrícula se genera con una resolución espacial de **0,1° × 0,1°**.

### Regiones biogeográficas MEOW

El script `03_02_assign_meow_realms.R` utiliza:

- `data/interim/grids/grid_ocean_0.1deg.gpkg`
- `data/raw/meow/meow_ecos.shp`

Se incorporan los atributos `REALM` y `RLM_CODE` mediante una unión espacial por intersección.

### Variables ambientales

El script `03_03_extract_environmental.R` utiliza:

- `data/interim/grids/grid_meow_0.1deg.gpkg`
- `data/processed/environmental/raster_standardized_vars_correct_new_vars.tif`
- `data/processed/environmental/layer_names_raster_standardized_vars_correct_new_vars.rds`

Los valores ambientales se extraen a partir de los rásteres armonizados y estandarizados durante la etapa anterior.

### Registros de especies

El script `03_04_assign_species_to_grid.R` utiliza los registros de ocurrencia procesados y la cuadrícula ambiental definitiva.

El archivo de referencia para las ocurrencias procesadas es:

`data/interim/occurrences/species_data.csv`

## 3. Metodología

### 3.1. Creación del grid oceánico

**Script:** `03_01_create_ocean_grid.py`

1. Obtiene la extensión espacial del ráster ambiental de referencia.
2. Construye una cuadrícula regular global de 0,1°.
3. Asigna un identificador único `cell_id` a cada celda.
4. Identifica las celdas que intersectan la cartografía terrestre.
5. Excluye esas celdas para conservar únicamente las celdas oceánicas.

Se generan dos archivos:

- `grid_global_0.1deg.gpkg`: cuadrícula completa.
- `grid_ocean_0.1deg.gpkg`: cuadrícula después de excluir las celdas que intersectan tierra.

**Importante:** la exclusión se realiza por intersección con tierra. Las celdas costeras no se recortan para conservar únicamente su superficie marina.

### 3.2. Asignación de regiones MEOW

**Script:** `03_02_assign_meow_realms.R`

1. Carga la cuadrícula oceánica y los polígonos MEOW.
2. Comprueba y armoniza los sistemas de referencia espacial.
3. Realiza una unión espacial por intersección.
4. Incorpora los atributos `REALM` y `RLM_CODE`.
5. Conserva únicamente las celdas con una región asignada.
6. Mantiene una única fila por `cell_id`.

Cuando una celda intersecta varias regiones, el procedimiento conserva la primera correspondencia obtenida por la unión espacial.

La operación asigna atributos biogeográficos; no recorta las geometrías del grid según los límites MEOW.

### 3.3. Extracción de variables ambientales

**Script:** `03_03_extract_environmental.R`

Las variables ambientales continuas se extraen utilizando su **valor medio dentro de cada celda de 0,1°**.

Variables continuas:

- `bathymetry`
- `o2`
- `ph`
- `phyc`
- `po4`
- `so`
- `sws`
- `thetao`
- `chl`

Las variables categóricas relacionadas con el sedimento se resumen mediante su **clase modal**:

- `sediment_size`
- `z_origin`

El procesamiento conserva los campos derivados `r_sediment_size` y `r_sediment_origin`.

Posteriormente, se eliminan las celdas sin valores válidos en las variables ambientales requeridas, siguiendo los filtros del procedimiento original.

El resultado es la cuadrícula ambiental definitiva utilizada para la PCA.

### 3.4. Asignación de ocurrencias de especies

**Script:** `03_04_assign_species_to_grid.R`

1. Carga los registros de ocurrencia procesados.
2. Utiliza las coordenadas geográficas de las especies para realizar la asignación espacial.
3. Relaciona cada registro con las celdas del grid ambiental definitivo.
4. Conserva los identificadores de celda y especie necesarios para construir posteriormente las matrices de presencia/ausencia.
5. Genera el archivo espacial de asignaciones.

Esta etapa sustituye la unión espacial que se realizaba anteriormente mediante QGIS.

La equivalencia exacta con la operación histórica de QGIS está pendiente de validación.

## 4. Archivos de salida

### Resultados intermedios

`data/interim/grids/`

| Archivo | Contenido |
| --- | --- |
| `grid_global_0.1deg.gpkg` | Cuadrícula global completa |
| `grid_ocean_0.1deg.gpkg` | Celdas oceánicas después de excluir las intersecciones con tierra |
| `grid_meow_0.1deg.gpkg` | Celdas oceánicas con atributos biogeográficos MEOW |
| `grid_meow_env_0.1deg.gpkg` | Cuadrícula MEOW con los valores ambientales extraídos, antes del filtrado definitivo |

### Resultados procesados

`data/processed/grids/`

| Archivo | Contenido | Uso posterior |
| --- | --- | --- |
| `grid_meow_env_clean_0.1deg.gpkg` | Grid MEOW con las variables ambientales definitivas | PCA ambiental |
| `species_grid_assignments.gpkg` | Registros de especies asociados a las celdas del grid | Hipervolúmenes y coocurrencia |

Estos dos GeoPackages constituyen los productos principales de esta etapa.

## 5. Dependencias y orden de ejecución

Los scripts deben ejecutarse en el siguiente orden:

1. `03_01_create_ocean_grid.py`
2. `03_02_assign_meow_realms.R`
3. `03_03_extract_environmental.R`
4. `03_04_assign_species_to_grid.R`

**Etapas anteriores:**

- `01_data_acquisition/`: adquisición de registros y datos ambientales.
- `02_data_processing/`: procesamiento de ocurrencias y preparación y armonización de variables ambientales.

**Etapas posteriores:**

- `04_pca/04_01_environmental_pca.R`: reducción de dimensionalidad ambiental.
- `05_hypervolumes/05_01_build_gaussian_hypervolumes.R`: construcción de hipervolúmenes de nicho.
- `06_global_analyses/06_01_calculate_global_cooccurrence.R`: cálculo de coocurrencia espacial entre especies.

## 6. Reproducibilidad y estado

Los scripts han sido reorganizados para separar las operaciones espaciales y eliminar la dependencia de rutas absolutas.

Los scripts R utilizan `here()` y el script Python utiliza rutas relativas al proyecto.

**Estado actual: scripts reorganizados, pendientes de ejecución integral y validación numérica frente a los productos históricos.**

Antes de considerar reproducidos los resultados originales, será necesario comprobar:

- El número de celdas generadas en la cuadrícula global y oceánica.
- La exclusión de celdas que intersectan tierra.
- La asignación de regiones MEOW, especialmente en celdas que intersectan varios polígonos.
- La correspondencia de los valores ambientales extraídos.
- Los filtros aplicados para obtener el grid ambiental definitivo.
- La asignación de registros de especies a celdas, comparándola con la operación histórica realizada en QGIS.
- La conservación de identificadores y nombres de especies entre las distintas etapas.

Durante el procesamiento histórico pudieron realizarse ajustes manuales en QGIS que todavía no están completamente documentados. Estos ajustes deben identificarse antes de certificar la reproducción exacta del resultado original.

Los GeoPackages y rásteres de gran tamaño se mantienen fuera del repositorio Git por el momento. La disponibilidad de los datos de entrada es necesaria para ejecutar y validar este flujo.