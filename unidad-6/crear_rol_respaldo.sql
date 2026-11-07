-- crear_rol_respaldo.sql
-- Ejecutar manualmente como administrador local, conectado a foodstore.
-- No contiene ni define contrasenas. La clave de operador_respaldo se configura
-- fuera del repositorio y se guarda solo en pgpass.conf.

BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'operador_respaldo') THEN
        CREATE ROLE operador_respaldo LOGIN NOINHERIT
            NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
    END IF;
END $$;

ALTER ROLE operador_respaldo LOGIN NOINHERIT
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;

GRANT CONNECT ON DATABASE foodstore TO operador_respaldo;
GRANT USAGE ON SCHEMA public TO operador_respaldo;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO operador_respaldo;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO operador_respaldo;

-- Ajusta los objetos futuros del rol que ejecute este script. Si otro rol crea
-- objetos, ese dueño debe repetir el ALTER DEFAULT PRIVILEGES correspondiente.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO operador_respaldo;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON SEQUENCES TO operador_respaldo;

COMMIT;

SELECT rolname,
       rolsuper,
       rolcreatedb,
       rolcreaterole,
       rolreplication,
       rolbypassrls,
       rolcanlogin,
       rolinherit
FROM pg_roles
WHERE rolname = 'operador_respaldo';
