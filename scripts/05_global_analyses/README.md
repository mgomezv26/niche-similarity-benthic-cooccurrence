# 05 — Análisis globales

| Script | Entradas | Salidas previstas |
| --- | --- | --- |
| 09_Calculate_CooccurrenceMatrix.R | Cuadrícula definitiva de especies | Coocurrencia y distancias Jaccard globales |
| 14_Mantel_test_clean.Rmd | Solapamiento HV, Schoener D, distancias entre centroides y coocurrencia | Matrices, Mantel, residuos, tablas y figuras globales |
| Residuals_Porifera.Rmd | Residuos globales, orden/taxonomía de especies y distancias genéticas COI | Comparaciones residuo–filogenia, tablas y figuras de Porifera |
| Residuals_Cnidaria.Rmd | Residuos globales, taxonomía y distancias COI | Comparaciones residuo–filogenia, tablas y figuras de Cnidaria |

Los tres Rmd se conservan completos, con cálculos y figuras juntos. No hay copias separadas del mismo código en 07_figures.

Estado: archivo documental, sin ejecución automatizada ni reproducción numérica certificada. El primer script documenta cómo se calculó la coocurrencia; no se reconstruye. El Rmd global se ha restaurado desde 0532fb7, conservando el saneamiento, sus 54 bloques, los tres Mantel de 1.000 permutaciones y la ausencia de set.seed(). Su SHA256 coincide con sha256_copy del inventario al conservar CRLF.

Se han sustituido rutas privadas, conservando nombres relativos y salidas originales. No se ha corregido el análisis ni sustituido resultados. Los análisis genéticos fueron realizados externamente por otra persona con software especializado; estos Rmd solo analizan estadísticamente residuos y matrices ya obtenidas. Las distancias COI finales son una entrada externa: el script histórico 17_Phylogeny.R no se incorpora como generador acreditado de esas matrices.

Los duplicados exactos de Residuals_* en subcarpetas originales solo se registran en el inventario.
