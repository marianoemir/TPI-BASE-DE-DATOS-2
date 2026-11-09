== 1 schema ==
== 2 import CSV ==
16
== 3 cargar_catalogo.sql ORIGINAL ==
Parse error near line 6 of cargar_catalogo.sql: near "DO": syntax error
  ROM snapshot_servidor s ON CONFLICT (producto_id) DO UPDATE SET     nombre    
                                      error here ---^
== 3b cargar_catalogo_fix.sql ==
16
== 4 pruebas_sqlite.sql ==
Despu├®s ROLLBACK:|0|0|0|0
C1 - v_catalogo_disponible:|13
Error near line 33 of pruebas_sqlite.sql: CHECK constraint failed: cantidad > 0
C7 - ERROR: cantidad 0 deber├¡a haber sido rechazada
Error near line 41 of pruebas_sqlite.sql: FOREIGN KEY constraint failed
C7 - ERROR: producto inexistente deber├¡a haber sido rechazado
C7 - ERROR: tipo de dato inv├ílido deber├¡a haber sido rechazado
== 5 casos_c2_c5_borradores.sql ==
