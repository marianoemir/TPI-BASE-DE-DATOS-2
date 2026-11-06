# 2.c · Los casos C2 a C6

Entorno: PostgreSQL 17.10 (`foodstore_u8`, base de pruebas) y SQLite 3.54.1. Cada salida completa está en `evidencias/`.
Fecha de la primera instantánea (2.a): `2026-11-03 08:48:12-03`, 16 productos (`evidencias/03_cargar_catalogo.txt`).
Fecha de la segunda, tomada después de los cambios del servidor: `2026-11-03 08:50:45-03` (`evidencias/07_recarga_c4.txt`).

En todos los casos la preparación es la misma: se anotan los borradores con la lista de precios vigente, el **servidor** cambia
datos de la copia de pruebas, se exporta una instantánea nueva (`11_exportar_snapshot.sql`), se vacía e importa `snapshot_servidor`,
se recarga `producto_cache` y se corre el semáforo.

## C2 · El precio cambió en el servidor

**Comandos**

```
sqlite3 -header -column $db ".read movil/casos_c2_c5_borradores.sql"      # borrador de 1 Muzzarella a $3.500
psql -U postgres -d foodstore_u8 -f postgresql/casos/c2_subir_precio.sql  # UPDATE 1: sube a $4.000
sqlite3 -header -column $db ".read movil/semaforo.sql"
sqlite3 -header -column $db ".read movil/casos_c2_c6_resolucion.sql"      # el cliente acepta: solicitud nueva
sqlite3 -header -column $db ".read movil/semaforo.sql"
```

**Resultado**

| Corrida | Solicitud | Estado | Motivo |
|---|---|---|---|
| 1.ª (`08_semaforo_1.txt`) | `c2000000-…-00000000000b` | `CONFLICTO` | precio de Muzzarella cambió de 350000 a 400000 centavos |
| 2.ª (`10_semaforo_2.txt`) | `c2000000-…-00000000000c` (nueva) | `SIMULADO_APROBADO` | — |

**Explicación.** El precio del borrador (350000) ya no coincide con el de la instantánea (400000), pero no falta ningún producto,
así que el semáforo da amarillo: se le pregunta al cliente. Al aceptar, se actualiza el precio del borrador con el de la lista
recargada y se encola una solicitud con UUID nuevo, que el índice parcial `ux_cola_una_pendiente` permite porque la anterior ya no está `PENDIENTE`.

## C3 · No alcanza el stock

**Comandos.** El borrador sale de `casos_c2_c5_borradores.sql` y se evalúa con `.read movil/semaforo.sql` (primera corrida).

**Resultado** (`08_semaforo_1.txt`): `c3000000-…-00000000000b` → `RECHAZADO`, motivo *stock insuficiente de Tiramisú (pide 10, hay 6)*.

**Explicación.** La tablet no bloquea el pedido por su `stock_visto`, que es solo orientativo: la decisión es del servidor, y el semáforo
compara con el stock de la instantánea. El stock de PostgreSQL no se tocó (ver la verificación al final).

## C4 · Un producto fue dado de baja

**Comandos**

```
psql -U postgres -d foodstore_u8 -f postgresql/casos/c4_baja_logica.sql   # UPDATE 1: eliminado = TRUE en la Fugazzeta (baja lógica)
sqlite3 -header -column $db ".read movil/cargar_catalogo.sql"             # recarga del catálogo
sqlite3 -header -column $db ".read movil/semaforo.sql"
```

**Resultado** (`07_recarga_c4.txt` y `08_semaforo_1.txt`)

- Fugazzeta en `v_catalogo_disponible`: **0** filas (ya no aparece). En `producto_cache`: la fila sigue, con `eliminado = 1`.
- `c4000000-…-00000000000b` → `RECHAZADO`, motivo *producto 3 (Fugazzeta) dado de baja*.

**Explicación.** La baja viaja a la tablet como lápida (`eliminado = 't'` en la instantánea). La carga usa `INSERT … ON CONFLICT DO UPDATE`,
no `INSERT OR REPLACE`, para conservar la fila que un borrador todavía referencia con una clave foránea; el producto sale de pantalla pero no del archivo.

## C5 · Todo coincide

**Resultado** (`08_semaforo_1.txt`): `c5000000-…-00000000000b` → `SIMULADO_APROBADO`, sin motivo. Lo mismo ocurre con el borrador de 1.c (`a0000000-…-00000000000b`).

**Explicación.** Con esta lista de precios y stock, el pedido pasaría las validaciones. **No es una venta**: solo `sp_crear_pedido` en el servidor
confirma una venta, y vuelve a revisar el stock con `SELECT … FOR UPDATE`, porque entre la instantánea y ese momento alguien más pudo comprar.

## C6 · Se reenvía la misma solicitud

**Comandos.** Está dentro de `casos_c2_c6_resolucion.sql` (intento de insertar de nuevo el UUID `c5000000-…-00000000000b`) y después se repite el semáforo.

**Resultado** (`09_c2_acepta_c6.txt` y `11_semaforo_3_repetido.txt`)

- El `INSERT` falla con `UNIQUE constraint failed: cola_sync.solicitud_uuid`.
- La fila original conserva `SIMULADO_APROBADO` y su `evaluada_en` (`2026-11-03T11:50:45Z`).
- En la tercera corrida del semáforo, `solicitudes_evaluadas = 0` y ninguna fecha cambia.

**Explicación.** El UUID es la clave primaria de `cola_sync`, así que un duplicado no entra; y como el semáforo solo evalúa las `PENDIENTE`,
repetirlo no reevalúa nada.

**Dónde iría la protección real (parada 8).** En un sistema real el control no puede estar solo en la tablet: tiene que estar **en el servidor**, con una tabla
`solicitud_movil` cuya clave primaria sea el UUID, insertada con `ON CONFLICT DO NOTHING` en la misma transacción que crea el pedido con `sp_crear_pedido`.
Si el servidor no recordara el UUID, un reintento crearía un segundo pedido. (Ejemplo docente; el TP no lo implementa.)

## PostgreSQL no cambió

**Consulta** (`postgresql/verificar_no_cambio.sql`, de solo lectura), corrida antes (`01_pg_antes.txt`) y después (`12_pg_despues.txt`):

| pedidos | detalles | stock_total | huella_stock |
|---|---|---|---|
| 6 | 13 | 454 | `89f8351d0162e23ef1473f32b05ce221` |

Los valores son idénticos. El precio de la Muzzarella y la baja de la Fugazzeta los cambió el propio servidor de pruebas, a propósito, para preparar C2 y C4;
no alteran los pedidos ni el stock, que son lo que mide la huella. La tablet nunca escribió en PostgreSQL.
