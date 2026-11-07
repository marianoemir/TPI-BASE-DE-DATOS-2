
-- H4b (auditoria U5, 2026-11-07): las rutinas heredaban EXECUTE de PUBLIC,
-- asi que app_web podia ejecutarlas sin que ningun GRANT lo autorizara.
-- Prueba: unidad-5/evidencias/h2b_h4b_prueba.txt
REVOKE EXECUTE ON FUNCTION calcular_total_pedido(bigint), fn_set_subtotal(),
  fn_recalcular_total(), fn_validar_estado_pedido() FROM PUBLIC;
