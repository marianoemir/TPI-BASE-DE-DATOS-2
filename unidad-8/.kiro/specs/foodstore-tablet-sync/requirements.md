# Requirements Document

Food Store · Base de la tablet y sincronización simulada

## Introduction

El food truck opera en ferias sin señal. La tablet lleva una base **SQLite** con una copia local del catálogo
y permite armar borradores de pedido sin conexión. Cuando se recupera la señal, cada borrador se envía como
solicitud a una cola de sincronización; un semáforo local la compara contra la última instantánea del servidor
y decide si la solicitud puede avanzar (`SIMULADO_APROBADO`), tiene un conflicto de precio (`CONFLICTO`) o
debe rechazarse (`RECHAZADO`).

**PostgreSQL es la única autoridad en precio, stock y ventas. La tablet solo consulta y propone.
`SIMULADO_APROBADO` no es una venta confirmada.**

---

## Glosario

- **Sistema**: la base de la tablet y su sincronización simulada (carga del catálogo desde la instantánea y semáforo).
- **Borrador**: pedido anotado en la tablet sin conexión, compuesto por `pedido_borrador` e `item_borrador`.
- **Solicitud**: fila en `cola_sync` que asocia un UUID único a un borrador y registra su resultado.
- **Instantánea**: copia del catálogo del servidor importada en `snapshot_servidor` (precio, stock, disponibilidad, lápida).
- **Catálogo local**: tabla `producto_cache` en SQLite; lo que ve el vendedor en pantalla.
- **Semáforo**: el script `semaforo.sql`, que evalúa las solicitudes `PENDIENTE` contra la instantánea. Rojo = rechazo, amarillo = conflicto de precio, verde = sin diferencias.
- **PENDIENTE**: estado inicial de toda solicitud, antes de ser evaluada por el semáforo.
- **CONFLICTO**: la solicitud fue evaluada y al menos un precio difiere entre el borrador y la instantánea.
- **RECHAZADO**: la solicitud fue evaluada y al menos un producto no puede cumplirse (stock, baja, no disponible o inexistencia), o el borrador no tiene ítems.
- **SIMULADO_APROBADO**: la solicitud fue evaluada y no hay conflictos ni rechazos; no constituye una venta.
- **UUID**: identificador único de 36 caracteres generado en la tablet para cada solicitud.
- **Lápida**: columna `eliminado = 1` en `producto_cache`; la fila se conserva pero el producto no se muestra.
- **Carpeta de trabajo**: la carpeta donde se generan y ejecutan todos los scripts de la tablet. Todas las rutas de esta spec son relativas a ella.

---

## Requisitos

### Requisito 1 — Conflicto de precio (C2)

**Historia de usuario:** Como vendedor, quiero que el sistema me avise cuando el precio del servidor cambió
desde que anoté el borrador, para que el cliente pueda confirmar el nuevo precio antes de continuar.

#### Criterios de aceptación

1. WHEN el precio registrado en un ítem del borrador (`precio_centavos_visto`) difiere del precio del mismo
   producto en la instantánea del servidor (`precio_centavos`), aunque sea en un solo centavo, THE Sistema SHALL
   marcar la solicitud como `CONFLICTO`, registrar en el campo `motivo` el nombre del producto, el precio
   registrado en el borrador y el precio actual del servidor, y mantener el estado `CONFLICTO` sin reevaluarlo
   ni modificarlo hasta que el cliente genere una nueva solicitud con UUID distinto.
2. IF la solicitud contiene más de un ítem con conflicto de precio, THEN THE Sistema SHALL registrar en el
   campo `motivo` todos los productos afectados, incluyendo el precio del borrador y el precio actual del
   servidor para cada uno, en una sola entrada de `CONFLICTO`.
3. WHEN el cliente genera una nueva solicitud con UUID distinto para el mismo borrador, THE Sistema SHALL
   evaluar esa solicitud nueva de forma completamente independiente, sin heredar ni considerar el estado ni
   el resultado de ninguna solicitud anterior en `CONFLICTO` asociada al mismo borrador.

*Se prueba con:* **C2**

---

### Requisito 2 — Stock insuficiente (C3)

**Historia de usuario:** Como vendedor, quiero que el sistema rechace automáticamente un pedido cuya cantidad
supera el stock disponible en el servidor, para no comprometer unidades que ya no existen.

#### Criterios de aceptación

1. WHEN la cantidad solicitada en un ítem del borrador es mayor que el stock del mismo producto en la
   instantánea del servidor, THE Sistema SHALL marcar la solicitud como `RECHAZADO` y registrar en `motivo`
   el nombre del producto, la cantidad pedida y el stock disponible en el momento de la verificación.
2. WHEN la solicitud es marcada como `RECHAZADO` por stock insuficiente, THE Sistema SHALL no modificar
   ningún registro en PostgreSQL ni decrementar el stock del catálogo local, dejando ambos en el estado
   previo a la solicitud.
3. WHEN una solicitud presenta a la vez stock insuficiente y conflicto de precio, THE Sistema SHALL asignar
   el estado `RECHAZADO` y no asignar el estado `CONFLICTO`, registrando en `motivo` la información de
   stock insuficiente del criterio 1.
4. IF el stock del producto en la instantánea del servidor es igual a cero, THEN THE Sistema SHALL marcar
   la solicitud como `RECHAZADO` y registrar en `motivo` el nombre del producto, la cantidad pedida (mayor
   que cero) y el stock disponible (cero).
5. WHEN la cantidad solicitada en todos los ítems del borrador es menor o igual al stock de cada producto
   en la instantánea del servidor, THE Sistema SHALL no marcar la solicitud como `RECHAZADO` por motivo de
   stock insuficiente.

*Se prueba con:* **C3**

---

### Requisito 3 — Producto dado de baja, inexistente o no disponible (C4)

**Historia de usuario:** Como vendedor, quiero que el sistema rechace pedidos con productos que ya no están
activos en el servidor y actualice el catálogo local, para no ofrecer productos que no se pueden vender.

#### Criterios de aceptación

1. WHEN un producto del borrador tiene `eliminado = 't'` en la instantánea del servidor, THE Sistema SHALL
   marcar la solicitud como `RECHAZADO` y registrar en `motivo` el nombre del producto y la causa
   (`dado de baja`).
2. WHEN un producto del borrador no existe en la instantánea del servidor, THE Sistema SHALL marcar la
   solicitud como `RECHAZADO` y registrar en `motivo` el identificador del producto y la causa
   (`no existe en el servidor`).
3. WHEN un producto del borrador tiene `disponible = 'f'` en la instantánea del servidor, THE Sistema SHALL
   marcar la solicitud como `RECHAZADO` y registrar en `motivo` el nombre del producto y la causa
   (`no disponible`).
4. WHEN se recarga `producto_cache` desde una instantánea en la que un producto tiene `eliminado = 't'`,
   THE Sistema SHALL guardar `eliminado = 1` en la fila correspondiente de `producto_cache`, conservando
   la fila (nunca DELETE), de modo que el producto deje de aparecer en `v_catalogo_disponible`.
5. IF un borrador contiene más de un producto afectado por las causas de los criterios 1, 2 o 3,
   THEN THE Sistema SHALL rechazar la solicitud completa y registrar en `motivo` todos los productos
   afectados con su causa individual.
6. WHEN una solicitud es rechazada por cualquiera de las causas de los criterios 1, 2 o 3, THE Sistema SHALL
   preservar sin modificación todos los demás campos de la solicitud (líneas, cantidades, precios) en el
   estado `RECHAZADO`.

*Se prueba con:* **C4**

---

### Requisito 4 — Reenvío de UUID duplicado (C6)

**Historia de usuario:** Como vendedor, quiero que el sistema ignore el reenvío accidental de una solicitud
ya registrada, para que su resultado no se sobrescriba ni se contabilice dos veces.

#### Criterios de aceptación

1. WHEN se intenta insertar en `cola_sync` una solicitud cuyo `solicitud_uuid` ya está registrado, THE Sistema
   SHALL rechazar la inserción por la clave primaria (`UNIQUE constraint failed: cola_sync.solicitud_uuid`)
   antes de que el semáforo intervenga.
2. WHEN se rechaza un reenvío de UUID duplicado, THE Sistema SHALL conservar sin modificación la fila original
   (`estado`, `motivo` y `evaluada_en`); por ejemplo, una solicitud ya `SIMULADO_APROBADO` sigue en ese estado
   con la misma `evaluada_en`.
3. WHEN el semáforo se ejecuta otra vez y no hay solicitudes en estado `PENDIENTE`, THE Sistema SHALL reportar
   `solicitudes_evaluadas = 0` y no modificar ninguna fila de `cola_sync`.
4. THE Sistema SHALL NOT usar `INSERT OR REPLACE` ni `ON CONFLICT DO UPDATE` para encolar solicitudes, porque
   sobrescribirían el resultado de una solicitud ya evaluada.

*Se prueba con:* **C6**

---

### Requisito 5 — Catálogo disponible sin conexión (C1)

**Historia de usuario:** Como vendedor, quiero ver el catálogo aunque no haya señal, para poder
tomar pedidos en la feria.

#### Criterios de aceptación

1. WHEN el vendedor consulta `v_catalogo_disponible` sin conexión al servidor, THE Sistema SHALL
   devolver solo los productos de `producto_cache` con `eliminado = 0` y `disponible_visto = 1`,
   leyendo únicamente el archivo SQLite de la tablet.
2. THE Sistema SHALL mostrar el precio en `v_catalogo_disponible` como `precio_centavos / 100.0`.
3. WHEN la instantánea cargada tiene 16 productos y los productos 3 (dado de baja), 15 (no disponible)
   y 16 (no disponible y dado de baja) no se muestran, THE Sistema SHALL devolver 13 productos
   en `v_catalogo_disponible`.

*Se prueba con:* **C1** (`pruebas_sqlite.sql`)

---

### Requisito 6 — Esquema de la tablet (STRICT, centavos, restricciones y C7)

**Historia de usuario:** Como desarrollador, quiero que el esquema rechace datos inválidos en origen,
para que la tablet nunca guarde un borrador inconsistente.

#### Criterios de aceptación

1. THE Sistema SHALL crear las tablas `producto_cache`, `pedido_borrador`, `item_borrador`,
   `cola_sync` y `snapshot_servidor` con la opción `STRICT` (SQLite 3.37 o superior).
2. THE Sistema SHALL guardar todo importe como entero en centavos (`precio_centavos`,
   `precio_centavos_visto`) con `CHECK (>= 0)`, sin tipos decimales.
3. THE Sistema SHALL activar `PRAGMA foreign_keys = ON;` al comienzo de cada script, porque vale
   solo para la conexión en curso.
4. THE Sistema SHALL exigir que `pedido_borrador.id_local` y `cola_sync.solicitud_uuid` tengan
   exactamente 36 caracteres (`CHECK (length(...) = 36)`).
5. THE Sistema SHALL restringir `pedido_borrador.forma_pago` a `EFECTIVO`, `TARJETA` o `TRANSFERENCIA`.
6. THE Sistema SHALL exigir `item_borrador.cantidad > 0` y clave primaria `(id_local, producto_id)`.
7. WHEN se inserta un ítem con cantidad 0, THE Sistema SHALL rechazarlo por `CHECK`.
8. WHEN se inserta un ítem con un `producto_id` que no existe en `producto_cache`, THE Sistema SHALL
   rechazarlo por `FOREIGN KEY`.
9. WHEN se inserta un valor de tipo incorrecto en una columna `STRICT` (por ejemplo, texto no numérico
   en una columna `INTEGER`), THE Sistema SHALL rechazarlo.
10. WHEN alguna de las tres inserciones inválidas (criterios 7, 8 y 9) falla dentro de un bloque
    `BEGIN … ROLLBACK`, THE Sistema SHALL dejar sin cambios los conteos de borradores, ítems y cola.
11. THE Sistema SHALL definir `cola_sync.estado` con los valores `PENDIENTE`, `CONFLICTO`, `RECHAZADO`
    y `SIMULADO_APROBADO`, con `PENDIENTE` por defecto, y exigir `motivo` no nulo cuando el estado
    sea `CONFLICTO` o `RECHAZADO`.

*Se prueba con:* **C7** (`pruebas_sqlite.sql`)

---

### Requisito 7 — Una sola solicitud pendiente por borrador (F2-6)

**Historia de usuario:** Como vendedor, quiero poder reenviar un borrador después de resolver un
conflicto, pero nunca tener dos envíos pendientes del mismo borrador.

#### Criterios de aceptación

1. THE Sistema SHALL impedir, mediante el índice parcial único `ux_cola_una_pendiente` sobre
   `cola_sync(id_local) WHERE estado = 'PENDIENTE'`, que un mismo borrador tenga dos solicitudes
   `PENDIENTE` a la vez.
2. WHEN la solicitud anterior de un borrador ya no está `PENDIENTE`, THE Sistema SHALL permitir
   encolar una nueva solicitud con UUID distinto para ese mismo borrador.
3. THE Sistema SHALL NOT definir un `UNIQUE` simple sobre `cola_sync.id_local`, porque impediría
   reenviar un borrador tras un `CONFLICTO`.

*Se prueba con:* **F2-6**

---

### Requisito 8 — Instantánea y recarga del catálogo

**Historia de usuario:** Como vendedor, quiero que el catálogo se actualice con los datos del
servidor sin perder los productos que mis borradores todavía usan.

#### Criterios de aceptación

1. THE Sistema SHALL importar la instantánea (`servidor_snapshot.csv`) a `snapshot_servidor`, que se
   vacía y se vuelve a llenar en cada instantánea nueva; los booleanos llegan como `t` / `f`.
2. THE Sistema SHALL rechazar en `snapshot_servidor` una fila con `precio_centavos` o `stock`
   negativos, y con `disponible` o `eliminado` distintos de `t` / `f`.
3. WHEN se recarga `producto_cache` desde `snapshot_servidor`, THE Sistema SHALL usar
   `INSERT … ON CONFLICT (producto_id) DO UPDATE` y SHALL NOT usar `INSERT OR REPLACE`, para conservar las
   filas referenciadas por claves foráneas de borradores.
4. WHEN la instantánea trae `disponible = 't'`, THE Sistema SHALL guardar `disponible_visto = 1`;
   WHEN trae `eliminado = 't'`, THE Sistema SHALL guardar `eliminado = 1` (lápida).
5. THE Sistema SHALL conservar `capturado_en` de cada fila para saber de qué instantánea proviene.
6. THE Sistema SHALL NOT escribir en PostgreSQL en ningún momento de la carga: la tablet solo lee.

*Se prueba con:* carga del catálogo (evidencias de carga inicial y de recarga con lápida) y `verificar_no_cambio.sql`

---

### Requisito 9 — Reglas de prioridad del semáforo y casos borde (F2)

**Historia de usuario:** Como vendedor, quiero que el semáforo nunca apruebe por error un borrador
dudoso, para no prometer algo que el servidor va a rechazar.

#### Criterios de aceptación

1. THE Sistema SHALL evaluar únicamente las solicitudes en estado `PENDIENTE`.
2. WHEN una solicitud tiene a la vez un motivo de rechazo (rojo) y un conflicto de precio (amarillo),
   THE Sistema SHALL asignar `RECHAZADO` (el rojo gana) (F2-1).
3. WHEN un ítem referencia un producto que no aparece en la instantánea, THE Sistema SHALL tratarlo
   como rojo y registrar `producto N no existe en el servidor`; un `NULL` del `LEFT JOIN` SHALL NOT
   pasar como verde (F2-2).
4. WHEN un borrador no tiene ítems, THE Sistema SHALL marcar la solicitud como `RECHAZADO` con motivo
   `borrador sin ítems` (F2-3).
5. WHEN un producto tiene `disponible = 'f'` en la instantánea, THE Sistema SHALL marcar la solicitud
   como `RECHAZADO` con el nombre del producto y la causa `no disponible` (F2-4).
6. WHEN todos los ítems coinciden en precio, hay stock y los productos están activos y disponibles,
   THE Sistema SHALL marcar la solicitud como `SIMULADO_APROBADO` (control, F2-5).
7. THE Sistema SHALL, al terminar la evaluación, registrar `evaluada_en` y reportar
   `solicitudes_evaluadas` con la cantidad de solicitudes que pasaron de `PENDIENTE` a otro estado.
8. THE Sistema SHALL NOT validar el contenido del UUID más allá de su longitud de 36 caracteres.

*Se prueba con:* **F2-1 a F2-6** (`casos_f2_semaforo.sql`)

---

### Requisito 10 — Dos borradores compiten por el mismo stock (C8)

**Historia de usuario:** Como responsable del sistema, quiero que quede explícito que el semáforo de la
tablet no resuelve la competencia por stock entre borradores, para que nadie lea
`SIMULADO_APROBADO` como una venta garantizada.

#### Criterios de aceptación

1. WHEN existen dos borradores `PENDIENTE` distintos que piden el mismo producto, y cada uno por
   separado pide una cantidad menor o igual al stock de la instantánea pero la suma de ambos supera
   ese stock, THE Sistema SHALL evaluar cada solicitud de forma independiente y marcar **ambas** como
   `SIMULADO_APROBADO`.
2. THE Sistema SHALL NOT sumar ni reservar cantidades entre solicitudes distintas al evaluar el
   semáforo.
3. THE Sistema SHALL NOT modificar `stock_visto` en `producto_cache` ni el stock de la instantánea
   como resultado de la evaluación.
4. THE Sistema SHALL documentar que la resolución real de la competencia corresponde solo al
   servidor, mediante `sp_crear_pedido` con `SELECT … FOR UPDATE`: la primera solicitud que llegue
   se acepta y la segunda se rechaza por stock insuficiente.
5. WHEN se ejecuta el caso C8, el stock de PostgreSQL SHALL NOT cambiar (`verificar_no_cambio.sql`
   da la misma huella antes y después).
6. THE Sistema SHALL dar el mismo resultado para C8 sin importar el orden en que se encolaron o evaluaron
   las dos solicitudes.

**Escenario de prueba sugerido (datos inventados):** Tiramisú (producto 11, stock 6 en la
instantánea). Borrador A pide 4 y borrador B pide 4, con el precio vigente. Cada uno pasa solo
(4 ≤ 6), juntos piden 8 > 6. Resultado esperado: A y B en `SIMULADO_APROBADO`.

*Se prueba con:* **C8** (`casos_c8_competencia_stock.sql`)

---

### Requisito 11 — Entregables, ejecución y evidencia

**Historia de usuario:** Como integrante del equipo, quiero que todo se pueda generar y ejecutar desde cero
en un orden documentado y dejar evidencia, para poder defender cada resultado.

#### Criterios de aceptación

1. THE Sistema SHALL entregarse solo como scripts SQL (SQLite y, del lado del servidor, PostgreSQL de solo
   lectura) y un README con el orden de ejecución; no hay código de aplicación.
2. WHEN se ejecutan los scripts sobre una base SQLite nueva, en el orden documentado en el diseño, THE Sistema
   SHALL reproducir los resultados esperados de los casos C1 a C8 y F2-1 a F2-6 sin ningún paso manual
   no documentado.
3. THE Sistema SHALL usar solo datos inventados; ningún script ni dato de ejemplo contiene el nombre real de
   una persona.
4. WHEN se ejecuta un script, THE Sistema SHALL permitir guardar su salida completa como un archivo de
   evidencia numerado, sin editar a mano.

*Se prueba con:* ejecución completa del README y evidencias guardadas

---

## Historial de revisiones

- **2026-11-06 (segunda entrega):** se completó el Requisito 4 (había quedado sin criterios), se cambió el umbral de
  precio del Requisito 1 a centavos, se normalizó la redacción `SHALL NOT`, se agregaron los criterios 9.8 y
  10.6 y el Requisito 11. Se conservan los Requisitos 1 a 3 y 5 a 10 de la versión anterior, que se escribió
  después del código original (declarado en la DUIA); esta revisión se hace **antes** de regenerar con OpenCode.
