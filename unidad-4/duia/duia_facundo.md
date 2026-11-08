# Declaración de Uso de IA (DUIA) — Facundo Quiroga

**Integrante:** Facundo Quiroga (Grupo 10)
**Materia:** Base de Datos II (UTN) — Unidad 4
**Proyecto Integrador:** Food Store
**Aporte:** primera versión de `tp_fnbc_control_lote.sql` (Parte 1), subida en la rama `integrante-3` (commit `28cdbca`)
**Herramienta de IA utilizada:** Gemini **
**Aporte adicional (08/11/2026):** migración transaccional `up.sql`/`down.sql` de la Parte 1 (`unidad-4/migracion/`), actualización de la spec (sección 9) e informe `docs/informe/u4.md`
**Herramienta adicional (08/11/2026):** Claude (chat, claude.ai); ver la sección "Actualización del 08/11/2026" al final

> Esta declaración cubre únicamente lo que hizo Facundo. La versión final del script de la Parte 1,
> sus capturas y su verificación en pgAdmin fueron consolidadas por Mariano Chirino y están
> declaradas en `duia_mariano.md`.

---

## Registro de interacciones con IA

Según lo declarado por Facundo, usó **un único prompt**, para generar el archivo completo.

| Herramienta | Para qué se usó | Prompt (resumen) | Qué produjo | Se aceptó / se descartó — por qué |
|---|---|---|---|---|
| Gemini | Generar de una sola vez el contenido completo de `tp_fnbc_control_lote.sql` | Rol de DBA PostgreSQL; se pidió un script en 5 fases (esquema e instancia, diagnóstico teórico en comentarios, descomposición y migración, verificación con conteo y los dos `EXCEPT`, reversión) bajo el patrón expandir–migrar–verificar–contraer. El prompt completo está al final de este documento | Una primera versión del script, subida al repositorio en el commit `28cdbca` | **Descartada y reemplazada.** El prompt no incluía las columnas de la tabla ni los datos del enunciado (decía solo "los 3 registros del enunciado"), y el resultado inventó un esquema propio: una tabla `almacenero` con columnas como `id_almacenero`, `nombre_almacenero` y `turnos`, que no corresponde al punto 4.1 del enunciado (columnas `lote_id`, `deposito_id`, `responsable_control_id`; lotes 501-503, depósitos 30-31, responsables 801-802). Por eso el análisis de dependencias de esa versión (`id_almacenero -> nombre_almacenero, turnos`) tampoco aplicaba. El grupo la rehízo sobre el esquema exacto del enunciado (commit `f583fd1`, "parte de facu corregida") |


## Lo que se aprovechó de esa versión

La **estructura en fases** que pedía el prompt (esquema e instancia, diagnóstico, descomposición y migración, verificación con los dos `EXCEPT`, reversión) es la que quedó en el script final. El contenido concreto (esquema, instancia, dependencias, tablas descompuestas) es el de la versión corregida por el grupo, no el de la primera versión.

## Verificación

- La primera versión **no se dio por válida**: al contrastarla con el punto 4.1 del enunciado se comprobó que no respetaba el esquema, y se reemplazó.
- El análisis correcto, sobre el esquema real, es: F1 `{LoteID, DepositoID} → ResponsableControlID`, F2 `ResponsableControlID → DepositoID`; claves candidatas `{L,D}` y `{L,R}`; los tres atributos son primos; viola FNBC por F2 y cumple 3FN.
- La versión final se ejecutó en pgAdmin sobre `copia_fnbc` (por Mariano): los dos `EXCEPT` dieron 0 filas y el conteo coincidió (3 y 3). Capturas en `capturas/`.

## Prompt utilizado (completo)

```text
Actúa como un DBA y experto en bases de datos PostgreSQL. Necesito que generes el contenido
completo y definitivo para el archivo tp_fnbc_control_lote.sql, correspondiente al ejercicio de
Normalización en Forma Normal de Boyce-Codd (FNBC) del Trabajo Práctico de Base de Datos.

El script debe estar completamente articulado, estructurado en secciones claras con comentarios
explicativos, ser ejecutable de principio a fin sin errores y cumplir rigurosamente con el patrón
de migración "Expandir – Migrar – Verificar – Contraer".

Estructura requerida para el archivo tp_fnbc_control_lote.sql:

1. FASE 1: ESQUEMA INICIAL E INSTANCIA DE EJEMPLO
   - DDL para crear las tablas base originales: lote, deposito y control_lote_almacen (con sus
     PKs y FKs correspondientes).
   - DML con la inserción de la instancia de datos de ejemplo (los 3 registros/INSERT del
     enunciado).

2. FASE 2: DIAGNÓSTICO Y JUSTIFICACIÓN TEÓRICA (En comentarios SQL)
   - Notación formal de Dependencias Funcionales (FDs).
   - Cálculo de clausuras y determinación del conjunto completo de claves candidatas
     (distinguiendo atributos primos y no primos).
   - Justificación formal de por qué control_lote_almacen viola FNBC (identificando la FD
     violatoria y demostrando que su determinante no es superclave).
   - Explicación breve de las 3 anomalías clásicas (Inserción, Modificación, Eliminación)
     presentes en el esquema original.

3. FASE 3: DESCOMPOSICIÓN Y MIGRACIÓN (UP.SQL)
   - DDL para crear las nuevas tablas normalizadas en FNBC con sus PKs y FKs.
   - DML de migración: Instrucciones INSERT INTO ... SELECT para trasvasar los datos desde la
     tabla original hacia las nuevas tablas sin pérdida de información.
   - Creación de la Vista de Compatibilidad que emule la estructura de la tabla original para no
     romper consultas existentes.

4. FASE 4: VERIFICACIÓN Y AUDITORÍA DE INTEGRIDAD
   - Consultas de verificación de conteo de filas (COUNT).
   - Consultas con AMBOS EXCEPT (en las dos direcciones) para demostrar matemáticamente que la
     unión/join es sin pérdida de información y sin generación de tuplas espurias:
     * (Datos de la vista de compatibilidad) EXCEPT (Datos de la tabla original)
     * (Datos de la tabla original) EXCEPT (Datos de la vista de compatibilidad)
     Ambas deben retornar 0 filas.

5. FASE 5: REVERSIÓN Y LIMPIEZA (DOWN.SQL)
   - Bloque de script que permita revertir exactamente los cambios aplicados en la migración
     (eliminar vista, eliminar tablas descompuestas) y restaurar el estado inicial limpiamente.

Por favor, genera el código SQL limpio, formateado profesionalmente y listo para ser copiado
directamente al archivo tp_fnbc_control_lote.sql.
```

## Resumen

| Aspecto | Resultado |
|---|---|
| Herramienta | Gemini (a confirmar por Facundo) |
| Uso declarado | Un único prompt para generar el script completo de la Parte 1 |
| Resultado | Primera versión descartada: inventó un esquema que no correspondía al enunciado |
| Corrección | El grupo rehízo el script sobre el esquema exacto del punto 4.1 (commit `f583fd1`) |
| Aprovechado | La estructura en fases del prompt (incluidos los dos `EXCEPT` y la reversión) |

---

## Actualización del 08/11/2026 — Migración transaccional `up.sql` / `down.sql` (objetivo 2)

**Alcance:** `unidad-4/migracion/` (`setup_previo.sql`, `up.sql`, `down.sql`, `verificar_migracion.sql`), la sección 9 de `specs/spec_parte_1_fnbc_control_lote.md` (commit `b55a4cb`) y `docs/informe/u4.md`. Esta parte sí es de Facundo.
**Herramienta:** Claude (chat, claude.ai), modelo Claude Sonnet 5.5, el 08/11/2026.
**No se usaron OpenCode ni Kiro para generar los archivos de migración.** El protocolo pide spec en Kiro, después OpenCode; en este paso no se cumplió así: los archivos se escribieron primero con Claude y la spec se actualizó después (ver `docs/informe/u4.md`). La edición de la spec si se realizó en Kiro.
**Datos enviados a la IA:** se subió el zip del repositorio. Los datos de ejemplo son ficticios (los usuarios de `data.sql` son inventados) y los nombres de los integrantes aparecen solo como autoría en comentarios. No se enviaron datos reales ni credenciales.

### Registro de interacciones

| Herramienta | Para qué se usó | Prompt (resumen) | Qué produjo | Se aceptó / corrigió / descartó — por qué |
|---|---|---|---|---|
| Claude | Diagnosticar el error `no existe la relación «operacion»` al ejecutar el `up.sql` en `copia_u4` | Se describió el error y se preguntó qué archivos `.sql` cargar antes | Buscó `operacion` en todos los `.sql` del repo, no la encontró, y concluyó que el `up.sql` era una plantilla genérica sin relación con Food Store. Indicó cargar `schema.sql`, `objects.sql` y `data.sql` | **Aceptado y verificado:** Facundo cargó los tres scripts en `copia_u4`. **Corregido:** Claude dijo primero "16 detalles"; los conteos reales son 6 pedidos, 13 detalles y 16 productos, y lo corrigió en el mismo chat |
| Claude | Escribir los cuatro archivos de migración | Se pidió reemplazar el `up.sql` y `down.sql` descartados por los reales, a partir de `tp_fnbc_control_lote.sql` (secciones 1, 4, 5 y 8) | `setup_previo.sql`, `up.sql` (con precondición `R -> D` y verificación dentro de la transacción), `down.sql` y `verificar_migracion.sql`. Claude los probó en un PostgreSQL 16 propio: ciclo completo, `up` y `down` repetidos y falla por datos que violan `R -> D` | **Aceptado tras leerlos línea por línea y ejecutarlos en pgAdmin** (`copia_u4`, 08/11/2026): `up` con `Verificación OK ... 3 / 3` y `COMMIT`; `down` con `COMMIT`; V1 a V5 con lo esperado. **Omisión de Claude:** no incluyó el respaldo previo exigido por el Paso 3; se sacó `copia_u4_20261108_1638.sql` y se repitió el ciclo con respaldo |
| Claude | Detectar y resolver la contradicción del respaldo | Se pidió ayuda con el punto del respaldo | Encontró que el comentario de la sección 5.2 (c) de `tp_desnormalizacion_top_categorias.sql` ("no se requirió respaldo previo") contradice el Paso 3, y recomendó sacar el `pg_dump` y declarar lo ocurrido en lugar de cambiar el protocolo | **Aceptado en la migración** (respaldo hecho). La corrección del comentario de la Parte 2 hecha el 08/11/2026 |
| Claude | Borrador de la sección de migración de `docs/informe/u4.md` | Se pidió el borrador usando la plantilla del informe | Borrador con marcas `[COMPLETAR]` para lo que solo Facundo conocía | **Aceptado con ediciones:** Facundo completó fechas, nombres de capturas, commit y orden spec/código. Claude revisó la versión completada y detectó cuatro errores (año `20026`, extensión del respaldo, `.png` faltante, frase confusa de V5), que se corrigieron. Claude advirtió que el historial de Git mostraría la spec antes del código y recomendó declarar el orden real, lo que se hizo en el informe |
| Claude | Actualizar la spec con el plan de reversión | Se pidió dejar la spec al día | Sección 9 agregada al final, sin tocar el texto original (verificado con `diff`: 0 líneas originales modificadas) y dos avisos de una línea en las secciones 5 y 7 | **Aceptado tras leerla.** Commit `b55a4cb` (2026-11-08), **posterior** al código |

### Verificación

- Los archivos se ejecutaron en `copia_u4` (pgAdmin 4) con respaldo previo; capturas en `unidad-4/capturas/`.
- Los caminos de falla (`up` repetido y datos que violan `R -> D`) se probaron en el PostgreSQL de Claude, no en el de Facundo; no hay captura propia.
- Sin pasada previa con ROLLBACK (Paso 2). El protocolo pide ejecutar primero cada script terminando en ROLLBACK y repetirlo con COMMIT solo después de inspeccionar el efecto. Corrimos up.sql directamente con COMMIT. Lo compensamos con tres controles: respaldo previo con pg_dump (Paso 3), verificación dentro de la transacción (si algo no coincide se lanza una excepción y no se confirma nada) y down.sql probado después del up. Con más tiempo haríamos la pasada con ROLLBACK antes de la definitiva.

