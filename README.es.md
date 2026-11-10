# niche-similarity-benthic-cooccurrence

**Idioma: [English](README.md) | Español**

Repositorio del código científico utilizado en el estudio de la similitud de nicho ambiental y la coocurrencia de especies bentónicas marinas.

Contiene 22 scripts científicos seleccionados, que conservan los procedimientos y cálculos originales del estudio, incluidos los documentos R Markdown completos. El código está organizado en **ocho etapas**, desde la adquisición de datos hasta los análisis estadísticos y la documentación de figuras y tablas.

## Organización del repositorio

| Etapa | Contenido |
|---|---|
| [01_data_acquisition](scripts/01_data_acquisition/README.es.md) | Descarga y preparación inicial de datos de GBIF, OBIS y Copernicus Marine (CMEMS). |
| [02_data_processing](scripts/02_data_processing/README.es.md) | Integración y depuración de ocurrencias y preparación de variables ambientales. |
| [03_spatial_processing](scripts/03_spatial_processing/README.es.md) | Creación de cuadrículas oceánicas, asignación de regiones MEOW, extracción ambiental y asignación de especies a celdas. |
| [04_pca](scripts/04_pca/README.es.md) | Análisis de componentes principales (PCA) y selección de seis componentes ambientales. |
| [05_hypervolumes](scripts/05_hypervolumes/README.es.md) | Construcción de hipervolúmenes ambientales, cálculo de solapamientos, distancias entre centroides y Schoener D. |
| [06_global_analyses](scripts/06_global_analyses/README.es.md) | Coocurrencia global, pruebas de Mantel y análisis de residuos en relación con distancias genéticas externas. |
| [07_local_analyses](scripts/07_local_analyses/README.es.md) | Análisis de comunidades bentónicas de Noruega (MAREANO) a escalas de 5, 40 y 400 m: Mantel, regresiones cuantílicas, residuos, índices comunitarios y modelos ambientales. |
| [08_figures](scripts/08_figures/README.es.md) | Correspondencia entre scripts, figuras, tablas y procedimientos externos utilizados en el artículo. |

## Consideraciones metodológicas

Los scripts documentan los procedimientos científicos originales. Algunas etapas incorporaron operaciones manuales o herramientas externas y no constituyen necesariamente un flujo de ejecución completamente automatizado.

Los análisis genéticos fueron realizados externamente por otro investigador mediante software especializado. Los documentos R Markdown de Porifera y Cnidaria analizan estadísticamente la relación entre los residuos y las matrices de distancias genéticas previamente obtenidas; no generan dichas matrices ni reconstruyen filogenias.

La Figura 1 se obtuvo mediante QGIS. Los gráficos estadísticos de la Figura 4 se generaron en R y posteriormente se combinaron en Affinity, donde se añadieron las ilustraciones biológicas.

## Disponibilidad de datos

Los datos y resultados analíticos asociados a este estudio están depositados en Figshare:

**Dataset:** *Environmental niche similarity and local co-occurrence of marine benthic species: Data and analytical outputs*

**DOI de Figshare:** Pendiente de incorporar tras la publicación definitiva.

El conjunto de datos incluye información ambiental y espacial, productos derivados de ocurrencias de especies, hipervolúmenes de nicho ambiental, matrices de similitud y coocurrencia, resultados estadísticos globales y datos de comunidades bentónicas de Noruega.

Los archivos conservan dos directorios principales:

- **`data/`** — Datos ambientales y espaciales, información de ocurrencias y matrices de presencia-ausencia de especies.
- **`results/`** — Resultados de hipervolúmenes, matrices de similitud de nicho, análisis estadísticos y figuras.

Para utilizar estos archivos junto con el código, se deben conservar las rutas relativas originales de `data/` y `results/`. Algunos scripts mantienen referencias a rutas históricas y pueden necesitar configuración adicional para su ejecución en otros equipos.

Los datos procedentes de proveedores externos deben citarse y reutilizarse de acuerdo con sus correspondientes condiciones de uso.