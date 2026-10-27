
# 04 — Análisis de Componentes Principales (PCA)

Esta carpeta contiene el análisis de componentes principales (PCA) utilizado para reducir la dimensionalidad ambiental antes de construir los hipervolúmenes de nicho de las especies bentónicas.

La PCA se realiza sobre las variables ambientales extraídas para las celdas marinas de 0,1° pertenecientes a las regiones biogeográficas MEOW.

## 1. Scripts

| Script | Entradas | Salidas |
| --- | --- | --- |
| `04_01_environmental_pca.R` | `grid_meow_env_clean_0.1deg.gpkg` | Grid con PC1–PC6, tablas de varianza explicada, cargas ambientales y figuras de PCA |

El script procede del antiguo `11_PCA_REALM.R` y se ha reorganizado para utilizar rutas relativas mediante `here()`.

## 2. Datos de entrada

**Archivo principal:**

`data/processed/grids/grid_meow_env_clean_0.1deg.gpkg`

Este GeoPackage procede de `03_03_extract_environmental.R` y contiene las celdas marinas de 0,1° con las variables ambientales armonizadas y extraídas.

Las diez variables utilizadas para la PCA son:

- `bathymetry`
- `o2`
- `ph`
- `phyc`
- `po4`
- `so`
- `sws`
- `thetao`
- `chl`
- `r_sediment_size`

Las nueve primeras variables continuas se estandarizaron durante el procesamiento ambiental anterior. El tamaño del sedimento se estandariza en el script de PCA.

## 3. Metodología

El script realiza las siguientes operaciones:

1. Carga el grid ambiental definitivo y elimina temporalmente la geometría para el análisis estadístico.
2. Selecciona las diez variables ambientales.
3. Estandariza el tamaño del sedimento.
4. Ejecuta la PCA mediante `prcomp()`, con centrado y sin una segunda estandarización global (`center = TRUE`, `scale. = FALSE`).
5. Calcula la varianza explicada por cada componente.
6. Evalúa la importancia de los componentes mediante el criterio Broken Stick.
7. Conserva los seis primeros componentes principales (PC1–PC6), siguiendo el análisis original del manuscrito.
8. Incorpora las puntuaciones de la PCA al grid espacial.
9. Exporta el GeoPackage final, las tablas y las figuras.

Los seis componentes seleccionados explicaban conjuntamente el 89,96 % de la varianza ambiental en el análisis histórico.

El criterio Broken Stick se conserva como evaluación de los componentes, pero no modifica automáticamente la selección fija de PC1–PC6.

## 4. Archivos de salida

### GeoPackage principal

`data/processed/grids/grid_meow_env_pca6_0.1deg.gpkg`

Contiene las geometrías originales del grid, los atributos ambientales y las puntuaciones de las seis componentes principales.

Este archivo constituye una entrada fundamental para los análisis de hipervolúmenes y similitud de nicho.

### Tablas y figuras

`results/pca/`

Esta carpeta contiene los resultados auxiliares del análisis, como:

- Varianza individual y acumulada de las componentes.
- Comparación con el criterio Broken Stick.
- Cargas ambientales de las componentes.
- Figuras de la PCA y de la varianza explicada.

Los nombres concretos de las tablas y figuras deben comprobarse frente a las exportaciones del script.

## 5. Dependencias

**Etapa anterior:**

`03_spatial_processing/03_03_extract_environmental.R`

**Etapa posterior:**

`05_hypervolumes/05_01_build_gaussian_hypervolumes.R`

Flujo de procesamiento:

`Grid ambiental de 0,1° → PCA → PC1–PC6 por celda → Hipervolúmenes gaussianos`

## 6. Reproducibilidad y estado

El script ha sido reorganizado a partir del análisis original, conservando la selección de variables, el procedimiento de PCA, Broken Stick y los seis componentes utilizados en el manuscrito.

No se ha realizado todavía una ejecución completa ni una validación numérica de la versión reorganizada.

Antes de considerar reproducidos los resultados históricos, será necesario comprobar:

- El número de celdas ambientales incluidas.
- La ausencia de valores faltantes en las variables seleccionadas.
- La varianza acumulada de PC1–PC6 frente al 89,96 % histórico.
- Las cargas ambientales y las puntuaciones de las componentes.
- La correspondencia entre el GeoPackage histórico y el nuevo.

Los datos espaciales de gran tamaño se mantienen fuera del repositorio Git por el momento. El código debe permitir regenerar los productos cuando estén disponibles los archivos de entrada.
