# 06 — Análisis globales

**Idioma: [English](README.md) | [Español](README.es.md)**

Esta carpeta contiene los scripts del análisis de coocurrencia a escala global, su relación con la similitud/proximidad del nicho ambiental y la evaluación posterior de los residuos frente a las distancias genéticas COI de **Cnidaria** y **Porifera**.

## Scripts y flujo de trabajo

| Script | Entradas principales | Resultados |
| --- | --- | --- |
| `06_01_calculate_global_cooccurrence.R` | `data/processed/grids/species_grid_assignments.gpkg` | Matriz de coocurrencia absoluta, distancia de Jaccard espacial y recuentos de celdas por especie (`results/global_analyses/cooccurrence/`). |
| `06_02_mantel_tests_and_residuals.Rmd` | Solapamiento de hipervolúmenes (`results/hypervolumes/overlap/`), Schoener's D (`results/hypervolumes/schoener/`) y distancia de Jaccard espacial del paso 06_01 | Matrices alineadas por especie, tres tests globales de Mantel, residuos, tablas diagnósticas y figuras (`results/global_analyses/mantel/`). |
| `06_03_cnidaria_phylogenetic_residuals.Rmd` | Residuos globales de Schoener y Jaccard, orden de especies, correspondencias taxonómicas y matriz COI externa de Cnidaria | Dos tests de Mantel residuo–distancia genética, residuos filtrados y figuras (`results/global_analyses/phylogenetic_residuals/cnidaria/`). |
| `06_04_porifera_phylogenetic_residuals.Rmd` | Residuos globales de Schoener y Jaccard, orden de especies, correspondencias taxonómicas y matriz COI externa de Porifera | Dos tests de Mantel residuo–distancia genética, residuos filtrados y figuras (`results/global_analyses/phylogenetic_residuals/porifera/`). |

**Orden de ejecución:** `06_01` → `06_02` → `06_03` y `06_04` (los dos últimos son independientes entre sí). Los scripts de hipervolúmenes de `05_hypervolumes/` deben haberse ejecutado antes de `06_02`.

## Entradas externas para los análisis COI

- `data/raw/phylogenetics/cnidaria/Cnidaria_Distance_Matrix_COI_MEGA.xlsx`
- `data/raw/phylogenetics/porifera/Porifera_Distance_Matrix_COI_MEGA.xlsx`
- `data/interim/phylogenetics/species_hv_names_tax.xlsx` (hojas `Cnidaria` y `Porifera`).
- `results/global_analyses/mantel/species_order.csv`, `mantel_residuals_schoener.rds` y `mantel_residuals_jaccard.rds`, generados por `06_02`.

Las matrices de distancias **COI se obtuvieron mediante un análisis externo con software especializado**. Estos Rmd **no generan ni validan las distancias genéticas originales**: importan las matrices recibidas, las relacionan con las especies y evalúan su asociación con los residuos globales. El antiguo `17_Phylogeny.R` no se considera un generador acreditado de las matrices COI finales.

## Organización de resultados

```text
results/global_analyses/
├── cooccurrence/
│   ├── cooc_matrix.rds
│   ├── jaccard_distance_matrix.rds
│   └── ... tablas CSV de consulta y control
├── mantel/
│   ├── matrices/
│   ├── figures/
│   ├── species_order.csv
│   ├── mantel_residuals_schoener.rds
│   ├── mantel_residuals_jaccard.rds
│   ├── mantel_residuals_centroid.rds
│   └── ... resúmenes y tablas de residuos
└── phylogenetic_residuals/
    ├── cnidaria/
    │   ├── resid_schoener_cnidaria_COI.rds
    │   ├── resid_jaccard_cnidaria_COI.rds
    │   ├── mantel_summary.csv                 # salida de la versión actual, aún pendiente de ejecutar
    │   ├── genetic_distance_matrix.rds       # exportación auxiliar en el Rmd actual
    │   ├── genetic_distance_matrix.csv       # exportación auxiliar en el Rmd actual
    │   └── figures/
    └── porifera/
        ├── resid_schoener_porifera_COI.rds
        ├── resid_jaccard_porifera_COI.rds
        ├── mantel_residuals_vs_COI_genetic_distance_porifera.csv
        └── figures/
```

La estructura indica **destinos de escritura**, no garantiza que los archivos se hayan regenerado. No crear resultados vacíos ni sustituir resultados históricos antes de comparar ambas versiones.

**Nota sobre la simplificación de salidas:** `06_03` todavía exporta `genetic_distance_matrix.rds`, `genetic_distance_matrix.csv` y `mantel_summary.csv`; en cambio, `06_04` no exporta la matriz genética y conserva el nombre histórico para el CSV de resultados. Esta diferencia está **pendiente de homogeneizar en el código**, no solo en la documentación. Las matrices genéticas auxiliares pueden calcularse en memoria si no son necesarias para análisis posteriores.

## Criterios y reproducibilidad

- En `06_01` cada combinación especie–celda cuenta una sola vez y se mantiene el filtro de presencia en al menos **10 celdas**.
- `06_02` ejecuta **tres tests de Mantel** (Pearson, **1.000 permutaciones**) y obtiene los residuos globales que consumen los siguientes Rmd.
- `06_03` y `06_04` ejecutan **dos tests de Mantel por filo** (Pearson, **999 permutaciones**), comparando distancias COI con residuos de Schoener y Jaccard.
- Las versiones reorganizadas usan rutas relativas mediante `here()` y fijan `set.seed(123)` en los tests de Mantel. Los **valores p pueden diferir** de los HTML históricos, donde la semilla no estaba fijada del mismo modo.
- Los tres Rmd conservan conjuntamente los cálculos y las figuras; no hay copias duplicadas del código en `08_figures/`.
- **Estado:** scripts reorganizados, sin ejecución integral ni comprobación de equivalencia numérica con los resultados históricos. Los HTML originales deben conservarse como referencia durante la validación.

Los conjuntos de datos de gran tamaño y los resultados históricos se mantienen fuera de GitHub por el momento; la publicación y el versionado de los datos se decidirán por separado.
