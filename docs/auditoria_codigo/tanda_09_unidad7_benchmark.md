# Tanda 09 — unidad-7 (benchmark, medición repetida y verificaciones)

Herramienta: OpenCode (modo Plan, solo lectura)
Modelo: Crouton Alpha Free
Fecha y hora: 8/11/2026 23:52
Sesión: nueva
Archivos (8, 349 líneas):
- unidad-7/carga_benchmark_mongodb.js (67)
- unidad-7/consultas_benchmark_postgresql.sql (36)
- unidad-7/medicion_repetida_mongodb.js (62)
- unidad-7/medicion_repetida_postgresql.sql (36)
- unidad-7/verificar_benchmark_mongodb.js (35)
- unidad-7/verificar_benchmark_postgresql.sql (45)
- unidad-7/verificar_referencias_postgresql.sql (27)
- unidad-7/modelo/exportar_pedidos_benchmark.sql (41)
Prompt: ver prompt_base.md, más la línea final: «Devolvé exactamente el formato indicado: un id H-nn y una severidad por hallazgo, sin resumen por archivo.»
Estado: Corrida completa
Total de hallazgos devueltos: 11 (3 alta / 6 media / 2 baja)
Estado del repo: rama review-final, etiqueta pre-review (351ddb9)

---

H-01 Alta — unidad-7/carga_benchmark_mongodb.js:25-36 — crea productos_benchmark, colección de productos, contrariando la migración parcial (solo pedidos con embebidos) definida en unidad-7/AGENTS.md.
H-02 Alta — unidad-7/modelo/exportar_pedidos_benchmark.sql:31-40 — JOIN producto, JOIN categoria y JOIN usuario no filtran eliminado = FALSE, a diferencia de las agregaciones de PostgreSQL.
H-03 Alta — unidad-7/verificar_benchmark_postgresql.sql:30-32 — la verificación de referencias no excluye usuario/producto eliminados, mientras que las consultas de ventas sí los excluyen, con riesgo de no detectar referencias blandas rotas.
H-04 Media — unidad-7/carga_benchmark_mongodb.js:12-16 — no convierte a NumberInt los identificadores (_id, usuario_id, detalle_id, producto_id, categoria_id), dejando su tipo BSON ambiguo frente a las reglas del proyecto.
H-05 Media — unidad-7/consultas_benchmark_postgresql.sql:30 / unidad-7/verificar_benchmark_postgresql.sql:39 / unidad-7/carga_benchmark_mongodb.js:51 / unidad-7/verificar_benchmark_mongodb.js:11 — PostgreSQL usa round(sum(...), 2) y MongoDB suma Decimal128 sin redondeo, por lo que la comparación de totales y ventas no es exacta.
H-06 Media — unidad-7/medicion_repetida_postgresql.sql:10-24 — el producto por defecto es 1, mientras que unidad-7/medicion_repetida_mongodb.js:25-34 calcula el producto más frecuente, por lo que una ejecución sin parámetro mide un producto distinto.
H-07 Media — unidad-7/carga_benchmark_mongodb.js:44 / unidad-7/medicion_repetida_mongodb.js:34 — acceso a [0]._id sin comprobar colección vacía; con una muestra vacía el benchmark falla con error en tiempo de ejecución.
H-08 Media — unidad-7/modelo/exportar_pedidos_benchmark.sql:25-30 / unidad-7/carga_benchmark_mongodb.js:12 — un pedido sin líneas vigentes produce lineas: null en JSON y d.lineas.map falla, ya que se asume siempre un arreglo no nulo.
H-09 Media — unidad-7/medicion_repetida_postgresql.sql:16-24 / unidad-7/medicion_repetida_mongodb.js:51 — la comparación por producto es asimétrica: MongoDB excluye el cálculo del objetivo de la medición y PostgreSQL recibe producto como parámetro, por lo que la equivalencia depende de una entrada externa.
H-10 Baja — unidad-7/carga_benchmark_mongodb.js:25-36 / unidad-7/verificar_benchmark_mongodb.js:16-28 — productos_benchmark se construye desde los propios documentos cargados, por lo que el contraste $lookup frente a categoría embebida nunca puede perder líneas y resulta tautológico.
H-11 Baja — unidad-7/verificar_benchmark_mongodb.js:4-14 / unidad-7/medicion_repetida_mongodb.js:37-48 — las agregaciones de MongoDB operan sobre toda la colección sin acotar a LIMIT, mientras que PostgreSQL aplica LIMIT :limite; la comparación solo es válida si la colección contiene exactamente la muestra.

