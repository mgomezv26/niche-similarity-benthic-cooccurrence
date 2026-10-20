# 06 — Análisis locales MAREANO

| Script | Entradas | Salidas previstas |
| --- | --- | --- |
| 02_Mantel_Test_Local_Scale.Rmd | Jaccard local a 5, 40 y 400 m y tres matrices globales | Nueve Mantel, tablas y figura comparativa |
| 03_expected_vs_observed_cooccurrence.Rmd | Jaccard local y solapamiento global de nicho | Pares observado–esperado, regresiones cuantílicas y figuras |
| 04_Analisis_residuos_locales.R | Presencia/ausencia original y residuals_diff_obs_exp.csv | Resúmenes por comunidad, índice relativo y figura |
| 00_Env_data_norway.R | Índice por comunidad, información de muestras y env_full-001.tif | Conjuntos ambientales, modelos, resumen y figuras |

Los Rmd permanecen completos. El script ambiental conserva sus bloques completos, incluido el bloque exploratorio posterior de selección de modelos; su conservación no lo incorpora automáticamente al análisis principal.

Se mantiene la definición confirmada: observed_local es similitud Jaccard local; expected_global es HV Jaccard global; residual = observed_local - expected_global. La media de (residual + 1) / 2 por comunidad es un índice relativo entre 0 y 1. El nombre mean_expected_prob se conserva, sin interpretarlo como probabilidad calibrada.

Estado: copias sin ejecución, pendientes de rutas y controles técnicos. No ejecutar los archivos completos con sus salidas originales. Los resultados B0/C, B1 y D existentes permanecen intactos en results/validation y excluidos de Git; esta fase no los copia ni aplica automáticamente sus conclusiones al código principal.

Se conserva el escenario ambiental original con filas repetidas. Los contrastes de pendientes e interacciones del código original no se presentan como sustitutos de los contrastes completos ya validados en C. Antes de automatizar deberá decidirse cómo integrar esa validación sin alterar silenciosamente el análisis publicado.
