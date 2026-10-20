# Revisión de la primera implementación estructural

## Alcance

Se han seleccionado 22 scripts de las carpetas originales. Se han inventariado 64 fuentes R, Rmd, Python y notebooks en las cinco carpetas de procedencia; las 42 restantes no se copian. La clasificación indica versiones históricas, exploración, duplicados exactos, configuración privada o función publicada todavía no acreditada.

No se considera que la fecha más reciente demuestre por sí sola la procedencia científica definitiva. Se conserva la selección de la auditoría como código metodológico principal, con las limitaciones de ejecución documentadas por etapa.

## Integridad

- Cuatro copias son idénticas byte a byte al original, comprobado mediante SHA256.
- Dieciocho copias difieren exclusivamente por saneamiento de configuración. Se verifica su SHA256 frente al contenido público preparado en memoria, se conservan original y hash, y cada sustitución queda registrada.
- Se conservan UTF-8, finales de línea y, cuando existe, BOM. Los Rmd mantienen sus líneas y delimitadores de bloques; no se han separado ni eliminado cálculos o figuras.
- Se comprueba que no existen diferencias fuera de las líneas de saneamiento registradas. Las operaciones sustituyen únicamente literales de configuración o rutas.
- Se comparan los hashes de las 64 fuentes antes/después de la copia. Se comprueban también los 159 archivos preexistentes de B0/C, B1 y D y el manuscrito. Los recuentos y resultados están en integrity_summary.csv.

## Revisión de autenticación y privacidad

Los 22 scripts se han leído completos para revisión estática de autenticación, rutas, correos de configuración, URL autenticadas, claves privadas, cadenas sospechosas y llamadas de ejecución/escritura. Se han revisado sus bibliotecas y referencias de entrada/salida.

Las tres declaraciones de autenticación GBIF se sustituyen directamente en memoria por Sys.getenv para GBIF_USER, GBIF_PWD y GBIF_EMAIL. Esta precaución no presupone que todos los valores fuente fueran credenciales reales; no se publica ninguno de sus literales de configuración.

Se sustituyen 24 literales de rutas locales por marcadores __CONFIGURE_PATH_*__, incluidos ejemplos comentados. Las rutas absolutas originales no se incluyen en el inventario público ni en un registro de diferencias. Los orígenes se expresan mediante la carpeta fuente y la ruta relativa.

No se ha guardado una copia sin sanear dentro del repositorio. Las alertas de cadenas largas revisadas corresponden a 19 rutas relativas de datos; no se han identificado secretos adicionales en las copias públicas. Se mantiene la autoría científica de los documentos, que no es configuración privada.

BBDD_SQL.R y los notebooks/variantes permanecen fuera del repositorio público. Se registra su hash y finalidad; esta fase no certifica que esas fuentes no copiadas estén libres de información sensible.

Esta revisión estática no equivale a una certificación de ausencia universal de secretos. No se han probado credenciales ni contactado servicios externos.

## Protección de Git

.gitignore excluye validaciones completas, datos y formatos grandes, credenciales/configuración local, cachés, temporales y el borrador local del manuscrito. Las reglas son preventivas: no sustituyen una revisión expresa de cualquier archivo que se seleccione para publicación.

No se ha ejecutado git add, commit ni push. No se han ejecutado scripts científicos, renderizado Rmd ni instalado dependencias. No se han movido o modificado fuentes, datos, resultados o manuscrito.

Las copias son revisables en Git, pero no están preparadas en el índice. La ejecución y la adaptación de rutas permanecen pendientes de autorización.
