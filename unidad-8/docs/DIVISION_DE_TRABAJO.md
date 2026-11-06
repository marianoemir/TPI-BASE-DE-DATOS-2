# División de trabajo — TP N.º 8 (Food Store: la base de la tablet y el cierre de la capa de datos)

Equipo de tres integrantes: **Mariano Chirino**, **Andrés Fabre** y **Facundo Quiroga**. Este documento dice **quién hace
qué, qué necesita de los demás y en qué orden** se avanza. Se actualiza si el reparto cambia.

Entrega: un `.zip` (o el repo con la etiqueta `tp8`) antes del cierre de la semana 13, en la fecha publicada en el
campus. **No hay entregas tardías**: la semana 14 es el segundo parcial.

## 1. Reparto

| Integrante | A su cargo |
|---|---|
| **Mariano Chirino** | **Consigna 1** (esquema SQLite `schema_sqlite.sql` y pruebas `pruebas_sqlite.sql`), **consigna 2** (instantánea y CSV, semáforo `semaforo.sql`, casos C2 a C6 y verificación de que PostgreSQL no cambió), **requisitos y diseño en Kiro** (4.a), integración del repo y, **al final**, el armado del informe PDF (`informe.pdf`), el `README.md`, la unificación de las bitácoras y la etiqueta `tp8` |
| **Andrés Fabre** | **1.a** (qué datos viajan a la tablet), **3.a** (mapa de la capa de datos: PostgreSQL, MongoDB y SQLite) y **3.b** (plan de mantenimiento como agregado al plan de la Unidad 6). Además la **revisión cruzada de las consignas 1 y 2** en su propio equipo |
| **Facundo Quiroga** | **3.c** (code review con IA de los scripts de la cursada) y la **revisión cruzada del semáforo** con casos propios |

**Todos** arman su entorno (H0) y completan **su propia bitácora y su propia DUIA** (sección 9).

## 2. Estado actual (05/11/2026)

| Tarea | Estado |
|---|---|
| Consignas 1 y 2 (`movil/` y `postgresql/`) corridas en la máquina de Mariano, con evidencia en `evidencias/`, y subidas a `main` | Hecho |
| Spec de Kiro (4.a) en `docs/kiro/` y texto de 2.c en `docs/partes/2c_casos.md` | Hecho |
| Protocolo de seguridad, paso 5 (equivalencia de las vistas): `evidencias/13` y `14` | Hecho |
| 1.a, 3.a, 3.b (Andrés) | Hecho: borradores de Andrés corregidos por Mariano contra el esquema real (PR #1) |
| 3.c (Facundo) | Hecho y corregido por Mariano contra `evidencias/15` a `17` (PR #2). Faltan los datos de OpenCode que solo Facundo conoce (modelo, prompt, fecha) |
| Revisión cruzada del semáforo (F2) | Hecho con casos borde ejecutados por Mariano (`evidencias/18` y `19`); el caso propio de Facundo era del esquema, no del semáforo |
| Corrida completa en la máquina de Andrés y de Facundo (H0 y revisiones cruzadas) | Parcial: no hay logs suyos en `evidencias/`; los resultados de Andrés para PostgreSQL coinciden con los de Mariano |
| Bitácora y DUIA de cada integrante | Mariano y Andrés: hechas. Facundo: subida y corregida por Mariano, con datos pendientes de él |
| Informe PDF, README final, bitácora de IA unificada y etiqueta `tp8` | Se dejan para el final |

### Datos ya definidos (para que nadie espere)

| Dato | Valor |
|---|---|
| Base de PostgreSQL de pruebas | `foodstore_u8`, armada con `heredado/base_heredada/` (orden: `schema` → `objects` → `data` → `views`); **no** correr `carga_masiva.sql` |
| Conteos esperados de `usuario`, `producto` y `pedido` | **6 / 16 / 6** (el pedido 4 está dado de baja) |
| Base de la tablet | `movil/foodstore_movil.db` (se genera con el `README.md`) |
| Estados de la cola | `PENDIENTE`, `CONFLICTO`, `RECHAZADO`, `SIMULADO_APROBADO` (**no es una venta**) |
| Casos de prueba | C1 a C7; los casos y su orden de ejecución están en el `README.md` |

## 3. Dependencias: quién necesita de quién

| # | Tarea | Responsable | Necesita de… | Le sirve a… |
|---|---|---|---|---|
| H0 | Entorno propio (sección 4) | Cada uno | — | Todo lo demás |
| H1 | Requisitos EARS, diseño y tareas en Kiro (4.a) | Mariano | H0 | H2 a H5 (se especifica antes de generar código) |
| H2 | Vista `v_snapshot_movil` y exportación a CSV (2.a) | Mariano | H0, H1 | H3 y A1 |
| H3 | `schema_sqlite.sql`, carga del catálogo y pruebas 1.c | Mariano | H2 | H4, A1 y A4 |
| H4 | Semáforo, casos C2 a C6 y verificación de PostgreSQL (2.b y 2.c) | Mariano | H3 | A4, F2, H6 |
| A1 | Tabla «qué datos viajan» (1.a) | Andrés | Columnas de `v_snapshot_movil` (H2) | H6 |
| A2 | Mapa de los tres motores (3.a) | Andrés | `heredado/u7_mongodb/esquema_documental.md` y el esquema de H3 | H6 |
| A3 | Plan de mantenimiento (3.b) | Andrés | Plan de la Unidad 6 | H6 |
| A4 | Revisión cruzada de las consignas 1 y 2 | Andrés | H3 y H4 | Mariano |
| F1 | Code review con IA de los scripts (3.c): rama `review-final`, agente Plan, tabla de hallazgos | Facundo | H0; para la unidad móvil, H3 y H4 | H6 |
| F2 | Revisión cruzada del semáforo con casos propios | Facundo | H4 | Mariano |
| B1 | Bitácora individual y DUIA individual (4.b) | Cada uno | Lo que hizo cada uno; plantilla de bitácora y `duia_mariano.md` como modelo de formato | H7 |
| H6 | `informe.pdf` (hasta 6 páginas), **al final** | Mariano | A1, A2, A3, F1 y las salidas de H4 | Entrega |
| H7 | `README.md` final, `bitacora_ia.md` unificada y etiqueta `tp8`, **al final** | Mariano | B1 de los tres | Entrega |

```
H0 entorno (los 3)
  └─> H1 Kiro (Mariano) ─> H2 snapshot y CSV (Mariano) ─> H3 esquema y pruebas (Mariano) ─> H4 semáforo y casos C2-C6 (Mariano)
                                  │                              │                                   │
                                  └─> A1 qué viaja (Andrés)      ├─> A2 mapa y A3 plan (Andrés)      ├─> A4 revisión de 1 y 2 (Andrés)
                                                                 └─> F1 code review (Facundo)        └─> F2 revisión del semáforo (Facundo)
                       A1, A2, A3, F1 y salidas de H4 ───> H6 informe PDF (Mariano) ───> H7 README, bitácoras y etiqueta tp8
```

- **Andrés y Facundo pueden empezar ya** con lo que no depende del código: Andrés con A2 y A3 (solo necesita el
  material de las Unidades 6 y 7), y Facundo con F1 sobre los scripts de las Unidades 1 a 7 que están en `heredado/`.
- **Lo que depende de H3 y H4** (la parte móvil del code review, A4 y F2) se hace cuando Mariano avise que el
  esquema y el semáforo están estables.
- **Cada integrante entrega su parte del informe como un archivo corto** en `docs/partes/` para que el armado del PDF
  sea directo: `1a_datos_que_viajan.md` (tabla de las columnas de producto que viajan y las que no, más dos o tres
  oraciones sobre por qué y quién es la fuente de verdad), `3a_mapa_capa_de_datos.md` (tabla con qué guarda cada
  motor y quién manda), `3b_plan_mantenimiento.md` (las tres respuestas, en pocas líneas) y `3c_code_review.md`
  (tabla de hallazgos con su decisión).

## 4. Armado del entorno (H0)

Los comandos exactos están en el `README.md`; acá va lo que cada uno tiene que comprobar.

1. **PostgreSQL 16+ con `psql`.** Armar `foodstore_u8` con los scripts de `heredado/base_heredada/` y comprobar los
   conteos **6 / 16 / 6**. Crear la vista con `postgresql/10_snapshot_catalogo.sql`.
2. **SQLite 3.37 o superior.** Verificar `sqlite3 --version` y también
   `python -c "import sqlite3; print(sqlite3.sqlite_version)"`: pueden ser versiones distintas y `STRICT` falla
   en cualquiera de las dos que sea anterior a 3.37. DBeaver o DB Browser for SQLite sirven para mirar la base, pero los scripts
   se ejecutan con el CLI para dejar cada comando como evidencia.
3. **MongoDB: no hace falta instalarlo.** La parte documental se usa solo para el mapa (A2) y como material de lectura
   del code review.
4. **Credenciales:** ninguna cadena de conexión ni contraseña va al repo.

Cada uno anota en su bitácora las versiones y los problemas del armado.

## 5. Qué hace cada uno, en detalle

Además de lo de cada sección, **los tres** completan su bitácora y su DUIA individuales (sección 9).

### Mariano

1. Escribir en Kiro `requirements.md` (cuatro requisitos EARS, cada uno ligado a su caso), `design.md` y `tasks.md`
   **antes** de dar por cerrados los scripts.
2. Dejar andando `movil/` y `postgresql/` (consignas 1 y 2) y avisar a los otros cuando el esquema y el semáforo estén
   estables.
3. **Al final**, armar `informe.pdf` (hasta 6 páginas) con: 1.a, 2.c (comando, resultado y una o dos oraciones por caso, más la
   consulta que muestra que PostgreSQL no cambió y la oración de C6 sobre dónde iría la protección real), 3.a, 3.b y
   3.c. Cada valor del informe debe tener evidencia guardada.
4. **Al final**, `README.md` con el orden para crear todo desde cero, `bitacora_ia.md` unificada a partir de las individuales (las DUIA no se unifican), y etiqueta `tp8`.

### Andrés

1. **1.a:** tabla corta con las columnas de producto que viajan y las que no (por ejemplo, los datos de usuarios),
   y dos o tres oraciones: por qué y quién es la fuente de verdad.
2. **3.a:** mapa con los tres motores del proyecto (PostgreSQL, MongoDB de la Unidad 7 y SQLite): qué guarda cada uno
   y quién manda sobre cada dato.
3. **3.b:** plan de mantenimiento como agregado al de la Unidad 6, en pocas líneas: qué se respalda y cómo se prueba
   la restauración; qué hacen las tablets si se restaura un respaldo viejo de PostgreSQL; cada cuánto y quién revisa
   las solicitudes en `CONFLICTO` o `RECHAZADO`.
4. **Revisión cruzada (A4):** armar todo desde cero en su máquina siguiendo el `README.md` y comprobar que la salida de
   cada caso coincide con la tabla de resultados esperados que `verificar_no_cambio.sql` da lo mismo antes y después, y que `postgresql/verificar_vista_snapshot.sql` y `movil/verificar_vistas_tablet.sql` (Paso 5 del protocolo) dan 0 filas.

### Facundo

1. **3.c:** congelar el trabajo en una rama `review-final`. Pedirle a OpenCode, en el **agente Plan** (analiza sin
   modificar archivos), que revise los scripts **una unidad por vez**. Comprobar **cada hallazgo en el motor** (una
   consulta, un `EXPLAIN` o una prueba que falla): lo que dice la IA no es prueba.
2. Anotar cada hallazgo con su decisión (**aceptado, corregido o descartado**) y el motivo. Desarrollar **al menos
   tres, de al menos dos unidades distintas**, con cómo se comprobaron en la base. **Al menos uno descartado con
   fundamento**. Las correcciones van en commits separados y después se vuelve a correr todo desde una base vacía.
3. **Revisión cruzada del semáforo (F2):** correr `semaforo.sql` con casos propios además de C2 a C6 (por ejemplo un
   producto que ya no está en la instantánea, o un borrador con un rojo y un amarillo a la vez) y anotar qué pasó.
4. **Su propia bitácora y DUIA** (sección 9), igual que los otros dos.

## 6. Revisión cruzada

| Se revisa | Lo revisa | Cómo |
|---|---|---|
| `schema_sqlite.sql`, `pruebas_sqlite.sql` y la carga del catálogo | Andrés | Los arma desde cero en su máquina y comprueba que cada restricción rechaza lo que debe (C1 y C7) |
| `semaforo.sql` y los casos C2 a C6 | Facundo | Los corre en su equipo con casos propios y compara con los resultados esperados |
| `postgresql/` (vista y verificación) | Andrés | Que la vista no incluya datos de usuarios y que la verificación dé lo mismo antes y después |
| 1.a, 3.a y 3.b | Mariano | Que cada afirmación coincida con lo que realmente hay en el esquema y en el plan de la Unidad 6 |
| 3.c | Mariano y Andrés | Que cada hallazgo tenga una comprobación real y que haya al menos uno descartado con fundamento |
| `informe.pdf` | Andrés y Facundo | Que respete las 6 páginas y que cada valor tenga evidencia guardada |

Cada revisor anota en su bitácora qué revisó y qué encontró. Si no encontró nada, también se anota.

## 7. Control antes de entregar

El enunciado pide que lo generado con IA se lea y se pruebe, y que lo que no se pueda explicar cuente como no hecho.
Por eso, antes de armar el `.zip`:

- Cada uno corre la simulación completa al menos una vez en su máquina (H0 y las revisiones cruzadas) y guarda las
  salidas como evidencia.
- Cada uno puede explicar por escrito, en su bitácora, qué hace el script que revisó y por qué está hecho así. Las
  decisiones a documentar son: el índice parcial `ux_cola_una_pendiente` (frente a un `UNIQUE` simple), la carga del
  catálogo con `ON CONFLICT DO UPDATE` (frente a `INSERT OR REPLACE`) y el tratamiento de los `NULL` del `LEFT JOIN`
  en el semáforo.
- Mariano recorre la estructura de entrega del enunciado (`README.md`, `movil/`, `docs/`) y comprueba que no falte
  ningún archivo, incluidos `foodstore_movil.db` y `servidor_snapshot.csv`, que se generan con el `README.md`.

## 8. Trabajo con Git

- Repo nuevo del TP8. Se trabaja en `main`; antes de empezar y antes de subir: `git pull`. Cada uno modifica sus
  propios archivos, así que los conflictos son poco probables. El code review corre en la rama `review-final`.
- Mensajes de commit descriptivos: `feat(movil): ...`, `feat(postgresql): ...`, `docs(informe): ...`,
  `docs(ia): ...`, `fix(review): ...`. Un commit por entregable; las correcciones del code review, en commits
  separados.
- Sin credenciales (cadenas de conexión, contraseñas) ni datos personales reales en ningún commit.
- En Windows, Git puede marcar archivos como modificados solo por el fin de línea (CRLF/LF). Si pasa, no los
  commitees (se arregla con `git config core.autocrlf true`).

## 9. Bitácora y DUIA (cada uno la suya)

Cada integrante completa **las dos**, con lo que hizo en su parte:

| Documento | Qué es | Dónde queda |
|---|---|---|
| **Bitácora individual** | El registro detallado de lo que hizo y por qué: cada interacción con IA (qué se pidió, qué se aceptó, qué se descartó y por qué), los problemas y las decisiones. | `docs/bitacoras/bitacora_<nombre>.md`, a partir de la plantilla |
| **DUIA individual** | La Declaración de Uso de IA: el resumen formal de qué herramientas usó, para qué, qué se aceptó o descartó y cómo se verificó en el motor. Una por persona, **sin unificar**. | `docs/duia_<nombre>.md`, con el formato de `duia_mariano.md`. `docs/DUIA.md` es solo el índice de las tres |

- **Las bitácoras sí se unifican** al final en `docs/bitacora_ia.md`, comparando cada fila contra la evidencia del repo.
  Las DUIA se quedan como tres archivos.
- Se anota lo que realmente pasó, incluidos los casos en que la IA **no** se equivocó, y se distingue entre lo que **propuso
  la IA** y lo que fue una **decisión de diseño propia**. Las respuestas se resumen; nunca se anotan contraseñas ni cadenas
  de conexión.
- **Todo uso de IA se declara** (Kiro, OpenCode, Claude, NotebookLM u otras herramientas). Cada script generado con IA se
  lee línea por línea y se prueba sobre una copia de la base antes de incorporarlo.
- La bitácora unificada tiene al menos tres entradas, y al menos una con algo **descartado** y su motivo.

## 10. Protocolo de seguridad

El protocolo del proyecto (`docs/protocolo_seguridad.md`) sigue vigente en el TP8: copia descartable, transacción antes de
confirmar, respaldo antes de cambios estructurales y verificación de equivalencia de las vistas nuevas. Su última sección
explica cómo se aplica a esta entrega.
