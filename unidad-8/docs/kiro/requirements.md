# Requisitos — Food Store · base de la tablet y sincronización simulada

Notación EARS. Cada requisito indica el caso del TP que lo prueba.

**REQ-01** WHEN el precio actual del servidor es distinto del precio visto en el borrador
THE SYSTEM SHALL marcar la solicitud como `CONFLICTO`, guardar en el motivo los dos precios y no volver a
evaluarla hasta que el cliente acepte y se genere una solicitud nueva.
*Se prueba con:* **C2**

**REQ-02** WHEN la cantidad pedida supera el stock de la instantánea del servidor
THE SYSTEM SHALL marcar la solicitud como `RECHAZADO` (aunque haya además un cambio de precio) sin modificar
el stock ni ningún dato de PostgreSQL.
*Se prueba con:* **C3**

**REQ-03** WHEN un producto del borrador fue dado de baja en el servidor (lápida) o no existe o no está disponible
THE SYSTEM SHALL marcar la solicitud como `RECHAZADO`, sacar el producto del catálogo de la tablet y conservar su fila.
*Se prueba con:* **C4**

**REQ-04** WHEN se reenvía una solicitud con un UUID que ya está registrado
THE SYSTEM SHALL rechazar el duplicado por clave primaria, conservar sin cambios la fila ya guardada y no evaluarla otra vez.
*Se prueba con:* **C6**
