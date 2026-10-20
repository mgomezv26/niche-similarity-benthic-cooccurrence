# niche-similarity-benthic-cooccurrence

Código metodológico del estudio de similitud de nicho y coocurrencia de organismos bentónicos.

Esta es la primera implementación estructural, pendiente de revisión. Los scripts conservan sus nombres y su lógica científica; los R Markdown permanecen completos. Solo se han saneado valores de autenticación y rutas privadas. **No se han ejecutado análisis ni se ha validado la ejecución de estas copias.**

| Etapa | Contenido |
| --- | --- |
| [01_data_acquisition](scripts/01_data_acquisition/README.md) | GBIF, OBIS y CMEMS |
| [02_data_processing](scripts/02_data_processing/README.md) | Ocurrencias, ambiente, cuadrículas, MEOW y presencia/ausencia local |
| [03_pca](scripts/03_pca/README.md) | Procedimiento PCA6 |
| [04_hypervolumes](scripts/04_hypervolumes/README.md) | Hipervolúmenes, solapamiento y Schoener D |
| [05_global_analyses](scripts/05_global_analyses/README.md) | Coocurrencia, Mantel y residuos globales |
| [06_local_analyses](scripts/06_local_analyses/README.md) | MAREANO: Mantel, cuantiles, residuos y ambiente |
| [07_figures](scripts/07_figures/README.md) | Localización del código de figuras, sin separar los Rmd |

El futuro flujo automatizado partirá de los productos científicos definitivos depositados externamente. Su manifiesto, DOI de Figshare y rutas aún deben configurarse. Las etapas de adquisición, preparación, PCA e hipervolúmenes se incluyen como documentación del procesamiento original cerrado; su presencia no autoriza recalcularlo.

La decisión de conservar PC1–PC6, con aproximadamente el 89,96 % de la varianza, se mantiene: Broken Stick complementado por el porcentaje acumulado de varianza explicada.

Los datos y resultados originales no se han incorporado en esta fase. Las validaciones locales B0/C, B1 y D permanecen en su ubicación, excluidas de Git. Su publicación requerirá una selección expresa.

Véanse el [inventario de procedencia y hashes](docs/source_inventory.csv), el [informe de revisión](docs/public_copy_review.md) y los [pendientes técnicos](docs/technical_pending.md). No hay todavía un ejecutor general, un entorno fijado ni una licencia de publicación acordada.
