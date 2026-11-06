# Food Store — Instrucciones para Agentes (TP Unidad 8)

TP N.º 8 de Base de Datos II (UTN · TUP): la base de la tablet del food truck en **SQLite**, la sincronización
simulada con **PostgreSQL** y el cierre de la capa de datos. Antes de generar o modificar código, leer
`.kiro/steering/` y `docs/kiro/`.

## Regla de oro

**El móvil propone, el servidor dispone.** La tablet solo consulta y arma borradores. Nada de lo que se genere
puede cambiar stock, precio o pedidos de PostgreSQL, ni presentar `SIMULADO_APROBADO` como una venta.

## Reglas que no se negocian

1. Trabajar sobre una **copia** de la base (`foodstore_u8`), con **datos inventados**.
2. Nada de contraseñas, mails, celulares ni datos personales reales: ni en SQLite, ni en Git, ni en lo que se le pida a la IA.
3. Todo lo generado con IA se **lee línea por línea y se prueba** antes de ejecutarlo. Lo que no se pueda explicar en la defensa cuenta como no hecho.
4. Cada uso de IA se anota en `docs/bitacora_ia.md` (qué se pidió, qué se aceptó, qué se descartó y por qué).
5. Para el code review con IA, usar el agente **Plan** (analiza sin modificar archivos).

## Stack

| Componente | Versión | Uso |
|---|---|---|
| PostgreSQL | 16+ | Servidor de pruebas (`foodstore_u8`); fuente de verdad |
| SQLite | 3.37+ (tablas `STRICT`) | Base de la tablet (`movil/foodstore_movil.db`) |
| Clientes | `psql`, `sqlite3`, DBeaver / DB Browser for SQLite | Ejecutar y mostrar resultados |

## Estructura

```
movil/        schema_sqlite.sql · cargar_catalogo.sql · pruebas_sqlite.sql · semaforo.sql
              casos_c2_c5_borradores.sql · casos_c2_c6_resolucion.sql
postgresql/   10_snapshot_catalogo.sql · 11_exportar_snapshot.sql · verificar_no_cambio.sql · casos/
heredado/     scripts de las Unidades 1 a 7 (sin modificar; entrada del code review)
docs/         informe · kiro/ · bitacora_ia.md · DUIA.md
```

## Lo que hay que respetar al escribir SQL

- SQLite: `PRAGMA foreign_keys = ON;` primero en todo script; tablas `STRICT`; dinero en centavos enteros;
  booleanos 0/1 con `CHECK`; UUID de 36 caracteres para lo que nace en la tablet.
- El semáforo evalúa **solo** solicitudes `PENDIENTE`; el rojo gana sobre el amarillo; un producto que no aparece
  en la instantánea es rojo (cuidado con los `NULL` del `LEFT JOIN`).
- Recargar el catálogo con `INSERT ... ON CONFLICT DO UPDATE` (nunca `INSERT OR REPLACE`): la lápida conserva la fila.
- PostgreSQL: baja siempre lógica (`eliminado = TRUE`), nunca `DELETE`; pedidos solo con `sp_crear_pedido`.
- Un `UNIQUE` simple sobre `cola_sync.id_local` es incorrecto: impediría reenviar tras un CONFLICTO.
  La regla "una sola pendiente" la cumple el índice parcial `ux_cola_una_pendiente`.
