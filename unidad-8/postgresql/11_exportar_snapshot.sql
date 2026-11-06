-- ============================================================
-- FOOD STORE · TP8 · 11_exportar_snapshot.sql
-- Exporta la instantánea a CSV. Es un comando de psql (\copy): se corre con
-- psql -f DESDE LA RAÍZ DEL REPO, así el CSV queda en movil/.
-- ============================================================
\copy (SELECT * FROM v_snapshot_movil ORDER BY producto_id) TO 'movil/servidor_snapshot.csv' CSV HEADER
