# Documentación del código del estudio

**Idioma: [English](README.md) | [Español](README.es.md)**

- source_inventory.csv: 64 archivos fuente inventariados; 22 incorporados y 42 registrados sin copia.
- sanitization_log.csv: ubicación y clase de cada sustitución pública, sin valores privados originales.
- integrity_summary.csv: comprobaciones de integridad de fuentes, copias, validaciones y manuscrito.
- public_copy_review.md: alcance de la revisión y sus límites.
- technical_pending.md: pendientes vigentes de publicación y planificación técnica anterior identificada como histórica.
- dependencies_observed.csv: bibliotecas declaradas en los scripts, sin instalar ni fijar versiones.

Las rutas de origen se expresan desde las carpetas 07_GitHub, Niche_bentic_species, 02_DATA_GENOVEVA, 05_ENVIROMENTAL_VARIABLES y 08_GRID_BASE. Se omite deliberadamente la ubicación personal de esas carpetas. La combinación source_root + source_relative_path identifica cada origen, junto con su SHA256.

Estados copied_identical y copied_sanitized_configuration distinguen identidad binaria de saneamiento de configuración. Los estados not_copied_* documentan versiones anteriores, exploración, duplicados o procedencia pendiente; no implican que se haya demostrado que esos archivos carecen de valor científico.

Los scripts seleccionados son las fuentes principales identificadas para documentar el flujo. Esto no certifica por sí solo que cada archivo, ejecutado hoy desde cero, reconstruya todos los productos finales.

- [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md): decisiones científicas y antecedentes de validación; la actualización inicial distingue el alcance vigente del registro histórico.
- [data_product_inventory.md](data_product_inventory.md) y [data_product_inventory.csv](data_product_inventory.csv): 121 productos documentados con hashes y versiones, sin aprobación de redistribución.
- [Correspondencia con el manuscrito](../scripts/08_figures/README.es.md): tablas, figuras, análisis conservados y procedimientos externos.

El objetivo vigente es un archivo documental, sin prometer automatización ni reproducción numérica verificada. Los informes de revisión e integridad conservan sus fechas y evidencias históricas; no se convierten en certificaciones de ejecución. La infraestructura retirada sigue en el historial de Git. No se regeneran los inventarios ni se eliminan hashes o registros de saneamiento.
