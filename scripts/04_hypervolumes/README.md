# 04 — Hipervolúmenes y métricas de nicho

| Script | Entradas | Salidas previstas |
| --- | --- | --- |
| 12_Hypervolume_realms_all_vars_gaussian.R | grid_env_realm_with_PCA6_axes.gpkg y grid_species_qgis_coords.gpkg | Hipervolúmenes gaussianos por especie, hv_list_all_species.RData y probabilidades |
| 13_Niche_overlap.R | Lista de hipervolúmenes | Volúmenes individuales, lista de especies y solapamiento por pareja |
| Calculate_D_Shoener.R | PCA6, cuadrícula de especies e hipervolúmenes originales | Productos intermedios y matrices/pares de Schoener D |

Estado: documentación del procedimiento original cerrado. No se han ejecutado ni se propone recalcular hipervolúmenes o métricas de nicho.

Las rutas privadas se han saneado; la estructura relativa y los parámetros científicos permanecen en el código. Algunos scripts contienen más de un bloque de cálculo. No hay todavía una selección automatizada de bloques ni un entorno fijado. Los productos definitivos deberán identificarse por hash y depósito externo antes de conectar los análisis posteriores.
