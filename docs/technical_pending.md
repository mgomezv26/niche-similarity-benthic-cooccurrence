# Pendientes antes de adaptar o ejecutar

1. Aprobar las copias públicas y su saneamiento. Los marcadores __CONFIGURE_PATH_*__ son intencionadamente inoperantes y se numeran dentro de cada archivo; no constituyen rutas ya adaptadas.
2. Definir un manifiesto de productos externos definitivos: nombre, función, DOI/versión de Figshare, licencia, tamaño, SHA256 y destino de descarga. No se han transferido datos.
3. Acordar las rutas relativas de entradas y una carpeta de salidas nueva, con protección frente a sobrescrituras. Los scripts aún conservan nombres relativos, setwd y llamadas de escritura originales, incluidas opciones overwrite/delete.
4. Documentar los pasos QGIS y la procedencia de las entradas finales COI/MEGA utilizadas por Residuals_Porifera.Rmd y Residuals_Cnidaria.Rmd, que se conservan como parte del artículo. 17_Phylogeny.R queda definitivamente excluido y no es candidato para completar esta trazabilidad.
5. Revisar solo problemas técnicos: sintaxis inicial de 11_PCA_REALM.R, bibliotecas/objetos implícitos, coincidencia de nombres de archivos entre etapas y configuración de directorios. No corregir filtros, estandarización ni métodos por este motivo. Las etapas 01–04 siguen siendo documentación de resultados científicos cerrados.
6. Fijar versiones y entorno después de revisar las dependencias observadas. Los comentarios de versión de Python son evidencia histórica, no versiones verificadas del equipo ni un archivo de bloqueo. No se instala ni actualiza nada en esta fase.
7. Definir la ejecución desde productos finales, sin volver a adquirir presencias ni reconstruir cuadrículas, PCA6 o hipervolúmenes. No existe todavía un runner ni se afirma reproducibilidad integral.
8. Seleccionar expresamente qué resultados de validación y qué implementación de contrastes se publicarán. Mantener la diferencia entre resultados originales y sensibilidades B1/D; no promover automáticamente sus resultados.
9. Confirmar la función publicada de los restantes scripts suplementarios y taxonómicos antes de incorporarlos. Exclusión definitiva confirmada por la investigadora: 17_Phylogeny.R y 17_ISA.R no forman parte del artículo final y deben permanecer fuera del repositorio público, del flujo reproducible y del material suplementario. No copiarlos, adaptarlos ni ejecutarlos; conservar sus originales intactos y sus referencias y hashes en el inventario. Esta exclusión no afecta a los análisis de residuos filogenéticos de Porifera y Cnidaria.
10. Acordar licencia del código y permisos/licencias de datos, metadatos de autores, cita y correspondencia final de figuras/tablas. El manuscrito no se modifica.

No se han autorizado en esta fase adaptaciones de lógica, ejecución de análisis, modificaciones del manuscrito ni commits/pushes.
