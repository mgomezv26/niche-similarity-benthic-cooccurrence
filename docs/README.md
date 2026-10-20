# Procedencia y estado de esta implementación

- source_inventory.csv: 64 archivos fuente inventariados; 22 incorporados y 42 registrados sin copia.
- sanitization_log.csv: ubicación y clase de cada sustitución pública, sin valores privados originales.
- integrity_summary.csv: comprobaciones de integridad de fuentes, copias, validaciones y manuscrito.
- public_copy_review.md: alcance de la revisión y sus límites.
- technical_pending.md: decisiones antes de adaptar rutas o ejecutar.
- dependencies_observed.csv: bibliotecas declaradas en los scripts, sin instalar ni fijar versiones.

Las rutas de origen se expresan desde las carpetas 07_GitHub, Niche_bentic_species, 02_DATA_GENOVEVA, 05_ENVIROMENTAL_VARIABLES y 08_GRID_BASE. Se omite deliberadamente la ubicación personal de esas carpetas. La combinación source_root + source_relative_path identifica cada origen, junto con su SHA256.

Estados copied_identical y copied_sanitized_configuration distinguen identidad binaria de saneamiento de configuración. Los estados not_copied_* documentan versiones anteriores, exploración, duplicados o procedencia pendiente; no implican que se haya demostrado que esos archivos carecen de valor científico.

Los scripts seleccionados son las fuentes principales identificadas para documentar el flujo. Esto no certifica por sí solo que cada archivo, ejecutado hoy desde cero, reconstruya todos los productos finales.
