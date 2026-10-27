# 07 — Análisis locales de coocurrencia y ambiente

Esta carpeta contiene los scripts utilizados para analizar la relación entre la similitud de nicho ambiental de las especies bentónicas y sus patrones de coocurrencia a escala local.

Los análisis se realizan sobre comunidades de Noruega, considerando tres escalas espaciales: **5 m, 40 m y 400 m**.

Esta etapa complementa los análisis globales realizados en `06_global_analyses/` y permite evaluar cómo varía la relación entre el nicho ambiental y la coocurrencia según la escala espacial.

También incluye un análisis específico de la relación entre las condiciones ambientales locales y la probabilidad esperada de coocurrencia de las comunidades.

## 1. Scripts

| Script | Función | Salidas principales |
| --- | --- | --- |
| `07_01_local_mantel_tests.Rmd` | Evalúa mediante tests de Mantel la relación entre las matrices globales de nicho y las matrices locales de coocurrencia. | Resultados de Mantel y figura comparativa |
| `07_02_expected_vs_observed_cooccurrence.Rmd` | Compara la coocurrencia observada localmente con la esperada a partir de las métricas globales de nicho. | Residuos por pareja de especies y figuras |
| `07_03_local_residual_analysis.R` | Resume las probabilidades esperadas de coocurrencia a nivel de comunidad para cada escala espacial. | Probabilidades por comunidad, resumen y figura |
| `07_04_norway_environmental_models.R` | Analiza la relación entre las variables ambientales de Noruega y las probabilidades esperadas de coocurrencia. | Correlaciones, modelos lineales y figuras |

Los scripts se han reorganizado a partir de los archivos originales:

- `02_Mantel_Test_Local_Scale.Rmd`
- `03_expected_vs_observed_cooccurrence.Rmd`
- `04_Analisis_residuos_locales.R`
- `00_Env_data_norway.R`

El orden de numeración actual refleja las dependencias entre los análisis.

## 2. Datos de entrada

### 2.1. Matrices globales de nicho

Los scripts `07_01` y `07_02` utilizan matrices generadas durante los análisis globales:

`results/global_analyses/mantel/matrices/`

| Archivo | Contenido |
| --- | --- |
| `schoener_matrix.csv` | Matriz global de similitud de nicho basada en Schoener D |
| `niche_jaccard_matrix.csv` | Matriz global de similitud de nicho basada en Jaccard |
| `niche_distance_matrix.csv` | Matriz global de distancias entre centroides de nicho |

La tercera matriz es utilizada por `07_01`, pero no por `07_02`.

### 2.2. Matrices locales de coocurrencia

Los análisis utilizan matrices correspondientes a tres escalas espaciales:

`data/processed/local_analyses/norway/cooccurrence_matrices/`

| Archivo | Contenido |
| --- | --- |
| `jaccard_distance_5m.csv` | Distancias de Jaccard de coocurrencia local a 5 m |
| `jaccard_distance_40m.csv` | Distancias de Jaccard de coocurrencia local a 40 m |
| `jaccard_distance_400m.csv` | Distancias de Jaccard de coocurrencia local a 400 m |
| `presence_absence_5m.csv` | Matriz de presencia/ausencia de especies por muestra a 5 m |
| `presence_absence_40m.csv` | Matriz de presencia/ausencia de especies por muestra a 40 m |
| `presence_absence_400m.csv` | Matriz de presencia/ausencia de especies por muestra a 400 m |

Estas matrices locales proceden del procesamiento previo de datos de comunidades de Noruega.

**Su procedimiento de generación todavía debe documentarse completamente.** Por el momento se consideran entradas preexistentes y no se regeneran automáticamente mediante los cuatro scripts de esta carpeta.

### 2.3. Datos ambientales y muestras de Noruega

El script `07_04_norway_environmental_models.R` utiliza:

| Archivo | Ruta |
| --- | --- |
| `env_full-001.tif` | `data/raw/local_analyses/norway/environmental/` |
| `sample_info_5m_ready.csv` | `data/raw/local_analyses/norway/samples/5m/` |
| `sample_info_40m_ready.csv` | `data/raw/local_analyses/norway/samples/40m/` |
| `sample_info.csv` | `data/raw/local_analyses/norway/samples/400m/` |

Además, utiliza el archivo procesado:

`data/processed/local_analyses/norway/community_expected_cooccurrence_probability_all_filt.csv`

Este último archivo es generado por `07_03_local_residual_analysis.R`.

## 3. Metodología

### 3.1. Tests de Mantel locales

**Script:** `07_01_local_mantel_tests.Rmd`

Este análisis compara las matrices globales de nicho con las matrices de coocurrencia local de las tres escalas espaciales.

Se consideran tres métricas de nicho:

- Jaccard de hipervolúmenes.
- Schoener D.
- Distancia entre centroides de los hipervolúmenes.

Para cada escala se identifican las especies compartidas entre las matrices comparadas.

Se aplica el test de Mantel con:

- Correlación de Pearson.
- 9.999 permutaciones.
- Tres escalas espaciales: 5 m, 40 m y 400 m.

El procedimiento genera nueve comparaciones entre métricas de nicho y escalas espaciales.

Las similitudes de Jaccard y Schoener D se transforman en disimilitudes mediante `1 - similitud` antes de las comparaciones correspondientes.

### 3.2. Coocurrencia observada frente a esperada

**Script:** `07_02_expected_vs_observed_cooccurrence.Rmd`

Este análisis estudia la relación entre la similitud de nicho global y la coocurrencia local.

Se utilizan las matrices globales de Jaccard y Schoener D junto con las matrices locales de coocurrencia de 5, 40 y 400 m.

El script realiza comparaciones entre los valores observados y los valores esperados definidos por el procedimiento original.

Los residuos se calculan a partir de la diferencia entre la coocurrencia observada localmente y los valores esperados derivados de las métricas globales de nicho.

También incluye regresiones, análisis de regresión cuantílica y comparaciones de residuos entre escalas espaciales.

El resultado principal es `residuals_diff_obs_exp.csv`, que constituye una entrada del siguiente script.

### 3.3. Probabilidad esperada de coocurrencia por comunidad

**Script:** `07_03_local_residual_analysis.R`

Este script utiliza:

- Las matrices locales de presencia/ausencia por muestra.
- Los residuos por pareja de especies calculados en `07_02`.

El procedimiento:

1. Normaliza los nombres de especies.
2. Transforma el valor de residuo mediante `expected_prob = (residual + 1) / 2`, siguiendo el cálculo original.
3. Identifica las especies presentes en cada muestra.
4. Genera las combinaciones posibles de parejas de especies.
5. Recupera los valores de probabilidad esperada correspondientes a cada pareja.
6. Calcula la media, mediana y desviación estándar para cada comunidad.
7. Excluye las comunidades sin parejas válidas.
8. Compara los valores entre escalas mediante Kruskal-Wallis.
9. Genera una figura combinada de violín y diagrama de cajas.

La interpretación de `expected_prob` depende de la definición y transformación de los residuos del análisis anterior; esta conversión debe contrastarse durante la validación metodológica.

El producto principal es:

`community_expected_cooccurrence_probability_all_filt.csv`

Este archivo contiene las probabilidades resumidas por muestra y escala espacial y se utiliza posteriormente en los modelos ambientales.

### 3.4. Modelos ambientales de Noruega

**Script:** `07_04_norway_environmental_models.R`

Este análisis relaciona las probabilidades esperadas de coocurrencia con las condiciones ambientales de las comunidades locales.

El script:

1. Extrae doce variables ambientales del ráster original para las muestras de 5, 40 y 400 m.
2. Une la información ambiental con la probabilidad media esperada de coocurrencia.
3. Evalúa las correlaciones entre variables ambientales.
4. Calcula factores de inflación de la varianza (VIF).
5. Ajusta modelos lineales separados por escala espacial utilizando once predictores estandarizados.
6. Genera una figura de coeficientes con intervalos de confianza.
7. Realiza selección de modelos mediante AIC y `MuMIn::dredge()`.
8. Calcula la importancia relativa de los predictores.

El script conserva la selección de variables y el procedimiento estadístico del análisis original.

## 4. Archivos de salida

### 4.1. Tests de Mantel

`results/local_analyses/mantel/`

```text
mantel/
├── mantel_results_df.csv
└── figures/
    └── line_plot.png
```

### 4.2. Coocurrencia observada frente a esperada

`results/local_analyses/expected_vs_observed/`

```text
expected_vs_observed/
├── residuals_diff_obs_exp.csv
└── figures/
    ├── global_niche_vs_local_cooccurrence_scalesv1.png
    ├── global_niche_vs_local_cooccurrence_scales_facet_Quantile.png
    └── residual_boxplot.png
```

### 4.3. Análisis de residuos locales

El resultado procesado utilizado posteriormente por los modelos ambientales se guarda en:

`data/processed/local_analyses/norway/community_expected_cooccurrence_probability_all_filt.csv`

Los resultados descriptivos y gráficos se guardan en:

```text
results/local_analyses/residuals/
├── info_n_community.csv
└── figures/
    └── Mean_expected_cooccurrence_probability_boxplot.png
```

### 4.4. Modelos ambientales de Noruega

`results/local_analyses/norway/environmental_models/`

```text
environmental_models/
├── cor_vars_sel.csv
├── model_summary_local_environment_scaled.csv
└── figures/
    ├── Environmental_effects_coefplot.pdf
    └── Environmental_effects_coefplot.png
```

No se exportan automáticamente todos los objetos estadísticos intermedios, siguiendo la decisión de evitar resultados redundantes.

## 5. Dependencias y orden de ejecución

El flujo principal de los análisis locales es:

```text
Matrices globales de nicho
            +
Matrices locales de coocurrencia
            |
            +----> 07_01_local_mantel_tests.Rmd
            |
            +----> 07_02_expected_vs_observed_cooccurrence.Rmd
                           |
                           v
                  residuals_diff_obs_exp.csv
                           |
             + Matrices presencia/ausencia
                           |
                           v
                07_03_local_residual_analysis.R
                           |
                           v
       community_expected_cooccurrence_probability_all_filt.csv
                           |
               + Datos ambientales locales
                           |
                           v
             07_04_norway_environmental_models.R
```

**Orden recomendado:**

1. `07_01_local_mantel_tests.Rmd`
2. `07_02_expected_vs_observed_cooccurrence.Rmd`
3. `07_03_local_residual_analysis.R`
4. `07_04_norway_environmental_models.R`

El primer script puede ejecutarse independientemente de los otros tres, siempre que estén disponibles las matrices globales y locales.

Los scripts `07_02`, `07_03` y `07_04` sí presentan dependencias sucesivas entre resultados.

## 6. Relación con otras etapas del proyecto

**Análisis globales:**

`06_global_analyses/`

Proporcionan las matrices de similitud y distancia de nicho utilizadas en las comparaciones locales.

**Procesamiento local externo:**

Las matrices de presencia/ausencia y distancia de Jaccard locales proceden de un procesamiento previo de datos comunitarios de Noruega.

Este procesamiento todavía no está incorporado como una etapa reproducible dentro del repositorio.

**Figuras:**

Las figuras principales de esta etapa se generan directamente desde sus respectivos scripts.

No se mantienen copias independientes del mismo código gráfico en `08_figures/`.

## 7. Reproducibilidad y estado

Los cuatro scripts se han reorganizado para utilizar rutas relativas al proyecto mediante `here()`.

Se han conservado los procedimientos científicos, las escalas espaciales y las principales exportaciones de los análisis originales.

**Estado actual: scripts reorganizados, pero pendientes de ejecución integral y validación numérica frente a los resultados históricos.**

Antes de considerar reproducida esta etapa será necesario comprobar:

- La procedencia y construcción de las matrices locales de coocurrencia y presencia/ausencia.
- La correspondencia taxonómica entre especies de las matrices globales y locales.
- La alineación de las matrices utilizadas en los tests de Mantel.
- Los coeficientes y valores de significación de los análisis históricos.
- La definición de coocurrencia esperada y la interpretación de los residuos.
- La transformación de residuos a probabilidades esperadas de coocurrencia.
- El número de muestras y comunidades conservadas por escala.
- Los resultados de los modelos ambientales y su selección mediante AIC.
- La correspondencia entre las figuras originales y las regeneradas.

Los datos ambientales y comunitarios de gran tamaño se mantienen fuera del repositorio Git por el momento.

La reorganización de los scripts no implica que sus resultados hayan sido reproducidos o certificados numéricamente.