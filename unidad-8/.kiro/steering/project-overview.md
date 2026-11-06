# Food Store — Visión General del Proyecto

## Descripción

Sistema de venta de comida. Las Unidades 1 a 6 lo construyeron en **PostgreSQL** (modelo, consultas, índices,
transacciones, seguridad, respaldo). La Unidad 7 representó los pedidos en **MongoDB**. La **Unidad 8** (este TP)
agrega la base de la **tablet** del food truck en **SQLite** y simula la sincronización con PostgreSQL.

## Regla de oro

**El móvil propone, el servidor dispone.** La tablet consulta el catálogo y arma borradores. Precio, stock y
ventas los decide PostgreSQL. `SIMULADO_APROBADO` quiere decir "con esta lista, el pedido pasaría": no es una venta.

## Tres motores, una fuente de verdad

| Motor | Qué guarda | Quién manda |
|---|---|---|
| PostgreSQL (`foodstore_u8`, base de pruebas) | Catálogo, usuarios, pedidos, stock | **Fuente de verdad**: decide precio, stock y ventas |
| MongoDB (Unidad 7) | Pedidos y detalle como documentos | Solo sobre esos documentos; no manda sobre el stock |
| SQLite (`movil/foodstore_movil.db`) | Copia del catálogo, borradores y cola de envío | Nadie: solo prepara |

## Flujo (la historia del apunte)

1. PostgreSQL publica la instantánea (`v_snapshot_movil`) → CSV con fecha.
2. La tablet la carga en `producto_cache` y arma borradores sin señal (borrador + ítems + solicitud, en una transacción).
3. Al volver la señal, el **semáforo** compara cada solicitud `PENDIENTE` con una instantánea nueva:
   rojo `RECHAZADO` (gana siempre) · amarillo `CONFLICTO` · verde `SIMULADO_APROBADO`.
4. Solo PostgreSQL confirma una venta (con `sp_crear_pedido`, que revalida el stock con `FOR UPDATE`).

## Orden de trabajo

Primero el spec en Kiro (`docs/kiro/requirements.md`, `design.md`, `tasks.md`), después los scripts, siempre
leídos y probados sobre una copia. Todo uso de IA se registra en `docs/bitacora_ia.md`.
