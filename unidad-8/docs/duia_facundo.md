# Declaración de Uso de IA (DUIA) — Facundo Quiroga

**Integrante:** Facundo Quiroga
**Materia:** Base de Datos II (UTN) — Unidad 8, TP N.º 8
**Proyecto Integrador:** Food Store
**Alcance:** code review de los scripts con IA (3.c), verificación del entorno (H0) y revisión del semáforo (F2)
**Herramientas:** OpenCode, agente Plan (solo lectura). *Modelo y proveedor: dato pendiente de Facundo.*

> Texto de Facundo (PR #2) con correcciones de Mariano Chirino del 05/11/2026, marcadas con *[corregido]*.
> Esta declaración cubre únicamente lo que usó y decidió Facundo.

---

## 1. Registro del uso de IA

| Herramienta | Para qué se usó | Se aceptó / se descartó — por qué |
|---|---|---|
| OpenCode (agente Plan) | Revisar los scripts de la cursada y proponer hallazgos | **Aceptado, después de comprobarlo en la base:** H01 (`sp_crear_pedido` no mira la categoría eliminada) y R1 (producto repetido en `p_items`). **Descartado:** H36 (la IA dijo que habría un commit parcial en `pruebas_sqlite.sql`; el script da los mismos conteos antes y después de C7 y cada bloque termina en `ROLLBACK`) y H04 (un índice por `producto_id` no mejora nada con 13 filas y `conventions.md` no permite agregarlos). |

*Prompt, fecha y cantidad total de hallazgos propuestos por la IA: dato pendiente de Facundo (no consta por escrito).*

## 2. Análisis técnico: PostgreSQL y SQLite

1. **Tipado.** PostgreSQL controla los tipos desde su definición. SQLite usa *type affinity* por defecto; la directiva `STRICT` del esquema móvil
   (`schema_sqlite.sql`) hace que un texto en una columna entera se rechace en la tablet antes de sincronizar.
2. **Transacciones en el CLI.** En PostgreSQL, un error dentro de un bloque inhabilita lo siguiente hasta el `ROLLBACK`. En el CLI de SQLite, un error en una sentencia
   no aborta la transacción salvo con `-bail`. *[corregido]* Eso se pensó como riesgo en `pruebas_sqlite.sql` (hallazgo H36), pero se comprobó que el script no lo sufre:
   cada bloque de C7 termina en `ROLLBACK`.
3. **Claves foráneas.** En SQLite hay que activarlas con `PRAGMA foreign_keys = ON;` en cada conexión; sin eso, C7.b no daría error.

## 3. Evaluación del semáforo (F2)

- **Evaluación local.** El semáforo clasifica con la instantánea guardada (`producto_cache` y `snapshot_servidor`) sin conexión al servidor.
- **Casos borde.** La precedencia y los demás casos de borde (producto fuera de la instantánea, borrador sin ítems, producto no disponible, dos pendientes del mismo borrador) los ejecutó Mariano en `movil/casos_f2_semaforo.sql` (`evidencias/18` y `19`); no figuran logs de Facundo.
- **Precedencia.** El rojo gana sobre el amarillo. *[corregido]* Son rojos (`RECHAZADO`): producto inexistente, no disponible, dado de baja o sin stock suficiente.
  Es amarillo (`CONFLICTO`): un precio que cambió, **sin umbral** (cualquier diferencia cuenta). Verde: `SIMULADO_APROBADO`, que **no es una venta**.
- **Asimetría H01.** *[corregido]* La vista `v_snapshot_movil` exporta como lápida (`eliminado = t`) los productos de categorías eliminadas, así que la tablet los rechaza; el procedimiento
  `sp_crear_pedido` del servidor no mira la categoría y acepta el pedido. Es una inconsistencia entre piezas heredadas y se documenta, sin modificar el código heredado.

## 4. Conclusión personal

Usar un agente de IA acelera la lectura de muchos scripts, pero sus afirmaciones no valen hasta correrlas: de los hallazgos comprobados, dos eran ciertos y dos no se sostenían
(H36 era falso para este script; H04 era cierto pero irrelevante con este volumen). La verificación en el motor real es lo que separa un hallazgo de una suposición.

---

## Nota de revisión del equipo (Mariano Chirino, 05/11/2026)

- Se corrigió el nombre de la sigla (Declaración de Uso de IA) y los puntos marcados *[corregido]*. Se quitaron las afirmaciones sin respaldo del texto original
  (planes de ejecución y «pruebas unitarias» sobre cada hallazgo; solo H04 usó `EXPLAIN`).
- Quedan pendientes de Facundo los datos que solo él conoce: modelo y proveedor de OpenCode, prompt, fecha, total de hallazgos de la IA y qué salió de OpenCode y qué de otra fuente.
  Según lo que dejó escrito, no hay logs adjuntos de sus comprobaciones; las salidas que respaldan las decisiones son las de Mariano (`evidencias/15` a `17`).
