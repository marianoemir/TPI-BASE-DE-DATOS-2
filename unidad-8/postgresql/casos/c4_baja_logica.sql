-- C4 · el servidor da de baja la Fugazzeta (id 3). Baja LÓGICA: nunca DELETE.
-- Correr solo en la base de PRUEBAS.
UPDATE producto SET eliminado = TRUE WHERE id = 3 AND eliminado = FALSE;
