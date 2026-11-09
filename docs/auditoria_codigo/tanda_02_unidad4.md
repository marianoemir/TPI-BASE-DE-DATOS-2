# Tanda 02 — unidad-4 (scripts de FNBC y desnormalización)

Herramienta: OpenCode (modo Plan, solo lectura)
Modelo: Croutou Alpha Free
Fecha y hora: 8/11/2026, 23:01
Archivos (2):
- unidad-4/tp_fnbc_control_lote.sql
- unidad-4/tp_desnormalizacion_top_categorias.sql
Prompt: ver prompt_base.md (solo cambia la lista de archivos)
Estado: Corrida completa
Total de hallazgos devueltos: 16 (1 alta / 9 media / 6 baja)
Estado del repo: rama review-final, etiqueta pre-review (351ddb9)

---

Revisión en modo solo lectura, sin ejecutar ni modificar nada — eso es lo que pediste. No afirmo haber probado nada.

### `unidad-4/tp_fnbc_control_lote.sql`

**H-01 — unidad-4/tp_fnbc_control_lote.sql:25 — `DELETE FROM usuario` hard delete, contra Regla dura 2. Severidad: media**

```sql
DELETE FROM usuario WHERE id IN (801, 802, 803);
```

Agencia: AGENTS.md dice nunca `DELETE`, siempre `UPDATE ... SET eliminado = TRUE`. Acá el `DELETE` es limpieza de demo, pero es físicamente borrar usuarios de `template`, y si algún `pedido` o `control_lote_almacen` los referencia, el FK lo bloquea o queda inconsistente. Además el orden de los `DROP` previos (líneas 19-24) deja a `usuario` solo — si `usuario` tuviera `pedido` (de `data.sql`) referenciándolo, el `DELETE` fallaría.

Cómo corregir: usar `UPDATE usuario SET eliminado = TRUE ...`, o documentar que ese `DELETE` es solo para usuarios de prueba de `copia_fnbc` y no se aplica a usuarios reales.

**H-02 — unidad-4/tp_fnbc_control_lote.sql:49-64 — `OVERRIDING SYSTEM VALUE` no avanza la sequence. Severidad: media**

Las tablas usan `GENERATED ALWAYS AS IDENTITY` (líneas 40, 45) y se insertan IDs explícitos `501-503`, `30-32`, `801-803`. Según documentación, `OVERRIDING` no mueve la sequence — tras esto, un `INSERT` posterior sin ID generaría `1`, `2`, etc., lo que tardeo o temprano puede colisionar con `30` o `501`. No ejecuté para verificar si `setval` se recupera solo; por lectura, queda desincronizado.

Cómo corregir: tras los `INSERT ... OVERRIDING`, hacer `SELECT setval('lote_id_seq', (SELECT MAX(id) FROM lote));` y lo mismo para `deposito` y `usuario`, o usar `BY DEFAULT` en vez de `ALWAYS`.

**H-03 — unidad-4/tp_fnbc_control_lote.sql:41, 47 — `codigo` / `nombre` sin `UNIQUE`. Severidad: baja**

`lote.codigo` y `deposito.nombre` admiten duplicados. Si el negocio los considera únicos, nada lo impide.

Cómo corregir: `UNIQUE` o `CHECK (btrim(codigo) <> '')` si corresponde, según enunciado.

**H-04 — unidad-4/tp_fnbc_control_lote.sql:67-72 — FK sin índice ni acción referencial explícita. Severidad: baja**

El FK `responsable_control_id` no tiene índice, y ninguna FK declara `ON DELETE / ON UPDATE`. En PostgreSQL, los FK no se indexan solos. Los `JOIN` por `responsable_control_id` tendrán que secuenciar.

Cómo corregir: `CREATE INDEX ON control_lote_almacen(responsable_control_id);` y explicitar `ON DELETE RESTRICT`.

**H-05 — unidad-4/tp_fnbc_control_lote.sql:62-64 — contraseñas de ejemplo en claro como `hash_resp801`. Severidad: media**

`'hash_resp801'` no es un hash real. Crea un patrón que luego se copió en `data.sql`/`queries.sql` del proyecto. AGENTS.md no prohíbe el valor del seed, pero normaliza guardar contraseñas débiles.

Cómo corregir: generar con `pgcrypto`/`bcrypt` real, o marcar explícitamente "solo seed de desarrollo, no usar en prod".

**H-06 — unidad-4/tp_fnbc_control_lote.sql:159-176, 283-292, 303-309 — pruebas `BEGIN…ROLLBACK` y `down` comentadas con `/* */`. Severidad: baja**

El archivo dice "Prueba ejecutable" pero está todo dentro de `/* ... */`. Al correr el archivo completo, `CAPTURA 3`, `CAPTURA 9` y el bloque de reversión no se ejecutan. Hay que descomentar a mano, y pgAdmin solo muestra la última sentencia, tal como avisa la cabecera (líneas 10-12).

Cómo corregir: dejar los bloques fuera del comentario de bloque y avisar "ejecutar seleccionado", o separarlos en secciones numeradas distintas del script principal.

**H-07 — unidad-4/tp_fnbc_control_lote.sql:227-230 — `NATURAL JOIN` frágil. Severidad: baja**

```sql
FROM control_lote NATURAL JOIN responsable_deposito;
```

Hoy solo comparten `responsable_control_id`, pero `NATURAL JOIN` une por *todas* las columnas con igual nombre. Si agregan una columna igual en ambas tablas, el join cambia silenciosamente.

Cómo corregir: `JOIN ... ON control_lote.responsable_control_id = responsable_deposito.responsable_control_id` explícito — igual que el resto del proyecto hace con `JOIN ... ON`.

**H-08 — unidad-4/tp_fnbc_control_lote.sql:198-202, 270-282 — la nueva PK no preserva F1 `{L,D} -> R`. Severidad: media**

El archivo lo reconoce en la sección 7: la PK nueva es `(lote_id, responsable_control_id)`, no `(lote_id, deposito_id)`. El ejemplo de líneas 285-286 es correcto: se puede insertar `(501, 803)` cuando `501` ya tiene `801` en el depósito `30`, y la vista devuelve dos responsables para `(lote 501, depósito 30)`. Esto viola F1 y el motor en el esquema descompuesto no lo rechaza.

Cómo corregir: un trigger que verifique que no exista ya otro `R` para el mismo `(L, D)` — es la limitación conocida de FNBC que el enunciado 4.2f espera discutir. El archivo lo menciona, pero no implementa el trigger; debería quedar como pendiente explícito en el entregable.

---

### `unidad-4/tp_desnormalizacion_top_categorias.sql`

**H-09 — tp_desnormalizacion_top_categorias.sql:25 — `UPDATE pedido SET fecha = CURRENT_DATE` destructivo e irreproducible. Severidad: alta**

```sql
UPDATE pedido SET fecha = CURRENT_DATE WHERE fecha = '2025-10-09';
```

Sin `BEGIN…ROLLBACK`, sin filtro `eliminado = FALSE`. Mueve 400 pedidos de historia real. El propio comentario (líneas 22-23) admite que "solo es reproducible el mismo día". Al día siguiente, `WHERE fecha='2025-10-09'` no encuentra nada y la medición cambia.

Cómo corregir: hacerlo en `copia_trabajo` dentro de una transacción de prueba, o guardar las fechas originales en una tabla temporal, y documentar que el `EXPLAIN` es válido solo ese día.

**H-10 — tp_desnormalizacion_top_categorias.sql:36-48 — baseline y MV sin filtro `pr.eliminado=FALSE` ni `c.eliminado=FALSE`. Severidad: media**

AGENTS Regla 6: el filtro `eliminado=FALSE` debe estar en *cada* tabla involucrada. El baseline (líneas 43-45) y la MV (líneas 122-123) filtran `dp` y `ped`, pero no `producto` ni `categoria`. Ventas de productos descontinuados o categorías dadas de baja siguen contando.

Cómo corregir: agregar `AND pr.eliminado = FALSE AND c.eliminado = FALSE` en ambas consultas.

**H-11 — tp_desnormalizacion_top_categorias.sql:46, 157 — `GROUP BY c.nombre` y `ORDER BY total_vendido DESC LIMIT 5` sin desempate. Severidad: baja**

Agrupar solo por `nombre` (MV agrupa por `id, nombre`) es frágil si `nombre` dejara de ser único. Y sin orden secundario, un empate en el puesto 5 elige un Top5 arbitrario — típico error de "top N" que da resultados no deterministas.

Cómo corregir: `GROUP BY c.id, c.nombre` en el baseline, y `ORDER BY total_vendido DESC, c.nombre` (o `categoria`) en ambas lecturas.

**H-12 — tp_desnormalizacion_top_categorias.sql:103-107 — cambio estructural sin `pg_dump`, contra protocolo. Severidad: media**

El comentario lo declara: "se ejecutó ... SIN respaldo previo con `pg_dump`. El protocolo (Paso 3) lo exige ... es un desvío declarado". AGENTS dice copia descartable se recrea desde `plantilla`, pero el protocolo exige respaldo antes de cambios estructurales sobre `copia_trabajo`. Decir que no es una "excepción" no lo vuelve conforme.

Cómo corregir: `pg_dump` antes del `CREATE MATERIALIZED VIEW`, o dejar constancia firmada de que el riesgo fue aceptado por el grupo — tal como lo hace, pero clasificado como desvío, no como excepción.

**H-13 — tp_desnormalizacion_top_categorias.sql:111-125 — la MV materializa todo el historial, no solo el día. Severidad: media**

El `WHERE` no filtra fecha: guarda todas las combinaciones `(categoría, fecha)` desde 2025. El reporte solo lee `fecha = CURRENT_DATE` (línea 161). El costo del `REFRESH` crece con todo el historial, no solo con el día.

Cómo corregir: o aceptar el costo (documentarlo), o particionar, o definir la MV solo para un rango (p. ej. `WHERE ped.fecha >= CURRENT_DATE - INTERVAL '30 days'`), si el negocio no necesita historia.

**H-14 — tp_desnormalizacion_top_categorias.sql:130-131, 139 — índice único correcto para `CONCURRENTLY`, pero orden cuestionable y sin aviso de transacción. Severidad: baja**

`UNIQUE (categoria_id, fecha)` es requisito para `REFRESH CONCURRENTLY`, y está bien creado. Pero la consulta filtra por `fecha = CURRENT_DATE` sin usar `categoria_id`, así que el orden `(fecha, categoria_id)` le serviría mejor al `EXPLAIN`. Además `REFRESH CONCURRENTLY` no puede correr dentro de `BEGIN…COMMIT`, y el archivo no lo advierte.

Cómo corregir: valorar `(fecha, categoria_id)`, y comentar que el `REFRESH` debe correr fuera de transacción (no usar `BEGIN` si se lo envuelve).

**H-15 — tp_desnormalizacion_top_categorias.sql:140-141, 165-177 — costo-beneficio no demostrado. Severidad: media**

Baseline: `6.546 ms` (línea 51). `REFRESH`: `6 s 800 ms` (línea 140). El ahorro es 6 ms por lectura; si el panel lee N veces entre refreshes, el neto es `N*6 ms - 6800 ms`, positivo solo si `N > 1000`. El archivo asume (líneas 93-97) que "lee muchas veces por minuto" sobre "escrituras un orden de magnitud menor", pero no lo mide.

Cómo corregir: agregar la medición de `N` reales del panel o la frecuencia del `pg_cron`, y el cálculo de punto de equilibrio, como pide AGENTS Regla 7 (nodo atacado + mejora esperada).

**H-16 — tp_desnormalizacion_top_categorias.sql:192-206 — auditoría incompleta, no detecta el bug de H-10. Severidad: media**

La reconciliación compara solo `total_vendido IS DISTINCT FROM` (línea 206). Si `cantidad_pedidos` diverge pero el total coincide, no lo detecta. Peor: como el lado recalculado (`f`) usa los mismos filtros incompletos que la MV, H-10 pasa desapercibido en ambos lados y la auditoría da 0 filas igual.

Cómo corregir: comparar también `cantidad_pedidos`, y que la auditoría use los filtros "correctos" del negocio (con `pr`/`c` eliminados), no una copia de la consulta de la MV.

---

Conclusión: ambos archivos tienen hallazgos; ninguno está sin hallazgos.

