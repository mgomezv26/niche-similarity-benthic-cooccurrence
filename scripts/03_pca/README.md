# 03 — PCA6

Script incluido: 11_PCA_REALM.R, procedente de Niche_bentic_species.

Finalidad: documentar la PCA ambiental utilizada para el espacio de nicho.

Entradas: grid_realms_0_1_env_clean.gpkg y las variables ambientales originales seleccionadas. Salidas previstas: cargas, diagnósticos y grid_env_realm_with_PCA6_axes.gpkg.

Decisión científica mantenida: PC1–PC6, aproximadamente el 89,96 % de la varianza. El criterio Broken Stick se complementa con la varianza explicada acumulada; no se exige que los seis ejes superen individualmente Broken Stick.

La frase del manuscrito «The number of retained axes was selected using the Broken Stick criterion, complemented by the cumulative percentage of explained variance.» es correcta y no requiere modificación. El recuerdo de la investigadora de que posiblemente solo PC1 y PC6 superaron Broken Stick no está confirmado: solo podrá precisarse consultando resultados originales, sin recalcular la PCA ni cambiar los seis ejes.

Estado: código metodológico, no ejecutado ni certificado desde cero. Se mantiene incluso el carácter aislado al inicio y las dependencias/objetos implícitos señalados en la auditoría. No se han corregido sintaxis, estandarización, selección de variables ni número de componentes. La ruta privada se ha sustituido por un marcador.

El futuro flujo automatizado utilizará la malla PCA6 definitiva depositada externamente. Cualquier corrección técnica del script deberá revisarse por separado y no habilita recalcular PCA ni hipervolúmenes.
