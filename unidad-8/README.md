# Food Store · TP N.º 8 — La base de la tablet y el cierre de la capa de datos

[![Repositorio en GitHub](https://img.shields.io/badge/GitHub-TP--Unidad8--BD2-181717?logo=github&logoColor=white)](https://github.com/marianoemir/TP-Unidad8-BD2)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16%2B-336791?logo=postgresql&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-3.37%2B-003B57?logo=sqlite&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE?logo=powershell&logoColor=white)

> 📦 **Repositorio del trabajo:** [github.com/marianoemir/TP-Unidad8-BD2](https://github.com/marianoemir/TP-Unidad8-BD2) · etiqueta de entrega: `tp8`

**Grupo:** Lobos Solitarios

| Integrante | Usuario de GitHub |
|---|---|
| Mariano Chirino | `marianoemir` |
| Andrés Fabre | `andresfabre27` |
| Facundo Quiroga | `Buhonero009` |

Base de Datos II · Tecnicatura Universitaria en Programación (UTN) · 2026.
El food truck vende en una feria sin señal: la tablet tiene una base **SQLite**, y la sincronización con
**PostgreSQL** se simula con un semáforo.

> **El móvil propone, el servidor dispone.** La tablet solo consulta y arma borradores. Precio, stock y ventas
> los decide PostgreSQL. `SIMULADO_APROBADO` **no es una venta**.

## Requisitos

- PostgreSQL 16+ con `psql` (en Windows suele no estar en el PATH: usar la ruta completa, ver abajo).
- SQLite **3.37 o superior** (tablas `STRICT`). Verificar las dos formas, pueden ser versiones distintas:
  `sqlite3 --version` y `python -c "import sqlite3; print(sqlite3.sqlite_version)"`.
- Datos inventados, sin contraseñas ni cadenas de conexión en el repo.

## Orden para crear todo desde cero

Desde PowerShell, **en la raíz del repo** (el CSV y los scripts usan rutas relativas):

```powershell
$psql = "C:\Program Files\PostgreSQL\17\bin\psql.exe"      # ajustar a tu versión
$env:PGCLIENTENCODING = "UTF8"
$db = "movil/foodstore_movil.db"

# 1. PostgreSQL de PRUEBAS: base nueva, armada con los scripts heredados
& $psql -U postgres -c "CREATE DATABASE foodstore_u8"
foreach ($f in "schema","objects","data","views") {
    & $psql -U postgres -d foodstore_u8 -v ON_ERROR_STOP=1 -f "heredado/base_heredada/$f.sql"
}
& $psql -U postgres -d foodstore_u8 -f postgresql/10_snapshot_catalogo.sql
& $psql -U postgres -d foodstore_u8 -f postgresql/verificar_no_cambio.sql      # ANTES: 6 pedidos, huella de stock

# 2. Instantánea → CSV (consigna 2.a)
& $psql -U postgres -d foodstore_u8 -f postgresql/11_exportar_snapshot.sql

# 3. Base de la tablet desde cero (consignas 1.b y 2.a)
Remove-Item $db -ErrorAction SilentlyContinue
sqlite3 $db ".read movil/schema_sqlite.sql"
sqlite3 $db ".import --csv --skip 1 movil/servidor_snapshot.csv snapshot_servidor"
sqlite3 -header -column $db ".read movil/cargar_catalogo.sql"                  # anotar la fecha de la copia

# 4. Pruebas de la tablet (consigna 1.c: COMMIT, ROLLBACK, C1, C7)
sqlite3 -header -column $db ".read movil/pruebas_sqlite.sql"
```

Los 3 errores de C7 (`CHECK`, `FOREIGN KEY`, `STRICT`) son **esperados**: el script sigue y no deja filas nuevas.

## Los casos C2 a C6 (consigna 2.c)

```powershell
# 5. Borradores de C2, C3, C4 y C5, con la lista de precios actual
sqlite3 -header -column $db ".read movil/casos_c2_c5_borradores.sql"

# 6. El SERVIDOR cambia (C2: sube el precio; C4: baja lógica). Nunca la tablet.
& $psql -U postgres -d foodstore_u8 -f postgresql/casos/c2_subir_precio.sql
& $psql -U postgres -d foodstore_u8 -f postgresql/casos/c4_baja_logica.sql

# 7. Instantánea NUEVA: se vacía la tabla de paso, se importa y se recarga el catálogo
& $psql -U postgres -d foodstore_u8 -f postgresql/11_exportar_snapshot.sql
sqlite3 $db "DELETE FROM snapshot_servidor;"
sqlite3 $db ".import --csv --skip 1 movil/servidor_snapshot.csv snapshot_servidor"
sqlite3 -header -column $db ".read movil/cargar_catalogo.sql"

# 8. El semáforo (primera corrida)
sqlite3 -header -column $db ".read movil/semaforo.sql"

# 9. C2: el cliente acepta el precio nuevo (solicitud nueva) · C6: se reenvía el mismo UUID
sqlite3 -header -column $db ".read movil/casos_c2_c6_resolucion.sql"
sqlite3 -header -column $db ".read movil/semaforo.sql"       # evalúa solo la solicitud nueva
sqlite3 -header -column $db ".read movil/semaforo.sql"       # repetir: 0 solicitudes evaluadas

# 10. PostgreSQL no cambió (pedidos y stock): comparar con el paso 1
& $psql -U postgres -d foodstore_u8 -f postgresql/verificar_no_cambio.sql
```

### Resultados esperados

| Caso | Qué pasa | Resultado |
|---|---|---|
| C1 | Catálogo con el servidor apagado | 13 productos (no aparecen el 3, el 15 ni el 16) |
| C2 | Muzzarella sube de $3.500 a $4.000 | `CONFLICTO`; tras aceptar, solicitud nueva `SIMULADO_APROBADO` |
| C3 | 10 Tiramisú, quedan 6 | `RECHAZADO` (stock insuficiente) |
| C4 | Fugazzeta dada de baja | `RECHAZADO`; sale del catálogo pero la fila queda con `eliminado = 1` |
| C5 | Sin cambios | `SIMULADO_APROBADO` |
| C6 | Mismo UUID otra vez | Error de clave primaria; la 2.ª corrida del semáforo evalúa 0 |
| C7 | Cantidad 0 / producto inexistente | Error; no queda ninguna fila nueva |

## Archivos

| Ruta | Qué es | Consigna |
|---|---|---|
| `movil/schema_sqlite.sql` | Cinco tablas STRICT, índice parcial, vista del catálogo, tabla de paso | 1.b |
| `movil/pruebas_sqlite.sql` | COMMIT, ROLLBACK, C1, C7 | 1.c |
| `movil/cargar_catalogo.sql` | `producto_cache` desde la instantánea (UPSERT) | 2.a |
| `movil/semaforo.sql` | Rojo / amarillo / verde sobre las `PENDIENTE` | 2.b |
| `movil/casos_c2_c5_borradores.sql`, `casos_c2_c6_resolucion.sql` | Borradores y resolución de los casos | 2.c |
| `movil/servidor_snapshot.csv`, `movil/foodstore_movil.db` | Se generan con los pasos de arriba; también están versionados | 2.a |
| `postgresql/10_snapshot_catalogo.sql`, `11_exportar_snapshot.sql` | Vista `v_snapshot_movil` y exportación | 2.a |
| `postgresql/casos/`, `verificar_no_cambio.sql` | Cambios del servidor por caso y prueba de que no se tocó nada | 2.c |
| `postgresql/verificar_vista_snapshot.sql`, `movil/verificar_vistas_tablet.sql` | Equivalencia de la vista con la tabla y de la vista de la tablet con `producto_cache` (protocolo de seguridad, paso 5) | 2.a |
| `movil/casos_f2_semaforo.sql` | Casos borde del semáforo (revisión cruzada F2): rojo + amarillo, producto fuera de la instantánea, sin ítems, no disponible. **Solo en una copia** de la tablet | 2.b |
| `postgresql/verificar_hallazgos_3c.sql` | Comprobación de los hallazgos H01 y R1 del code review. **Solo en una copia** de la base | 3.c |
| `evidencias/` | Salidas de cada comando (01 a 12: C1 a C7; 13 y 14: vistas; 15 a 17: code review; 18 y 19: casos borde del semáforo; 20 y 21: revisión de Andrés, A4 completa y 3.c; 22 a 29: objetivo 11, ver la sección siguiente) | todas |
| `movil_opencode/`, `movil_opencode_v2/` | Objetivo 11: la base de la tablet regenerada con OpenCode desde la spec (ver la sección siguiente) | 4 y 11 |
| `heredado/` | Scripts de las Unidades 1 a 7, entrada del code review (ver nota abajo) | 3.c |
| `docs/` | `informe.pdf` (1.a, 2.c, 3.a, 3.b, 3.c), `kiro/` (spec), `bitacora_ia.md`, `DUIA.md` y `DIVISION_DE_TRABAJO.md` (quién hace qué y en qué orden) | 3 y 4 |

**Nota sobre `heredado/`.** Los scripts están sin modificar, salvo `data.sql`: se reemplazó el usuario con
nombre real de un integrante por uno inventado (Carlos Rivas), por la regla de datos ficticios.

## Objetivo 11: la base de la tablet regenerada con OpenCode desde la spec

La spec de Kiro (`.kiro/specs/foodstore-tablet-sync/`) se amplió y se commiteó **antes** de generar. Con ella y `AGENTS.md`
se hicieron dos corridas de OpenCode (agente Nemotron 3.5 Lightning Free). **Ninguna produjo una base funcional sin editar.**

| Carpeta | Qué es | Estado |
|---|---|---|
| `movil/` | Scripts originales (hechos con Claude y NotebookLM, spec posterior) | Referencia; no se borra |
| `movil_opencode/` | Corrida 1 (06/11) corregida con Claude a partir de los errores; originales sin editar en `movil_opencode/original_opencode/` | **Versión final**: pasa C1 a C8 y F2 (evidencias 25 a 27) |
| `movil_opencode_v2/` | Corrida 2 (07/11), en carpeta aislada sin `movil/`, **sin editar** | Evidencia: nueve defectos (evidencias 28 y 29) |

Qué falló, qué se corrigió y qué diferencias hay con los originales: `docs/comparacion_generado_vs_original.md`.
Registros de las corridas (modelo, prompt y respuesta cruda): `docs/registro_opencode_corrida1.txt` y `docs/registro_opencode_corrida2.txt`.

| Evidencia | Contenido |
|---|---|
| 22 | Corrida 1 sin editar (el esquema no se crea) |
| 23 a 25 | Versión corregida: esquema, carga y casos (25: `casos.sql` completo) |
| 26 | Casos F2 originales contra la versión corregida |
| 27 | `casos.sql` tras los REQ 6.12 y 6.13 |
| 28 | Corrida 2 sin editar |
| 29 | Corrida 2: `motivo` sin `CHECK`, clave foránea con y sin `PRAGMA`, tablas sin `STRICT` |

Para ejecutar la versión final se usa el mismo orden de arriba cambiando `movil/` por `movil_opencode/`. Cada script lleva
`PRAGMA foreign_keys = ON;` porque cada `sqlite3` abre una conexión nueva con la clave foránea desactivada.

## Uso de IA

Spec en `docs/kiro/`; bitácora en `docs/bitacora_ia.md`; declaración en `docs/DUIA.md`.
