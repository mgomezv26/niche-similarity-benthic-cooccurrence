# 02 — Procesamiento de datos

Finalidad: documentar la combinación de ocurrencias, preparación ambiental, cuadrícula, asignación MEOW y presencia/ausencia MAREANO.

| Script | Entradas | Salidas previstas |
| --- | --- | --- |
| 03_Ocurrence_Data_OBIS_GBIF.R | CSV GBIF/OBIS procesados, libro de especies, equivalencias taxonómicas | combine_data_drop_duplicates.csv y Data_Occurrence_period_2000_2020.csv |
| Enviromental_Variables.R | Capas Bio-ORACLE de los períodos originales y seabed_lithology_v1.nc | Promedios ambientales, seafloor_lithology_dummy.tif y litología |
| Analisis_correlacion.R | Extracciones ambientales y clorofila a las profundidades originales | Diagnósticos y mapas de correlación |
| 06_Join_Harmonise_Enviromental_Variables.R | Rásteres ambientales y litología | Pila armonizada y nombres de capas |
| 07_Create_Grid.py | Base terrestre y capas originales | Cuadrículas global, oceánica y septentrional |
| Assign_MEOW_realms_to_grid.R | Cuadrícula oceánica, MEOW, ambiente y ocurrencias | Cuadrícula ambiental de reinos y grid_species_qgis_coords.gpkg |
| 01_species_data_cooccur.R | species_densities.csv a 5, 40 y 400 m; lista taxonómica global | presence_absence_*.csv, jaccard_distance_*.csv, shared_samples_*.csv |

Estado: documentación del procesamiento original; no se han regenerado matrices, presencias ni cuadrículas. Las rutas privadas se sustituyen por marcadores __CONFIGURE_PATH_*__, como saneamiento documental, sin configurar un flujo ejecutable.

El script espacial utiliza productos intermedios de QGIS y no constituye un flujo íntegramente automatizado. Para completar la procedencia documental se necesita una ficha de cada paso manual: entradas con hash, versión de QGIS, herramienta y parámetros, CRS, claves/tipo de unión, selección o reparación de geometrías, recuentos y salida con hash. No se inventan aquí parámetros manuales que no estén acreditados.

Los scripts mixtos se conservan completos, incluidos diagnósticos y figuras. Se mantienen las reglas originales de presencia/ausencia y el universo original de muestras; esta fase no ejecuta la sensibilidad taxonómica.
