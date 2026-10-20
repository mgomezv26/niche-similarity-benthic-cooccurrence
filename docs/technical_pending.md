# Pendientes antes de adaptar o ejecutar

1. Aprobar las copias públicas y su saneamiento. Los marcadores __CONFIGURE_PATH_*__ son intencionadamente inoperantes y se numeran dentro de cada archivo; no constituyen rutas ya adaptadas.
2. Definir un manifiesto de productos externos definitivos: nombre, función, DOI/versión de Figshare, licencia, tamaño, SHA256 y destino de descarga. No se han transferido datos.
3. Acordar las rutas relativas de entradas y una carpeta de salidas nueva, con protección frente a sobrescrituras. Los scripts aún conservan nombres relativos, setwd y llamadas de escritura originales, incluidas opciones overwrite/delete.
4. Documentar los pasos QGIS y las entradas finales COI/MEGA. No se considera demostrado que el código histórico excluido genere esos productos.
5. Revisar solo problemas técnicos: sintaxis inicial de 11_PCA_REALM.R, bibliotecas/objetos implícitos, coincidencia de nombres de archivos entre etapas y configuración de directorios. No corregir filtros, estandarización ni métodos por este motivo. Las etapas 01–04 siguen siendo documentación de resultados científicos cerrados.
6. Fijar versiones y entorno después de revisar las dependencias observadas. Los comentarios de versión de Python son evidencia histórica, no versiones verificadas del equipo ni un archivo de bloqueo. No se instala ni actualiza nada en esta fase.
7. Definir la ejecución desde productos finales, sin volver a adquirir presencias ni reconstruir cuadrículas, PCA6 o hipervolúmenes. No existe todavía un runner ni se afirma reproducibilidad integral.
8. Seleccionar expresamente qué resultados de validación y qué implementación de contrastes se publicarán. Mantener la diferencia entre resultados originales y sensibilidades B1/D; no promover automáticamente sus resultados.
9. Confirmar la función publicada de scripts suplementarios, taxonómicos y filogenéticos pendientes antes de incorporarlos. El inventario conserva su función y ubicación, sin calificarlos definitivamente de innecesarios.
10. Acordar licencia del código y permisos/licencias de datos, metadatos de autores, cita y correspondencia final de figuras/tablas. El manuscrito no se modifica.

No se han autorizado en esta fase adaptaciones de lógica, ejecución de análisis, modificaciones del manuscrito ni commits/pushes.
