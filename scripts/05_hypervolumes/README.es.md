# 05 — Hipervolúmenes y métricas de nicho

**Idioma: [English](README.md) | [Español](README.es.md)**

Esta carpeta contiene los scripts para construir los hipervolúmenes gaussianos de las especies bentónicas y calcular las métricas de similitud de nicho utilizadas en los análisis globales. Los scripts se han reorganizado a partir del código histórico, manteniendo como referencia el procedimiento científico original.

## Scripts y flujo de trabajo

| Script | Entradas principales | Salidas principales |
| --- | --- | --- |
| `05_01_build_gaussian_hypervolumes.R` | `data/processed/grids/grid_meow_env_pca6_0.1deg.gpkg`; `data/processed/grids/species_grid_assignments.gpkg` | Hipervolúmenes individuales `.rds`, `hv_list_all_species.RData`, probabilidades y recuentos de celdas por especie en `results/hypervolumes/gaussian/` |
| `05_02_calculate_hypervolume_overlap.R` | `results/hypervolumes/gaussian/hv_list_all_species.RData` | Volúmenes individuales, correspondencia de especies y métricas de solapamiento por parejas en `results/hypervolumes/overlap/` |
| `05_03_calculate_schoener_d.R` | Grid PCA6, asignaciones de especies e hipervolúmenes gaussianos | Pares de Schoener D, matriz de similitud y bins ambientales muestreados en `results/hypervolumes/schoener/` |

Orden lógico de ejecución: **05_01 → 05_02 y 05_03**. Los scripts `05_02` y `05_03` emplean los resultados de `05_01`, pero no dependen entre sí.

## Decisiones metodológicas conservadas

- Los hipervolúmenes se construyen en el espacio ambiental definido por **PC1–PC6**, calculado previamente en `04_pca/`.
- Se conserva el criterio de **al menos 10 celdas distintas por especie**, contando una única presencia por combinación especie–celda.
- La estimación de nicho utiliza `hypervolume_gaussian()` y el ancho de banda de Silverman, siguiendo el script original.
- Las comparaciones por parejas incluyen las métricas de solapamiento y distancia entre centroides previstas en el análisis histórico.
- Schoener D se calcula sobre bins ambientales comunes, con coordenadas PCA redondeadas a un decimal, hasta 100 000 bins y muestreo ponderado por disponibilidad ambiental; la semilla configurada es `123`.

**Precaución:** el script de Schoener vincula especies e hipervolúmenes por nombre para evitar desajustes de orden. Esta protección y otras limpiezas pueden producir diferencias respecto a salidas históricas si el código anterior emparejaba incorrectamente elementos. No se considera demostrada la equivalencia numérica.

## Organización de resultados

```text
results/
└── hypervolumes/
    ├── gaussian/
    │   ├── hv_list_all_species.RData
    │   ├── hv_probabilities_all_species.rds
    │   ├── hv_probabilities_all_species.csv
    │   ├── hypervolume_<species>.rds
    │   └── ... tablas de control de celdas por especie
    ├── overlap/
    │   ├── individual_volumes_all_species.csv
    │   ├── species_hv_names.csv
    │   └── pairwise_hypervolume_overlap_all_species.csv
    └── schoener/
        ├── schoener_D_pairs_round_1_n_100000.csv
        ├── schoener_D_matrix_round_1_n_100000.rds
        └── env_bins_sampled_round_1_n_100000.rds
```

Los nombres de Schoener con sufijo `n_100000` representan el caso en que se utilizan 100 000 bins; el sufijo debe corresponder al número realmente muestreado. Se acordó **conservar únicamente estos tres productos de Schoener**, evitando CSV y RDS duplicados de probabilidades y tablas intermedias.

## Dependencias con otras etapas

- **Etapa previa:** `04_pca/` genera `grid_meow_env_pca6_0.1deg.gpkg`; `03_spatial_processing/` produce las asignaciones de especies al grid.
- **Etapa siguiente:** `06_global_analyses/06_02_mantel_tests_and_residuals.Rmd` utiliza `pairwise_hypervolume_overlap_all_species.csv` y el CSV de pares de Schoener D para las pruebas globales de Mantel.

Las rutas de los scripts reorganizados se definen con `here()` desde la raíz del repositorio, identificada mediante `.here`. Los datos de entrada y los resultados voluminosos pueden conservarse fuera de GitHub, pero deben estar disponibles en las rutas esperadas cuando se ejecuten los análisis.

## Estado y reproducibilidad

**Estado: scripts reorganizados; ejecución y validación numérica pendientes.** No se han recalculado ni contrastado aquí los hipervolúmenes ni sus métricas con los resultados históricos. Se conservarán los productos originales como referencia hasta comprobar la concordancia de especies, pares y valores. Los inventarios y hashes históricos, cuando estén disponibles, son documentación de procedencia y no equivalen por sí mismos a una validación del flujo nuevo.
