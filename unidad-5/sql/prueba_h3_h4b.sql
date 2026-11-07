\set ON_ERROR_STOP on
BEGIN;

\echo === ANTES: membresias entre roles de grupo
SELECT g.rolname AS grupo, m.rolname AS miembro
FROM pg_auth_members am
JOIN pg_roles g ON g.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE g.rolname IN ('rol_app_lectura','rol_app_escritura','rol_app_auth','rol_soporte','rol_reportes')
  AND m.rolname IN ('rol_app_lectura','rol_app_escritura','rol_app_auth','rol_soporte','rol_reportes');

\echo === ANTES: EXECUTE de app_web
SELECT has_function_privilege('app_web','calcular_total_pedido(bigint)','EXECUTE') AS calcular_total_pedido,
       has_function_privilege('app_web','fn_set_subtotal()','EXECUTE')            AS fn_set_subtotal,
       has_function_privilege('app_web','fn_recalcular_total()','EXECUTE')        AS fn_recalcular_total,
       has_function_privilege('app_web','fn_validar_estado_pedido()','EXECUTE')   AS fn_validar_estado_pedido;

DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT g.rolname AS grupo, m.rolname AS miembro
    FROM pg_auth_members am
    JOIN pg_roles g ON g.oid = am.roleid
    JOIN pg_roles m ON m.oid = am.member
    WHERE g.rolname IN ('rol_app_lectura','rol_app_escritura','rol_app_auth','rol_soporte','rol_reportes')
      AND m.rolname IN ('rol_app_lectura','rol_app_escritura','rol_app_auth','rol_soporte','rol_reportes')
  LOOP
    EXECUTE format('REVOKE %I FROM %I', r.grupo, r.miembro);
  END LOOP;
END $$;

REVOKE EXECUTE ON FUNCTION calcular_total_pedido(bigint), fn_set_subtotal(),
  fn_recalcular_total(), fn_validar_estado_pedido() FROM PUBLIC;

\echo === DESPUES: membresias
SELECT g.rolname AS grupo, m.rolname AS miembro
FROM pg_auth_members am
JOIN pg_roles g ON g.oid = am.roleid
JOIN pg_roles m ON m.oid = am.member
WHERE g.rolname IN ('rol_app_lectura','rol_app_escritura','rol_app_auth','rol_soporte','rol_reportes')
  AND m.rolname IN ('rol_app_lectura','rol_app_escritura','rol_app_auth','rol_soporte','rol_reportes');

\echo === DESPUES: EXECUTE de app_web
SELECT has_function_privilege('app_web','calcular_total_pedido(bigint)','EXECUTE') AS calcular_total_pedido,
       has_function_privilege('app_web','fn_set_subtotal()','EXECUTE')            AS fn_set_subtotal,
       has_function_privilege('app_web','fn_recalcular_total()','EXECUTE')        AS fn_recalcular_total,
       has_function_privilege('app_web','fn_validar_estado_pedido()','EXECUTE')   AS fn_validar_estado_pedido;

ROLLBACK;
