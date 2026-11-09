# Tanda 10 — unidad-8 (movil y postgresql)

Herramienta: OpenCode (modo Plan, solo lectura)
Modelo: Crouton Alpha Free
Fecha y hora: 8/11/2026 23:59
Sesión: nueva
Archivos (15, 570 líneas):
- unidad-8/movil/cargar_catalogo.sql (31)
- unidad-8/movil/casos_c2_c5_borradores.sql (51)
- unidad-8/movil/casos_c2_c6_resolucion.sql (34)
- unidad-8/movil/casos_f2_semaforo.sql (63)
- unidad-8/movil/pruebas_sqlite.sql (99)
- unidad-8/movil/schema_sqlite.sql (73)
- unidad-8/movil/semaforo.sql (70)
- unidad-8/movil/verificar_vistas_tablet.sql (37)
- unidad-8/postgresql/10_snapshot_catalogo.sql (18)
- unidad-8/postgresql/11_exportar_snapshot.sql (6)
- unidad-8/postgresql/verificar_hallazgos_3c.sql (37)
- unidad-8/postgresql/verificar_no_cambio.sql (11)
- unidad-8/postgresql/verificar_vista_snapshot.sql (34)
- unidad-8/postgresql/casos/c2_subir_precio.sql (3)
- unidad-8/postgresql/casos/c4_baja_logica.sql (3)
Prompt: ver prompt_base.md, más la línea final: «Devolvé exactamente el formato indicado: un id H-nn y una severidad por hallazgo, sin resumen por archivo.»
Estado: Corrida Completa
Total de hallazgos devueltos: 9 (0 alta / 3 media / 6 baja)
Estado del repo: rama review-final, etiqueta pre-review (351ddb9)

---

H-01 [Media] unidad-8/postgresql/10_snapshot_catalogo.sql:9 vs unidad-8/postgresql/verificar_vista_snapshot.sql:15 — (p.precio * 100)::INTEGER trunca (hacia cero) mientras la consulta manual usa round(p.precio * 100)::integer; ante una fracción de centavo difieren en 1 centavo y la vista queda mal aunque el conteo de la línea 28-30 hoy da 0.
H-02 [Baja] unidad-8/movil/cargar_catalogo.sql:11-25 + unidad-8/postgresql/10_snapshot_catalogo.sql:15 — el UPSERT nunca depura ids ausentes de la instantánea y la vista usa JOIN a categoria; un producto sin categoría o desaparecido de la vista queda como fantasma en producto_cache/v_catalogo_disponible (caso producto 99) con disponible_visto viejo.
H-03 [Media] unidad-8/postgresql/verificar_hallazgos_3c.sql:18-24 — el bloque H01 no captura EXCEPTION (a diferencia del bloque PRODUCTO REPETIDO:28-37); si el servidor se corrige y rechaza, el script aborta ahí y nunca llega a la segunda prueba, no sirve como regresión.
H-04 [Media] unidad-8/movil/casos_f2_semaforo.sql:49-50,57-58 — F2-4 y F2-5 insertan con INSERT ... SELECT sin validar filas insertadas; si el producto falta en producto_cache insertan 0 filas, el borrador queda vacío y el semáforo devuelve "borrador sin ítems" en vez del motivo buscado, ocultando el error de configuración.
H-05 [Baja] unidad-8/movil/casos_c2_c6_resolucion.sql:28-29, unidad-8/movil/casos_f2_semaforo.sql:63, unidad-8/movil/pruebas_sqlite.sql:73-95 — el patrón INSERT que debe fallar (C6, F2-6, C7.a/b/c) supone que sqlite3/DBeaver continúa y luego ejecuta ROLLBACK/SELECT; con stop-on-error el SELECT de comprobación nunca corre o la transacción queda abierta con el borrador parcial.
H-06 [Baja] unidad-8/postgresql/11_exportar_snapshot.sql:6 — \copy a ruta relativa 'movil/servidor_snapshot.csv' depende del cwd (raíz del repo) y SELECT * de la vista; corrido desde otro directorio escribe fuera de movil/ y puede dejar un CSV viejo que luego se importa como si fuera la instantánea.
H-07 [Baja] unidad-8/movil/semaforo.sql:45-46 — sum(substr(problema,1,1)='R'/'A') suma NULLs cuando problema es NULL; si todo el borrador es verde rojos y amarillos quedan NULL y solo caen al ELSE porque CASE trata NULL como falso, funciona por descarte de SUM y debería ser COUNT con COALESCE.
H-08 [Baja] unidad-8/postgresql/verificar_vista_snapshot.sql:28-34 — el chequeo de fracciones de centavo y la lista de columnas de information_schema solo informan; no asertan (falla/0 filas) que no haya truncamiento ni columnas sensibles, así que una columna extra de usuario/credencial en la vista pasaría como válida.
H-09 [Baja] unidad-8/movil/casos_c2_c5_borradores.sql:15,25,35,45-46 — precios literales hardcodeados (350000, 220000, 450000, 90000, 120000) en vez de leerlos de producto_cache como hace casos_f2_semaforo.sql; si el catálogo cargado no coincide, los borradores nacen ya con precio distinto y C2-C5 no tienen el motivo esperado.