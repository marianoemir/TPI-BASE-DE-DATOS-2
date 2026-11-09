# 3.b · Plan de mantenimiento (agregado al plan de la Unidad 6)

> Se apoya en `unidad-6/SPEC_U6_ampliacion.md` y en las evidencias reales del 07/11/2026. Lo que sigue agrega lo que cambia al sumar las tablets.

**1. ¿Qué se respalda y cómo se prueba la restauración?**
Se respalda la **fuente de verdad**: la base PostgreSQL (`foodstore`) con `pg_dump` en formato custom (`backup_foodstore.ps1` de la Unidad 6), con fecha y hora en el nombre, verificado con `pg_restore --list`, SHA-256 y guardado fuera del repo. El dump de datos usa `operador_respaldo`, un rol sin atributos administrativos; además se guarda un dump separado de roles/globales con `pg_dumpall --globals-only --no-role-passwords` y su hash.
El respaldo es **diario** (RPO previsto: hasta 24 h) y se ejecuta antes de cada cambio estructural. En la repetición del 07/11/2026 se registró la tarea `FoodStore-Respaldo-Diario`, se disparó manualmente y terminó con `LastTaskResult = 0`; después se desregistró junto con las demás tareas de prueba. No hay evidencia de una ejecución por horario. La retención conserva siempre el último conjunto válido y elimina conjuntos completos de más de 14 días.
La restauración se prueba **cada semana** en `foodstore_restore_test`, nunca sobre la real. Antes de borrar la copia verifica los SHA-256; después restaura, ejecuta `ANALYZE`, `pg_amcheck`, compara conteos con origen y comprueba valores inválidos y referencias huérfanas. En el simulacro del 07/11/2026 tardó 7,11 s y usó un respaldo de 2 min 52 s de antigüedad (RPO observado: 0,05 h).
Para esta unidad se agrega `postgresql/verificar_no_cambio.sql`: si los pedidos, los detalles, el stock total y la huella de stock coinciden con los de la base original, el respaldo sirve.
El dump global de roles se conserva y verifica, pero no se aplica automáticamente: restaurar roles modifica todo el clúster local. La verificación de permisos de la U5 se hace manualmente sobre la copia restaurada. En la repetición final del 07/11 se aplicó el `roles.sql` vigente y `verificacion_roles.sql` dio T01 a T23 en `OK`; la evidencia está en `unidad-6/evidencias/obj7_verificacion_roles_mariano_20261107.txt`.
MongoDB se puede regenerar desde PostgreSQL con la exportación de la Unidad 7. La base de la tablet no se respalda como fuente: la lista de precios se regenera con una instantánea nueva.
Lo único que existe solo en la tablet son los borradores que todavía no se enviaron, por eso se copia el archivo `foodstore_movil.db` antes de actualizar el catálogo.

**2. Si se restaura un respaldo viejo de PostgreSQL, ¿qué hacen las tablets?**
Las tablets quedan con datos «del futuro»: precios, stock y bajas que el servidor restaurado ya no tiene. Por eso **no envían nada con esa lista**: primero
**vuelven a descargar el catálogo** (instantánea nueva → recarga de `producto_cache`) y recién ahí se corre el semáforo sobre las solicitudes `PENDIENTE`.
Como el UUID de cada solicitud no cambia, reenviarlas no duplica pedidos, y como `SIMULADO_APROBADO` nunca fue una venta, la restauración no deja ventas falsas en las tablets.

**3. ¿Cada cuánto y quién revisa las solicitudes en `CONFLICTO` o `RECHAZADO`?**
Se revisan **al volver la señal y al cierre de cada jornada de feria**. Las revisa el **vendedor a cargo de la tablet, junto con el administrador (rol `ADMIN`)**:
ante un `CONFLICTO` se le pregunta al cliente si acepta el precio nuevo y, si acepta, se actualiza el borrador y se genera una solicitud nueva;
ante un `RECHAZADO` se corrige el borrador o se avisa que el producto no está disponible, sin stock o dado de baja. Nada se resuelve desde la tablet contra el servidor.

---
*Versión corregida por Mariano Chirino tras revisar el borrador de Andrés Fabre (PR #1): se agregó la descarga del catálogo tras restaurar un respaldo viejo y se nombró quién revisa la cola. Las frecuencias (respaldo diario, restauración de prueba semanal) se contrastaron con `SPEC_U6.md` y coinciden con las del borrador; se agregó que al 21/10/2026 el respaldo era manual y que `pg_dump` no incluye roles. Actualización de Andrés del 08/11/2026: la verificación manual de roles fue repetida por Mariano el 07/11/2026 con la versión final de `roles.sql` (evidencia `obj7_*_mariano_*`); Andrés incorpora aquí ese resultado y no declara haber corrido esa prueba.*
