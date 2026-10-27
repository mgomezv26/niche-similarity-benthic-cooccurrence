# 07 — Correspondencia con el manuscrito

**Idioma: [English](README.md) | [Español](README.es.md)**

Índice documental; no contiene scripts independientes. Los Rmd conservan íntegros sus cálculos y figuras. Referencia editorial: `MS_Bentic_MG_13_7_2026_review.docx`, incluido el suplemento de su parte final; el suplemento independiente es anterior.

La correspondencia procede de la lectura del manuscrito y del código, sin ejecutar análisis ni verificar igualdad numérica. Identificar un bloque pertinente no certifica la selección de una versión editorial guardada.

## Productos del manuscrito

| Sección o producto | Código o procedimiento identificado | Alcance |
| --- | --- | --- |
| Adquisición y preparación; tabla 1 | [Etapa 01](../01_data_acquisition/README.es.md) y [etapa 02](../02_data_processing/README.es.md) | Procedencia y tratamiento de variables; tabla de fuentes como síntesis editorial |
| PCA; tabla 2 | [11_PCA_REALM.R](../04_pca/04_01_environmental_pca.R) | PCA, varianza y diagnósticos; decisión PCA6 conservada |
| Hipervolúmenes y métricas de nicho | [Etapa 04](../05_hypervolumes/README.es.md) | Procedimiento original, sin visualizaciones adicionales ajenas al artículo |
| Figura 1 | Preparación espacial en etapa 02; captura QGIS | Composición externa; no hay generador R de la figura final |
| Tabla 4; figuras 2–3 | [14_Mantel_test_clean.Rmd](../06_global_analyses/06_02_mantel_tests_and_residuals.Rmd) | Mantel global, relaciones y residuos |
| Tabla 5; figura 4 | [Residuals_Porifera.Rmd](../06_global_analyses/06_04_porifera_phylogenetic_residuals.Rmd) y [Residuals_Cnidaria.Rmd](../06_global_analyses/06_03_cnidaria_phylogenetic_residuals.Rmd) | Estadística sobre residuos y distancias genéticas externas; gráficos R y montaje Affinity |
| Tabla 6; figura 5 | [03_expected_vs_observed_cooccurrence.Rmd](../07_local_analyses/07_02_expected_vs_observed_cooccurrence.Rmd) | Cuantiles y gráficos por escala |
| Tabla 7; figura 6 | [03_expected_vs_observed_cooccurrence.Rmd](../07_local_analyses/07_02_expected_vs_observed_cooccurrence.Rmd) | Residuos locales y comparación entre escalas |
| Tabla 3; figura 7 | [04_Analisis_residuos_locales.R](../07_local_analyses/07_03_local_residual_analysis.R) | Recuentos de comunidades e índice relativo, no probabilidad calibrada |
| Tablas 8–9; figura 8 | [00_Env_data_norway.R](../07_local_analyses/07_04_norway_environmental_models.R) | Modelos ambientales originales, resúmenes y coeficientes |
| Tabla S2 | [06_Join_Harmonise_Enviromental_Variables.R](../02_data_processing/02_03_Join_Harmonise_Enviromental_Variables.R) | Bloque de reclasificación sedimentaria; presentación editorial |
| Figura S3; tabla S3 | [00_Env_data_norway.R](../07_local_analyses/07_04_norway_environmental_models.R) | Correlaciones ambientales y VIF |
| S1 | Esquema presente en el suplemento | Tabla aún no elaborada; columnas no aprobadas. No generar tabla ni código nuevo |

## Análisis conservados y antecedentes

- [02_Mantel_Test_Local_Scale.Rmd](../07_local_analyses/07_01_local_mantel_tests.Rmd) se conserva como **análisis del estudio con correspondencia editorial pendiente**. No se localizó un pasaje explícito de los nueve Mantel locales en los resultados revisados. No se presentan como publicados ni se reclasifican como auxiliares por carecer de figura o tabla. DP025 es referencia histórica provisional por coincidir con el HTML original; DP027 sigue como alternativa documentada, sin declararlo erróneo.
- Los bloques exploratorios originales se conservan sin atribuir automáticamente sus resultados al artículo. El bloque posterior de selección de modelos del script ambiental no se convierte en análisis principal.
- B0, B1, C y D permanecen separados. Sus resultados comunicados se conservan en el [traspaso](../../docs/PROJECT_HANDOFF.md); no sustituyen los originales ni se recalculan.

## Procedimientos externos y límites

Los análisis genéticos fueron realizados por otra persona mediante software especializado. Las matrices COI/MEGA son entradas ya obtenidas de los dos Rmd estadísticos. Sigue pendiente completar su atribución y procedencia documental con información acreditada, sin inventar código genético.

La Figura 1 es una captura QGIS. Los cuatro paneles de la Figura 4 se exportaron desde R y se combinaron en Affinity, donde se añadieron las ilustraciones. Estos pasos no se automatizan. Sigue pendiente identificar los archivos editoriales finales cuando existan copias alternativas.

`17_Phylogeny.R` y `17_ISA.R` permanecen excluidos. Las variantes `16_Hypervolume_Plots.Rmd` no se incorporan: sus referencias y hashes siguen en el [inventario de fuentes](../../docs/source_inventory.csv), sin ampliar el suplemento ni crear nuevos scripts científicos.
