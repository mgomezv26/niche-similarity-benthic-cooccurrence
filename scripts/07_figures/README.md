# 07 — Figuras

Esta carpeta reserva la etapa de figuras. En esta fase no contiene scripts científicos independientes: los Rmd originales conservan íntegros sus cálculos y figuras en 05_global_analyses y 06_local_analyses.

| Producto | Ubicación del código o procedimiento |
| --- | --- |
| Figuras globales de relaciones y residuos | ../05_global_analyses/14_Mantel_test_clean.Rmd |
| Figura 4: gráficos residuo–filogenia | ../05_global_analyses/Residuals_Porifera.Rmd y Residuals_Cnidaria.Rmd; gráficos estadísticos exportados desde R |
| Figura 4: composición editorial final | Cuatro paneles combinados en Affinity, con ilustraciones de Porifera y Cnidaria añadidas allí |
| Figuras locales de comparación entre escalas y cuantiles | ../06_local_analyses/02_Mantel_Test_Local_Scale.Rmd y 03_expected_vs_observed_cooccurrence.Rmd |
| Resúmenes locales por comunidad | ../06_local_analyses/04_Analisis_residuos_locales.R |
| Modelos ambientales locales | ../06_local_analyses/00_Env_data_norway.R |
| Figura 1: cartografía del área de estudio | Captura definitiva obtenida en QGIS; no existe script R de su composición final |

Entradas: productos definitivos y resultados asociados a cada documento. Salidas: PNG y tablas con los nombres conservados dentro de los scripts.

Estado: no se han renderizado documentos ni generado figuras. Las procedencias de las figuras 1 y 4 están confirmadas por la investigadora. No reconstruir la captura QGIS ni crear un script artificial; no automatizar ni reproducir la composición Affinity sin autorización. La reproducción estadística de la Figura 4 termina en los gráficos exportados de R. Sigue pendiente identificar los archivos finales y sus hashes.

La referencia editorial definitiva del suplemento es la incluida al final de MS_Bentic_MG_13_7_2026_review.docx. El suplemento independiente es una versión anterior. La Tabla S1 aún no está elaborada: sus columnas no son un formato aprobado y no debe generarse todavía.

Las variantes 16_Hypervolume_Plots.Rmd no se copian. La posible incorporación de nuevos materiales suplementarios no está decidida; su existencia no justifica ampliar el suplemento definitivo. Permanecen localizables por origen y hash en docs/source_inventory.csv. No se crea variants/ ni se divide ningún Rmd.
