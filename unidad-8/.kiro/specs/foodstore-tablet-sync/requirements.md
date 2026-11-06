# Documento de Requisitos — Food Store · Base de la tablet y sincronización simulada

## Introducción

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
- **PENDIENTE**: estado inicial de toda solicitud, antes de ser evaluada por el semáforo.
- **CONFLICTO**: la solicitud fue evaluada y al menos un precio difiere entre el borrador y la instantánea.
- **RECHAZADO**: la solicitud fue evaluada y al menos un producto no puede cumplirse (stock, baja o inexistencia).
- **SIMULADO_APROBADO**: la solicitud fue evaluada y no hay conflictos ni rechazos; no constituye una venta.
- **UUID**: identificador único de 36 caracteres generado en la tablet para cada solicitud.
- **Lápida**: columna `eliminado = 1` en `producto_cache`; la fila se conserva pero el producto no se muestra.

---

## Requisitos

### Requisito 1 — Conflicto de precio (C2)

**Historia de usuario:** Como vendedor, quiero que el sistema me avise cuando el precio del servidor cambió
desde que anoté el borrador, para que el cliente pueda confirmar el nuevo precio antes de continuar.

#### Criterios de aceptación

1. WHEN el precio registrado en un ítem del borrador difiere del precio del mismo producto en la instantánea
   del servidor en al menos 0,01 unidades monetarias, THE Sistema SHALL marcar la solicitud como `CONFLICTO`,
   registrar en el campo `motivo` el nombre del producto, el precio registrado en el
   borrador y el precio actual del servidor, y mantener el estado `CONFLICTO` sin reevaluarlo ni modificarlo
   hasta que el cliente genere una nueva solicitud con UUID distinto.
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

1. WHEN se intenta insertar en `cola_sync` una solicitud con un UUID que ya existe en la tabla, THE Sistema
   SHALL rechazar la inserción e indicar fallo por restricción de clave primaria, sin modificar ninguna fila
   existente en `cola_sync`.
2. WHEN el intento de duplicar un UUID falla por clave primaria, THE Sistema SHALL conservar intactos el
   estado y el campo `evaluada_en` de la solicitud original, sin reevaluarla, independientemente de si su
   estado actual es `PENDIENTE`, `CONFLICTO`, `RECHAZADO` o `SIMULADO_APROBADO`.
3. WHEN el semáforo se ejecuta después de un intento de duplicado, THE Sistema SHALL evaluar cero
   solicitudes adicionales relacionadas con ese UUID y reportar `solicitudes_evaluadas = 0`.

*Se prueba con:* **C6**
