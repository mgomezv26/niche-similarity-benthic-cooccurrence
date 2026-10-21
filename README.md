# niche-similarity-benthic-cooccurrence

Archivo documental del código del estudio de similitud de nicho y coocurrencia de organismos bentónicos. Conserva 22 scripts científicos seleccionados, sus cálculos originales y los R Markdown completos, organizados en siete etapas.

**No se ofrece ejecución automatizada ni reproducción numérica verificada.** Los scripts mantienen sus operaciones de escritura y nombres originales; las rutas privadas y los campos de autenticación identificados se sanearon. Los marcadores `__CONFIGURE_PATH_*__` son intencionadamente inoperantes. No ejecutar las copias directamente sobre archivos originales.

| Etapa | Contenido documental |
| --- | --- |
| [01_data_acquisition](scripts/01_data_acquisition/README.md) | GBIF, OBIS y CMEMS |
| [02_data_processing](scripts/02_data_processing/README.md) | Ocurrencias, ambiente, cuadrículas, MEOW y presencia/ausencia local |
| [03_pca](scripts/03_pca/README.md) | Procedimiento PCA6 |
| [04_hypervolumes](scripts/04_hypervolumes/README.md) | Hipervolúmenes, solapamiento y Schoener D |
| [05_global_analyses](scripts/05_global_analyses/README.md) | Coocurrencia, Mantel y residuos; análisis estadístico con distancias genéticas externas |
| [06_local_analyses](scripts/06_local_analyses/README.md) | MAREANO: cuantiles, residuos, índice comunitario y ambiente; Mantel local con correspondencia editorial pendiente |
| [07_figures](scripts/07_figures/README.md) | Correspondencia con figuras, tablas y procedimientos externos |

Las etapas de adquisición, procesamiento, PCA e hipervolúmenes documentan trabajo ya realizado; no se reconstruyen ni recalculan productos originales. Se mantienen seis componentes PCA, seleccionados mediante Broken Stick complementado por la varianza acumulada explicada (aproximadamente 89,96 %), y el carácter relativo, no probabilístico calibrado, de `mean_expected_prob`.

Los análisis genéticos fueron realizados externamente por otra persona con software especializado. Los Rmd de Porifera y Cnidaria analizan estadísticamente residuos y matrices genéticas ya obtenidas; no generan esas distancias. La Figura 1 procede de QGIS y la Figura 4 incluye montaje en Affinity. No se inventan scripts para esos procedimientos.

`17_Phylogeny.R` y `17_ISA.R` permanecen excluidos. B0, B1, C y D se documentan separadamente como antecedentes; sus informes completos se recuperarán del ordenador del trabajo, sin volver a ejecutarlos. No se añaden análisis ni materiales suplementarios.

Los inventarios no son manifiestos públicos definitivos ni autorizaciones de redistribución. Datos, resultados y manuscrito no se publican automáticamente. Siguen pendientes la licencia del código, autoría/cita y revisión editorial final.

Consulte el [índice documental](docs/README.md), el [inventario de procedencia](docs/source_inventory.csv), el [registro de saneamiento](docs/sanitization_log.csv) y los [pendientes de publicación](docs/technical_pending.md).

La infraestructura experimental de ejecución fue retirada del árbol de trabajo tras redefinir el alcance; permanece en el historial de Git. El Rmd global recupera la copia documental saneada anterior a su adaptación.
