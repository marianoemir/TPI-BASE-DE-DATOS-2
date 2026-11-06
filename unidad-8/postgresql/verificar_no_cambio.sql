-- ============================================================
-- FOOD STORE · TP8 · verificar_no_cambio.sql
-- Solo LEE. Correrlo ANTES y DESPUÉS de simular: las cuatro columnas tienen
-- que dar lo mismo. Prueba que la tablet no tocó pedidos ni stock.
-- (Los cambios de precio y de baja de C2 y C4 los hace el "servidor" a propósito
--  con postgresql/casos/*.sql; no tocan el stock ni los pedidos.)
-- ============================================================
SELECT (SELECT count(*) FROM pedido)         AS pedidos,
       (SELECT count(*) FROM detalle_pedido) AS detalles,
       (SELECT sum(stock) FROM producto)     AS stock_total,
       (SELECT md5(string_agg(id || ':' || stock, ',' ORDER BY id)) FROM producto) AS huella_stock;
