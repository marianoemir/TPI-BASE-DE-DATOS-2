-- =====================================================================
-- TRABAJO PRÁCTICO UNIDAD 7: NoSQL y nuevas formas de almacenamiento
-- Consultas en PostgreSQL (Consigna 5) - Food Store
-- Integrante: Andrés
-- =====================================================================

-- ---------------------------------------------------------------------
-- b) Filtrar pedidos por un estado existente ("PENDIENTE")
-- Limitado a los IDs vigentes analizados [1, 2, 3, 5, 6, 7, 8]
-- ---------------------------------------------------------------------
SELECT id, estado, fecha, total
FROM pedido
WHERE estado = 'PENDIENTE'
  AND eliminado = FALSE
  AND id IN (1, 2, 3, 5, 6, 7, 8)
ORDER BY id;

-- ---------------------------------------------------------------------
-- c) Buscar pedidos que contengan un producto determinado (producto_id = 1)
-- JOIN entre pedido y detalle_pedido validando la baja lógica en ambas tablas
-- ---------------------------------------------------------------------
SELECT DISTINCT p.id, p.estado, p.fecha, p.total
FROM pedido p
JOIN detalle_pedido dp ON p.id = dp.pedido_id
WHERE dp.producto_id = 1
  AND p.eliminado = FALSE
  AND dp.eliminado = FALSE
  AND p.id IN (1, 2, 3, 5, 6, 7, 8)
ORDER BY p.id;