# Inventario de productos científicos: fase 1

Fecha: 2026-10-20. Estado: propuesta documental para revisión, no manifiesto público definitivo ni autorización de ejecución.

## Estado vigente tras la simplificación

Los dos inventarios de fase 1 están aprobados como documentación: se conservan sus 121 productos, referencias, hashes y comparaciones; no son manifiestos públicos definitivos. El CSV no se modifica. DP025 queda como referencia histórica provisional por su coincidencia con el HTML; DP027 permanece como alternativa, sin declararlo erróneo. La correspondencia editorial del Mantel local sigue pendiente.

Este documento conserva a continuación las observaciones y propuestas de la fase 1. La estructura de ejecución y los destinos de publicación propuestos entonces son **antecedentes no vigentes**, no compromisos: el objetivo actual es un archivo documental de código. No se aprueba la publicación de datos ni resultados, no se crean depósitos y no se adaptan nuevos scripts. Los informes B0/B1/C/D se recuperarán del ordenador del trabajo, sin volver a ejecutarlos. Véanse los [pendientes actuales](technical_pending.md).

## Alcance y evidencia de la fase 1

Se han localizado e inventariado **121 archivos**, con tamaño y SHA256 individual en [data_product_inventory.csv](data_product_inventory.csv). Suman 3.369.699.651 bytes contando copias y productos históricos; esta cifra no representa el tamaño de un futuro depósito. Los identificadores DP son referencias internas estables y tienen saltos deliberados.

Se consultaron los siete scripts seleccionados, `source_inventory.csv`, `PROJECT_HANDOFF.md`, la documentación de pendientes y el manuscrito definitivo `Niche_bentic_species/11_Manuscrito/MS_Bentic_MG_13_7_2026_review.docx` (DP113), incluido su suplemento integrado. Las búsquedas abarcaron las carpetas originales `Niche_bentic_species`, `02_DATA_GENOVEVA`, `07_GitHub` y `05_ENVIROMENTAL_VARIABLES`, además del repositorio para las validaciones. No se presupone acceso a otras copias.

Las rutas del CSV se reconstruyen como `<raíz original>/source_root/source_relative_path`. La raíz original local es la carpeta `02_NICHE_BENTHIC_ORGANISMS`; no se incluye la ruta personal absoluta en estos documentos. Las rutas de scripts son relativas al repositorio. `source_inventory.csv` mantiene la trazabilidad de los scripts originales y sus copias públicas.

Se leyeron tablas, XML de libros/documentos, objetos RDS y cabeceras de imágenes/raster. Se compararon productos guardados; no se ejecutaron los scripts científicos, Mantel, modelos, regresiones, reconstrucciones ni figuras. La lectura de un RDS no constituye reproducción del análisis que lo generó. La inspección del TIFF se limitó a metadatos y al flujo de bytes para SHA256, sin extraer valores ambientales.

**Identificado no significa aprobado como definitivo.** Las rutas explícitas de los scripts permiten identificar candidatos y dependencias; no demuestran por sí solas qué ejecución produjo el artículo. Los nombres y fechas no se utilizaron para resolver versiones. Un productor consignado por lectura del código es una relación documental, no prueba de ejecución histórica.

## Cómo interpretar el CSV

Cada fila corresponde a un archivo realmente localizado. Contiene función, procedencia, ruta esperada, coincidencia con esa ruta, tamaño, SHA256, formato, dimensiones, columnas/componentes, identificadores, metadatos estructurales, consumidores, productor propuesto, evidencia, copias idénticas y destino propuesto.

- `entrada_cientifica_candidata`: producto ya calculado que podría fijarse como entrada definitiva tras revisión.
- `intermedio_necesario`: salida de un paso que alimenta otro; puede ser también referencia original y entrada de una ejecución parcial.
- `referencia_original`: resultado guardado para comparación futura, sin validación científica nueva.
- `historico` / `historico_o_no_utilizado`: no requerido por los siete scripts seleccionados; no implica que deba eliminarse.
- `expected_path_match` y `consumption_evidence` distinguen una lectura literal de una copia alternativa del mismo producto. Un consumidor lógico no demuestra que leyera todas sus copias.
- `identical_bytes_to` documenta igualdad SHA256. `version_relation` registra comparaciones por nombre; las comparaciones entre formatos y nombres diferentes se explican abajo.
- `selection_status` permanece pendiente en todos los casos. `rights_status` no verifica derechos de redistribución.

Las dimensiones CSV cuentan filas de datos y columnas del archivo, incluida la columna de nombres de fila cuando existe. Los recuentos de identificadores no justifican eliminar registros. En XLSX se distinguen filas no vacías y rango declarado; en imágenes, dimensiones de cabecera, sin evaluación visual de su correspondencia con el manuscrito.

## Dependencias de los siete scripts

| Clave y script | Entradas científicas / intermedios consumidos | Salidas originales de referencia localizadas | Función |
|---|---|---|---|
| G — `scripts/05_global_analyses/14_Mantel_test_clean.Rmd` | Schoener por pares DP043; solapamiento/centroides DP044; Jaccard global RDS DP049 y formato largo DP050 | Matrices DP052–053, DP056–061; tabla DP066; residuos DP072–074; orden DP088; resúmenes DP064–065, DP084–087; figuras DP081–083, DP093–096; informe DP116 | Calcula Mantel global, residuos y tablas; genera figuras |
| P — `scripts/05_global_analyses/Residuals_Porifera.Rmd` | DP088, residuos DP073–074, taxonomía DP045, distancias MEGA DP109 | Matriz genética DP107–108; subconjuntos DP078/080; resultados DP076; figuras DP097/099/101; informe DP118 (copia DP120) | Análisis de residuos filogenéticos de Porifera y figuras |
| C — `scripts/05_global_analyses/Residuals_Cnidaria.Rmd` | DP088, residuos DP073–074, taxonomía DP045, distancias MEGA DP112 | Matriz genética DP110–111; subconjuntos DP077/079; resultados DP075; figuras DP098/100/102; informe DP117 (copia DP119) | Análisis de residuos filogenéticos de Cnidaria y figuras |
| L — `scripts/06_local_analyses/02_Mantel_Test_Local_Scale.Rmd` | Matrices globales CSV DP056/058/060 y Jaccard locales DP003–005 | Nueve Mantel DP025; alternativa DP027; figura DP016; informe DP121 | Calcula nueve Mantel locales y figura de resumen |
| Q — `scripts/06_local_analyses/03_expected_vs_observed_cooccurrence.Rmd` | DP058/060 y DP003–005; `expected_global` procede de Jaccard de hipervolúmenes, no de Schoener | Residuos locales DP026; figuras DP014–015/029/037–040; informe DP122 | Calcula relaciones observadas/esperadas, cuantiles y residuos; genera figuras |
| I — `scripts/06_local_analyses/04_Analisis_residuos_locales.R` | Presencia/ausencia DP006–008 y residuos DP026 | Índice comunitario DP023; resumen DP024; figura DP028 | Calcula índice comunitario y resúmenes; genera figura |
| E — `scripts/06_local_analyses/00_Env_data_norway.R` | TIFF DP034; índice DP023; información de muestras DP031–033 | Correlaciones ambientales DP036; resumen de modelos DP039; figuras DP012–013 | Extrae información ambiental, ajusta modelos y genera figuras |

Los siete scripts mezclan cálculo y visualización; las figuras guardadas no sustituyen sus entradas numéricas. Los HTML son referencias de ejecuciones anteriores, no entradas necesarias. DP123 (`results_local_scale.docx`) es otro documento de resultados localizado, sin certificar equivalencia con la versión final del artículo.

La ruta taxonómica declarada en L no equivale a una lectura efectiva. Q lee Schoener, pero esa lectura no convierte Schoener en el predictor del cálculo observado/esperado. `env_full_levels.rds` (DP035) acompaña al raster y no figura como lectura necesaria de E.

Se han localizado las entradas explícitas necesarias de los siete scripts. Esto no garantiza aún una ejecución reproducible: rutas, versiones, dependencias de software, selecciones de variables y correspondencia editorial requieren la fase posterior. No es necesario reconstruir PCA, ocurrencias ni hipervolúmenes para inventariar estas entradas.

## Estructura verificada de los productos principales

| Productos | Estructura observada | Implicación documental |
|---|---|---|
| DP043–044 | 10.585 pares cada uno; 3 y 9 columnas respectivamente | Productos de nicho ya calculados para el análisis global |
| DP049–053, DP056–061 | Matrices de 146 × 146; CSV cuadrados con una columna adicional de nombres | Conservar identificadores y orden; distinguir similitud y disimilitud conforme al código original |
| DP050 | 21.316 filas × 3 columnas | Formato completo de 146² posiciones; no confundir con 10.585 pares no ordenados |
| DP066 | 10.585 filas × 5 columnas | Tabla global guardada; alternativa XLSX DP067 |
| DP072–074 | Objetos RDS de tres componentes | Metadatos de componentes en CSV; conservar objetos originales como referencias |
| DP003 / DP004 / DP005 | Jaccard local: 77 / 96 / 95 especies para 400 / 40 / 5 m | Universos distintos por escala; no convertirlos automáticamente en el subconjunto de validación D |
| DP006 / DP007 / DP008 | Presencia/ausencia: 1.664 / 18.286 / 85.179 filas; 77 / 96 / 95 especies | Identificadores de fila únicos en cada archivo inspeccionado |
| DP026 | 11.951 filas × 7 columnas | Residuos por pares y escala; 97 identificadores de especies en la unión |
| DP023 | 38.807 filas × 7 columnas | Clave `(SampID, scale)` única; `SampID` aislado tiene 37.916 valores únicos |
| DP023 por escala | 25.871 filas a 5 m; 11.454 a 40 m; 1.482 a 400 m | Son filas del producto comunitario, no tamaños de las muestras finales del modelo |
| DP031 / DP032 / DP033 | Información de muestras: 1.960 / 28.572 / 271.894 filas × 11 columnas | `ID_400`: 1.934 valores únicos, 26 repeticiones adicionales; `ID_40`: todos únicos; `ID_5`: 271.887 únicos, 7 repeticiones adicionales. No se eliminaron ni unieron filas |
| DP034 | 14.436 × 10.985 píxeles, 130 bandas, float32; 200 × 200 m; EPSG:32633 | 3.203.418.451 bytes; nombres de bandas en metadatos del CSV; no se leyeron píxeles para análisis |
| DP041 / DP045 | Taxonomía: 146 especies en hoja principal; Porifera 20, Cnidaria 28 filas de datos | Cnidaria declara rango hasta fila 1.048.460, pero contiene 29 filas no vacías contando cabecera; el rango inflado no es número de especies |
| DP109 / DP112 | MEGA: 91 / 210 pares y 14 / 21 identificadores respectivamente | Matrices normalizadas y residuos filogenéticos de 14 × 14 y 21 × 21 |
| DP039 | Tres filas de resumen ambiental | A 400 m: N=1.437, R²=0,0324519562042724, R² ajustado=0,0249831642872528; coincide numéricamente con el antecedente B0 comunicado, sin reproducirlo |

Las repeticiones en la información de muestras no se equiparan a las 15 comunidades adicionales de B1: esa correspondencia requeriría examinar el conjunto efectivamente utilizado por el modelo. No se modificaron filtros, uniones ni registros.

## Versiones y comparaciones

### Nueve Mantel locales: dos resultados guardados

DP025 está en `01_outputs/Mantel_results/mantel_results_df.csv`; DP027 en `01_outputs/Mantel_resultsmantel_results_df.csv`, ambos bajo `02_DATA_GENOVEVA`. Tienen nueve filas y las mismas columnas, escalas, métricas, tamaños y coeficientes r. Difieren seis valores p:

| Escala | Métrica | p DP025 | p DP027 |
|---|---|---:|---:|
| 5 m | HV Jaccard | 0,0118 | 0,0138 |
| 5 m | Schoener | 0,1593 | 0,1545 |
| 40 m | HV Jaccard | 0,0100 | 0,0085 |
| 40 m | Schoener | 0,1075 | 0,1023 |
| 400 m | HV Jaccard | 0,0096 | 0,0115 |
| 400 m | Schoener | 0,0124 | 0,0131 |

Para centroides, p=0,0001 en las tres escalas en ambos archivos. El HTML DP121 reproduce los valores de DP025. Esta concordancia aporta trazabilidad, pero **no aprueba automáticamente DP025**. El script especifica 9.999 permutaciones; no se atribuye la diferencia a una causa no demostrada ni se ejecutaron nuevas permutaciones.

### Otras versiones

- Copias con SHA256 idéntico: DP030/033 (muestras 5 m), DP041/045 (taxonomía), DP042/044 (solapamiento), DP049/053 (Jaccard RDS), DP051/052 (CSV Jaccard), DP117/119 y DP118/120 (HTML filogenéticos). Las restantes coincidencias exactas, incluidas figuras, están en `identical_bytes_to`.
- Diez pares de matrices CSV/RDS guardadas tienen dimensiones y nombres de filas/columnas coincidentes. Las diferencias numéricas máximas son cero salvo redondeo de representación en Jaccard global (aproximadamente 5,6 × 10⁻¹⁶). No se regeneraron matrices.
- DP066/067 (tabla global CSV/XLSX): mismas dimensiones y cabecera; 14 celdas numéricas difieren en representación, máximo 8,9 × 10⁻¹⁶. Esto no demuestra cuál se utilizó para el artículo.
- DP104–106 son copias en `09_ISA`, fuera del flujo aprobado. Frente a DP051, DP106 conserva los identificadores pero difiere en 396 celdas, máximo aproximadamente 1,0 × 10⁻¹⁵. DP050/105 difieren además en cabecera. Se documentan como históricos; no se proponen como sustitutos ni se incorpora ISA.
- DP081/090 son figuras idénticas; DP103, del mismo nombre en otra carpeta, tiene bytes distintos. DP082/091 y DP083/092 también difieren. Se han comparado hashes, tamaños y cabeceras, no la equivalencia visual/científica de paneles. La selección editorial queda abierta.
- DP089/093 (figura global combinada) son idénticos pese a la carpeta obsoleta de una copia. La carpeta o la fecha no bastan para descartar o seleccionar una versión.
- DP001–002 pertenecen a un índice comunitario histórico con otro nombre de columna y distinto número de filas (DP001: 105.129). No se sustituyó DP023 con ese producto. No se estableció equivalencia numérica o metodológica entre ellos.
- DP009–011, DP017–022, DP046–048, DP054–055, DP062–063 y DP068–071 se conservan en el inventario como contexto o productos no consumidos por los siete scripts. Su presencia no amplía el alcance autorizado.

## Correspondencia de los nueve Mantel locales con el manuscrito

Se examinó el texto completo de Results, no solo las leyendas. Las menciones a Mantel identificadas allí corresponden al análisis global (Table 4 / Fig. 2, con referencia expresa a “global marine grid”) y a los residuos filogenéticos (Fig. 4). La sección local `Scaling relationships between global niche overlap and local community assembly`, incluida `Predicting local community assembly from global environmental niche overlap`, presenta las regresiones cuantílicas y remite a Table 6 / Fig. 5. **No se identificó un pasaje que exponga explícitamente los nueve Mantel locales.**

Esto es una limitación de correspondencia documental, no una conclusión de que estén fuera del estudio. Por decisión del autor se conservan como **análisis del estudio; clasificación como principales condicionada a confirmar su correspondencia textual; futura ejecución pendiente de revisión**. No se los clasifica como auxiliares por carecer de figura o tabla. Esta propuesta sustituye, para esta fase, cualquier consideración previa basada solo en la ausencia de un producto numerado.

La existencia de DP025/027 y DP121 acredita resultados guardados de esos análisis, pero no permite elegir la versión editorial. Se requiere que el autor identifique el pasaje correspondiente o confirme la versión de manuscrito aplicable; no se modificó el manuscrito.

## Disponibilidad, lagunas y límites

1. **Entradas explícitas:** localizadas para los siete scripts, con versiones pendientes de aprobación. `EnvironmentalDatacor_vars_sel.csv` (DP036) existe con el nombre concatenado generado por el código; no se inventó una dependencia llamada `cor_vars_sel.csv` en otra carpeta.
2. **B0/B1/C/D:** no se localizaron las carpetas completas ni sus informes originales de validación en las raíces examinadas. Los antecedentes del handoff siguen siendo resultados comunicados, no verificados de nuevo. DP039 es compatible con B0, pero no sustituye su informe. Los HTML originales DP116–122 no son esos informes de validación.
3. **Objetos de ajuste:** no se identificaron exportaciones separadas de los modelos cuantílicos y sus matrices completas de covarianzas ni de los modelos ambientales y el conjunto final unido utilizado por cada ajuste. El código mantiene objetos en memoria y no documenta para todos ellos una exportación independiente. Esto es una laguna de referencias guardadas, no prueba de una entrada obligatoria ausente.
4. **Procedencia externa:** falta acreditar de manera suficiente la preparación de las tablas de muestras MAREANO y las condiciones de redistribución del raster, de las tablas MAREANO y de las distancias genéticas/metadatos asociados. La disponibilidad local no es autorización de publicación.
5. **Correspondencia editorial:** faltan aprobación de la versión Mantel local y de figuras alternativas, así como trazabilidad final entre archivos y paneles editados. Fig. 1 procede de QGIS; Fig. 4 incluye montaje manual. No se pretende regenerar estos montajes con los siete scripts.
6. **Alcance:** no es un inventario exhaustivo de todos los insumos históricos, paquetes, archivos de edición o productos del estudio. No se reconstruyó la cadena anterior de ocurrencias/PCA/hipervolúmenes ni se resolvió aquí S1.

## Propuesta histórica de publicación y estructura segura (no vigente)

Propuesta sujeta a selección de versiones, revisión de contenido privado y derechos; no se ha preparado un depósito ni un manifiesto público definitivo.

| Destino propuesto | Contenido | Condiciones |
|---|---|---|
| GitHub | Estos inventarios, documentación, siete scripts tras futura adaptación; pequeños CSV de referencia seleccionados, por ejemplo DP024/025/039/075/076/084/085/088 | Aprobar versiones y derechos; no publicar rutas personales ni convertir estos candidatos en resultados recalculados |
| Figshare | Entradas científicas versionadas: productos de nicho, matrices globales/locales, presencia/ausencia, tablas de muestras, taxonomía y distancias genéticas; referencias RDS/CSV y figuras seleccionadas | Documentar fuentes/licencias y mantener hashes; evitar copias duplicadas; no publicar ISA o filogenia excluida |
| Figshare o fuente externa autorizada | Raster DP034 de 3,20 GB decimales | Confirmar redistribución; si no procede, documentar acceso a fuente autorizada y hash sin redistribuirlo |
| Archivo de trabajo privado | Copias históricas, variantes no seleccionadas, manuscrito y documentos de resultados; HTML originales hasta revisar contenido | No son parte automática del paquete público. Un HTML puede contener rutas y configuración privada |

Estructura futura sugerida, **no creada**:

```text
<almacén externo de solo lectura>/<versión aprobada>/
  inputs/global/       # nicho, Jaccard, taxonomía, distancias genéticas
  inputs/local/        # Jaccard local, presencia/ausencia, muestras
  inputs/environment/ # raster y metadatos autorizados
  reference/global/   # matrices intermedias, residuos, tablas e informes aprobados
  reference/local/    # Mantel, cuantiles, índice, resúmenes y figuras aprobados

<repositorio>/
  config/              # futura resolución de rutas externas
  docs/                # inventario y futura documentación de procedencia
  results/runs/<id>/    # nuevas salidas, fuera de Git salvo selección explícita
    global/
    local/
    figures/
    logs/
```

Las referencias originales permanecerían inmutables; las futuras ejecuciones escribirían en un directorio nuevo por ejecución. Los intermedios publicados se etiquetarían como referencias preexistentes o entradas de ejecución parcial, sin sobrescribirlos con cálculos nuevos. Habría que aprobar posteriormente la configuración y las exclusiones de Git; no se han implementado.

## Decisiones y revisión planteadas al cierre de la fase 1 (registro histórico)

Se respetan las decisiones de `PROJECT_HANDOFF.md`: no alterar presencias ni filtros GBIF/OBIS; no reconstruir hipervolúmenes ni cambiar parámetros; mantener seis componentes PCA seleccionados con Broken Stick y varianza acumulada aproximada de 89,96 %; preservar residuos locales e índice relativo `mean_expected_prob`; mantener B0/B1/C/D separados. No se modificaron manuscrito, datos ni resultados. `17_Phylogeny.R` y `17_ISA.R` permanecen excluidos y sus originales intactos; los residuos filogenéticos de Porifera/Cnidaria se conservan.

Prioridad propuesta entonces; las decisiones posteriores se recogen al inicio:

1. Confirmar el pasaje/versionado del manuscrito para los nueve Mantel locales y aprobar cuál de DP025/027 será referencia.
2. Aprobar el conjunto de entradas identificado por rutas explícitas y las representaciones canónicas CSV/RDS/XLSX, sin descartar originales.
3. Resolver figuras con hashes distintos y confirmar los archivos que corresponden a paneles finales.
4. Acreditar procedencia y redistribución de MAREANO, raster y distancias genéticas antes de decidir el contenido de Figshare.
5. Recuperar, si están disponibles en otro ordenador, los informes completos B0/B1/C/D y objetos de ajuste guardados; si no existen, documentar esa limitación sin inventar resultados.
6. Aprobar la estructura de entradas/referencias/salidas antes de adaptar scripts o crear el manifiesto público.

La fase termina con este inventario. No se autoriza ni se inicia la adaptación, ejecución o publicación.
