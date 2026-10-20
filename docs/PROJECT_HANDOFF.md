# Traspaso del proyecto

Fecha de revisión: 20 de octubre de 2026. Repositorio: `niche-similarity-benthic-cooccurrence`.

Este documento permite retomar el trabajo sin el historial de la conversación anterior. Se basa en la copia local del repositorio y en las instrucciones expresas de la investigadora para este traspaso. No reconstruye conversaciones, informes ni conclusiones ausentes.

## 1. Cómo interpretar el estado

- **Verificado en esta revisión:** observado directamente en archivos, estructura o comprobaciones de hashes de esta copia.
- **Antecedente documentado:** afirmación de los registros anteriores; no equivale a una nueva comprobación de sus originales ni de sus resultados.
- **Decisión confirmada:** restricción o criterio metodológico que debe mantenerse, confirmado por la investigadora y, cuando se indica, recogido también en los README.
- **Pendiente:** información o trabajo todavía necesario; su inclusión no autoriza ejecutarlo.

La revisión ha sido documental y estática. No se han ejecutado análisis científicos, renderizado Rmd, instalado paquetes ni consultado servicios científicos externos. La única incorporación de esta tarea es este documento; no se modifican otros archivos ni se realizan commits o pushes.

## 2. Estado verificado del repositorio

La raíz contiene `README.md`, `.gitignore`, `docs/` y `scripts/`, además de `.git/`. `scripts/` está organizado en siete etapas, cada una con README. Hay 22 archivos de código científico; la séptima etapa contiene únicamente su README.

| Etapa y fuente | Código incluido | Función documentada y límite actual |
| --- | ---: | --- |
| [01_data_acquisition](../scripts/01_data_acquisition/README.md) | 3 | Adquisición GBIF, OBIS y CMEMS. Documentación del procesamiento original cerrado; no volver a descargar ni filtrar. |
| [02_data_processing](../scripts/02_data_processing/README.md) | 7 | Ocurrencias, ambiente, armonización, cuadrículas, MEOW y presencia/ausencia MAREANO a 5, 40 y 400 m. Incluye dependencia de pasos manuales QGIS. |
| [03_pca](../scripts/03_pca/README.md) | 1 | `11_PCA_REALM.R`, seleccionado de `Niche_bentic_species`; documenta PCA6. No está certificado como ejecutable desde cero. |
| [04_hypervolumes](../scripts/04_hypervolumes/README.md) | 3 | Hipervolúmenes gaussianos, solapamiento y Schoener D. Procedimiento cerrado, sin reconstrucción autorizada. |
| [05_global_analyses](../scripts/05_global_analyses/README.md) | 4 | Coocurrencia, Mantel y residuos globales; relaciones con filogenia en Porifera y Cnidaria. Futura ejecución desde matrices finales fijas. |
| [06_local_analyses](../scripts/06_local_analyses/README.md) | 4 | Mantel local, observado–esperado, regresiones cuantílicas, residuos, índice comunitario y modelos ambientales. Copias pendientes de adaptación técnica. |
| [07_figures](../scripts/07_figures/README.md) | 0 | Localiza el código de figuras en los Rmd y scripts anteriores; no contiene una implementación independiente. |

Los Rmd reúnen cálculos y figuras. El README general describe esta entrega como primera implementación estructural pendiente de revisión, sin ejecución validada de las copias. No hay ejecutor general, entorno fijado ni licencia de publicación acordada. La presencia de los scripts no demuestra reproducibilidad integral.

### Inventario, saneamiento e integridad

El [inventario](source_inventory.csv) contiene 64 fuentes de cinco raíces lógicas: `07_GitHub`, `Niche_bentic_species`, `02_DATA_GENOVEVA`, `05_ENVIROMENTAL_VARIABLES` y `08_GRID_BASE`. Identifica procedencia relativa, función, selección y hashes.

| Estado del inventario | Archivos |
| --- | ---: |
| Copiados idénticos | 4 |
| Copiados con saneamiento de configuración | 18 |
| Históricos no copiados | 25 |
| Exploratorios no copiados | 5 |
| Procedencia no verificada, no copiados | 3 |
| Excluidos definitivamente del artículo final, no copiados | 2 |
| Función suplementaria no confirmada, no copiados | 4 |
| Duplicados no copiados | 2 |
| Configuración privada no copiada | 1 |
| **Total** | **64** |

**Verificado ahora:** los 22 archivos de destino existen y sus SHA256 coinciden con `sha256_copy` del inventario. Esta comprobación establece concordancia con el registro; no repite la comparación con las 64 fuentes originales.

El [registro de saneamiento](sanitization_log.csv) contiene 27 sustituciones: tres campos GBIF trasladados a variables de entorno (`GBIF_USER`, `GBIF_PWD`, `GBIF_EMAIL`) y 24 literales de rutas sustituidos por marcadores `__CONFIGURE_PATH_*__`. Todas las filas declaran `scientific_logic_changed=FALSE` y omiten el valor privado original. Los marcadores no son rutas configuradas y su numeración es local a cada archivo.

**Antecedente documentado:** [public_copy_review.md](public_copy_review.md) informa de revisión estática de los 22 scripts, conservación de Rmd completos y cambios limitados a configuración. [integrity_summary.csv](integrity_summary.csv), fechado `2026-10-20T11:56:37.7220509Z`, registra `PASS` para 64 fuentes sin cambios, 22 copias verificadas, cuatro copias idénticas, 18 con saneamiento, 159 archivos de validación sin cambios y un manuscrito sin cambios. Estos controles de integridad no validan resultados estadísticos ni la ejecución actual.

Las afirmaciones del informe previo sobre ausencia de `git add`, commits o pushes describen aquella fase. No se extrapolan a toda la historia posterior del repositorio. Al comenzar este traspaso, `git status --short` no mostraba cambios.

## 3. Decisiones metodológicas confirmadas

Estas decisiones son vinculantes para continuar el trabajo:

1. **Presencias y adquisición:** no modificar los datos de presencia, los filtros GBIF/OBIS, las reglas de presencia/ausencia ni el universo original de muestras.
2. **PCA:** conservar PC1–PC6. La selección utiliza Broken Stick complementado por la varianza acumulada explicada, aproximadamente **89,96 %**. No se exige que los seis ejes superen individualmente Broken Stick. El porcentaje es una decisión documentada y confirmada, no un valor recalculado en esta revisión.
3. **Hipervolúmenes:** no reconstruirlos ni cambiar parámetros. Conservar los productos originales y las métricas de nicho; la documentación de las etapas 01–04 no autoriza volver a ejecutar el procesamiento.
4. **Residuos locales:** mantener `residual = observed_local - expected_global`, donde `observed_local` es similitud Jaccard local y `expected_global` es HV Jaccard global. Conservar el cálculo original.
5. **Índice comunitario:** mantener `mean_expected_prob`, media comunitaria de los valores `(residual + 1) / 2`. Es un **índice relativo entre 0 y 1 cuando está definido**, no una probabilidad calibrada. Conservar su nombre no cambia esa interpretación.
6. **Validaciones:** mantener **B0, B1, C y D separadas**, sin sustituir los análisis originales ni incorporar automáticamente sus conclusiones al flujo principal.
7. **Resultados y manuscrito:** no modificar el manuscrito ni los resultados científicos.
8. **Exclusión definitiva del alcance:** `07_GitHub/17_Phylogeny.R` y `Niche_bentic_species/17_ISA.R` no forman parte del artículo científico final. Deben permanecer fuera del repositorio público, del flujo reproducible y del material suplementario; no copiarlos, adaptarlos ni ejecutarlos. Conservar sus originales intactos y sus referencias y hashes en el inventario. Esta exclusión no afecta a `Residuals_Porifera.Rmd` ni a `Residuals_Cnidaria.Rmd`: sus análisis de residuos filogenéticos sí forman parte del artículo y ambos scripts se conservan.

La lectura estática de `04_Analisis_residuos_locales.R` confirma que el índice usa parejas de especies presentes por comunidad y escala, busca cada pareja en ambos órdenes, toma el primer registro coincidente y calcula la media omitiendo valores ausentes. Para comunidades con menos de dos especies devuelve `NA`. Estos detalles se documentan para preservar la implementación; no se ha probado su comportamiento con datos.

El README local también establece conservar el escenario ambiental original con filas repetidas. El bloque exploratorio de selección de modelos se conserva como código histórico, sin convertirlo automáticamente en análisis principal. Los contrastes originales de pendientes e interacciones no deben presentarse como sustitutos de los contrastes completos referidos en C.

## 4. Validaciones previas: evidencia disponible y límites

**Verificado ahora:** no existe `results/validation/` en esta copia local; tampoco hay carpetas `data/`, `results/` o `figures/` en la raíz. Git no enumera archivos versionados bajo esas tres rutas. `.gitignore` excluye expresamente `/results/validation/`, y se comprobó que la regla se aplica.

Los README afirman que las validaciones permanecieron en su ubicación original y no se incorporaron a Git. Esto explica que no acompañen a la copia, pero no permite afirmar que se hayan perdido ni que estén ausentes de cualquier otra ubicación del ordenador. No se ha realizado una búsqueda externa de sus originales.

**Resultados comunicados de informes anteriores:** la investigadora ha proporcionado los siguientes resúmenes como antecedentes documentados. No se han verificado de nuevo en este ordenador ni se han ejecutado análisis en esta sesión. Los informes originales completos siguen sin estar disponibles en esta copia local.

| Validación | Alcance y resultados comunicados | Límites de interpretación |
| --- | --- | --- |
| **B0** | Reproducción del modelo ambiental original de 400 m: N = 1.437 filas, 1.422 comunidades únicas, R² = 0,0324519562 y R² ajustado = 0,0249831643. Salinidad fue el único predictor significativo a α = 0,05. | Resultado del escenario original comunicado; no reproducido en esta sesión. |
| **B1** | Sensibilidad eliminando la contribución adicional de 15 comunidades repetidas, sin eliminar registros originales: N = 1.422, R² = 0,0328081358 y R² ajustado = 0,0252626673. Salinidad continúa siendo el único predictor significativo. No se alteran las conclusiones ambientales a α = 0,05. | Sensibilidad separada de B0; no sustituye el modelo original ni modifica sus registros. |
| **C** | Reproducción de regresiones cuantílicas para τ = 0,75 y 0,90 con `observed_local ~ expected_global * scale`. Los contrastes con la matriz completa de covarianzas respaldaron pendientes positivas y la ordenación 400 m > 40 m > 5 m bajo la inferencia NID original. | La inferencia NID original no resuelve la dependencia entre pares de especies y escalas. |
| **D** | Sensibilidad con las 76 especies compartidas entre 5, 40 y 400 m. Se mantienen los patrones cualitativos de las correlaciones Mantel y la ordenación de pendientes cuantílicas. | Las magnitudes y los errores estándar cambian, especialmente a escalas finas. La composición taxonómica afecta a las estimaciones y su precisión. |

El registro de **159 archivos sin cambios** es agregado para B0/C, B1 y D: no aporta desglose por validación ni los informes científicos. Que B0 y C aparezcan agrupadas en ese registro no elimina su separación metodológica.

Los resúmenes anteriores amplían los antecedentes disponibles con los resultados comunicados por la investigadora; no sustituyen los informes completos, sus datos ni su implementación. **No se certifican de nuevo aquí sus resultados, significación, robustez ni conclusiones.** B0, B1, C y D se conservan como validaciones separadas, sin sustituir los análisis originales. Sigue pendiente recuperar los informes y archivos originales con su procedencia y hashes.

## 5. Restricciones de trabajo y publicación

- El encargo actual autoriza únicamente crear este documento y revisarlo. No ejecutar scripts ni análisis, instalar paquetes, adaptar rutas, modificar otros archivos, hacer commits o pushes.
- Los scripts conservan `setwd`, rutas relativas y escrituras originales, incluidas opciones de sobrescritura o borrado señaladas en los pendientes. No ejecutarlos completos con esa configuración.
- Mantener datos, resultados, validaciones completas, configuración privada y manuscrito fuera de la publicación automática. `.gitignore` es preventivo; cualquier selección pública necesita revisión expresa.
- No volver a introducir valores privados eliminados. La revisión estática previa no es una certificación universal de ausencia de secretos, especialmente para fuentes no copiadas.
- Mantener completos los Rmd y evitar duplicar su código en `07_figures`. No promover variantes históricas o exploratorias por su fecha o nombre.
- La futura automatización debe partir de productos científicos definitivos externos. No reconstruir presencias, cuadrículas, PCA6, hipervolúmenes o coocurrencia original para resolver problemas técnicos.

## 6. Tareas pendientes para una fase posterior

Derivadas de [technical_pending.md](technical_pending.md), de los README y de las lagunas de esta revisión. Ninguna se ejecuta mediante este traspaso.

| Tarea | Evidencia o definición necesaria para cerrarla |
| --- | --- |
| Revisar y aprobar las copias públicas y el saneamiento | Revisión de selección e inventario; sin alterar la lógica científica. |
| Recuperar documentación de B0, B1, C y D | Informes y archivos originales, identificados por validación, con procedencia y hashes; conservar resultados originales y sensibilidades diferenciados. |
| Definir productos externos definitivos | Manifiesto con nombre, función, DOI/versión de Figshare, licencia, tamaño, SHA256 y destino. La documentación actual no aporta un depósito configurado. |
| Acordar entradas y salidas seguras | Rutas relativas, correspondencia de nombres entre etapas y carpeta nueva de resultados con protección contra sobrescritura. |
| Documentar pasos manuales QGIS | Entradas y salidas con hash, versión, herramientas y parámetros, CRS, claves y tipo de unión, selección/reparación de geometrías y recuentos. |
| Acreditar las matrices COI/MEGA finales | Productos y procedencia para los análisis conservados de residuos filogenéticos de Porifera y Cnidaria. `17_Phylogeny.R` queda definitivamente excluido y no es candidato para completar esta trazabilidad. |
| Revisar problemas exclusivamente técnicos | Carácter inicial de `11_PCA_REALM.R`, sintaxis, bibliotecas y objetos implícitos, nombres y directorios. Cualquier corrección requiere revisión separada y no habilita recalcular PCA o hipervolúmenes. |
| Fijar entorno y versiones | Revisar `dependencies_observed.csv`; sus declaraciones y los comentarios históricos no acreditan versiones instaladas ni constituyen un archivo de bloqueo. |
| Diseñar ejecución desde productos finales | Definir el ejecutor y sus controles sin reabrir el procesamiento científico cerrado; no afirmar reproducibilidad integral antes de verificarla. |
| Seleccionar material de validación publicable | Decidir qué resultados e implementación de contrastes se incluirán, preservando B0, B1, C y D y sin sustituciones silenciosas. |
| Resolver scripts de función pendiente | Confirmar papel de las restantes variantes suplementarias y taxonómicas. `17_Phylogeny.R` y `17_ISA.R` tienen exclusión definitiva confirmada y no son candidatos para incorporar; sus originales se conservan. |
| Cerrar metadatos y correspondencia editorial | Licencia de código, permisos de datos, autores, cita y tabla salida–panel–figura/tabla del manuscrito, sin modificar este último. |

## 7. Lagunas que impiden un traspaso científico completo

Faltan en esta copia los informes originales de validación y sus resultados detallados, los productos científicos finales y su manifiesto, la trazabilidad completa de QGIS y COI/MEGA, y la correspondencia definitiva de figuras/tablas. No hay entorno fijado ni ejecución certificada de las copias.

El historial conversacional anterior no está disponible. Las decisiones no recogidas en los archivos consultados o en las instrucciones actuales no se presuponen. Los originales externos, el manuscrito y los 159 archivos de validación no se han vuelto a comprobar en este ordenador.

El siguiente paso queda pendiente de la revisión de este documento por la investigadora. Este traspaso no inicia ninguna de las tareas anteriores.
