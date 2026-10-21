# Pendientes antes de adaptar o ejecutar

## Cuestiones documentales cerradas

El traspaso está aprobado. El suplemento definitivo es el incluido al final de `MS_Bentic_MG_13_7_2026_review.docx`; el documento independiente es anterior. La Figura 1 es una captura QGIS, sin script R de composición. La Figura 4 combina gráficos exportados por los dos Rmd de residuos filogenéticos con montaje e ilustraciones añadidas en Affinity. No buscar generadores artificiales ni automatizar estas composiciones.

PCA6 conserva Broken Stick complementado por la varianza acumulada (aproximadamente 89,96 %), sin exigir que los seis ejes superen Broken Stick. La frase del manuscrito que describe ese criterio combinado es correcta. La posible superación por solo PC1 y PC6 es un recuerdo no confirmado; consultar resultados originales si se necesita precisarlo, sin recalcular. Las exclusiones definitivas de `17_Phylogeny.R` y `17_ISA.R` permanecen vigentes.

## Pendientes vigentes

1. Aprobar las copias públicas y su saneamiento. Los marcadores __CONFIGURE_PATH_*__ son intencionadamente inoperantes y se numeran dentro de cada archivo; no constituyen rutas ya adaptadas.
2. Definir un manifiesto de productos externos definitivos: nombre, función, DOI/versión de Figshare, licencia, tamaño, SHA256 y destino de descarga. No se han transferido datos.
3. Acordar las rutas relativas de entradas y una carpeta de salidas nueva, con protección frente a sobrescrituras. Los scripts aún conservan nombres relativos, setwd y llamadas de escritura originales, incluidas opciones overwrite/delete.
4. Documentar los pasos originales de preparación QGIS y la procedencia de las entradas finales COI/MEGA utilizadas por Residuals_Porifera.Rmd y Residuals_Cnidaria.Rmd. Identificar los archivos editoriales finales de las figuras 1 y 4 y sus hashes; su procedencia ya está resuelta. 17_Phylogeny.R queda definitivamente excluido y no es candidato para completar esta trazabilidad.
5. Revisar solo problemas técnicos: sintaxis inicial de 11_PCA_REALM.R, bibliotecas/objetos implícitos, coincidencia de nombres de archivos entre etapas y configuración de directorios. No corregir filtros, estandarización ni métodos por este motivo. Las etapas 01–04 siguen siendo documentación de resultados científicos cerrados.
6. Fijar versiones y entorno después de revisar las dependencias observadas. Los comentarios de versión de Python son evidencia histórica, no versiones verificadas del equipo ni un archivo de bloqueo. No se instala ni actualiza nada en esta fase.
7. Definir la ejecución desde productos finales, sin volver a adquirir presencias ni reconstruir cuadrículas, PCA6 o hipervolúmenes. No existe todavía un runner ni se afirma reproducibilidad integral.
8. Seleccionar expresamente qué resultados de validación y qué implementación de contrastes se publicarán. Mantener la diferencia entre resultados originales y sensibilidades B1/D; no promover automáticamente sus resultados.
9. Decidir expresamente si se incorporará nuevo material suplementario; no tratar las variantes históricas como incorporaciones pendientes obligatorias. 17_Phylogeny.R y 17_ISA.R no forman parte del artículo final ni del repositorio público, flujo reproducible o suplemento. No copiarlos, adaptarlos ni ejecutarlos; conservar originales, referencias y hashes. Los residuos filogenéticos de Porifera y Cnidaria se mantienen.
10. Acordar licencia del código y permisos/licencias de datos, metadatos de autores, cita y correspondencia final de figuras/tablas. El manuscrito no se modifica.

11. Definir la Tabla S1: todavía no está elaborada y sus columnas no están aprobadas. No generarla en esta fase.
12. Aprobar la propuesta técnica antes de modificar código: conservar como procedencia las etapas 01–04 y 09_Calculate_CooccurrenceMatrix.R (15 scripts); proponer adaptación desde productos finales de los tres Rmd globales restantes y los cuatro scripts locales (7 scripts). El papel editorial del Mantel local debe distinguirse de su posible ejecución como análisis auxiliar.

La fase actual solo actualiza documentación y planifica. No adaptar código, ejecutar modelos, Mantel o regresiones, generar figuras o tablas científicas, instalar dependencias, modificar manuscrito o suplementos ni realizar commits/pushes. La futura validación científica requerirá autorización de ejecución; aprobar una adaptación técnica no equivale a autorizar recalcular el procesamiento cerrado.
