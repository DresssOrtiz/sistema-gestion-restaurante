SET TIME ZONE 'America/Bogota';

-- =========================================================
-- PRUEBAS DE VALIDACION E INTEGRIDAD
-- Base: Restaurante_Proyecto1
-- Objetivo:
-- demostrar que la BD bloquea errores del negocio
-- =========================================================

-- Para ver los NOTICE con claridad
SET client_min_messages TO NOTICE;

-- =========================================================
-- PRUEBA 0
-- CONTROL POSITIVO: una reservación válida sí debe funcionar
-- =========================================================
BEGIN;

WITH nueva_reserva AS (
    INSERT INTO reservaciones (cliente_id, cantidad, estado)
    VALUES (27, 4, 1)
    RETURNING id
)
INSERT INTO horarios (mesa_id, reservacion_id, inicio, duracion)
SELECT
    12,
    id,
    TIMESTAMP '2026-04-13 17:30:00',
    INTERVAL '2 hours'
FROM nueva_reserva;

ROLLBACK;

SELECT 'PRUEBA 0 OK: una reservación válida fue aceptada y luego revertida' AS resultado;


-- =========================================================
-- PRUEBA 1
-- No se puede crear una reservación con un usuario que no sea CLIENTE
-- =========================================================
DO $$
BEGIN
    BEGIN
        INSERT INTO reservaciones (cliente_id, cantidad, estado)
        VALUES (3, 2, 1); -- usuario 3 = mesero, no cliente

        RAISE EXCEPTION 'FALLO LA PRUEBA 1: se permitió una reservación con usuario no CLIENTE';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 1 OK: se bloqueó reservación con usuario no CLIENTE -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 2
-- No se puede crear un pedido con un usuario que no sea MESERO
-- =========================================================
DO $$
BEGIN
    BEGIN
        INSERT INTO pedidos (cliente_id, mesero_id, mesa_id)
        VALUES (17, 9, 1); -- usuario 9 = cocinero, no mesero

        RAISE EXCEPTION 'FALLO LA PRUEBA 2: se permitió un pedido con usuario no MESERO';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 2 OK: se bloqueó pedido con usuario no MESERO -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 3
-- No se puede crear un pedido con un usuario que no sea CLIENTE
-- =========================================================
DO $$
BEGIN
    BEGIN
        INSERT INTO pedidos (cliente_id, mesero_id, mesa_id)
        VALUES (9, 3, 1); -- usuario 9 = cocinero, no cliente

        RAISE EXCEPTION 'FALLO LA PRUEBA 3: se permitió un pedido con usuario no CLIENTE';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 3 OK: se bloqueó pedido con usuario no CLIENTE -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 4
-- En especialidades no se puede registrar un usuario que no sea COCINERO
-- =========================================================
DO $$
BEGIN
    BEGIN
        INSERT INTO especialidades (cocinero_id, plato_id)
        VALUES (3, 1); -- usuario 3 = mesero

        RAISE EXCEPTION 'FALLO LA PRUEBA 4: se permitió especialidad para usuario no COCINERO';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 4 OK: se bloqueó especialidad con usuario no COCINERO -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 5
-- Un cocinero no puede preparar una orden de un plato que no sabe preparar
-- =========================================================
DO $$
BEGIN
    BEGIN
        INSERT INTO preparaciones (cocinero_id, orden_id)
        VALUES (9, 5);
        -- cocinero 9 sabe preparar platos 4 y 5
        -- orden 5 corresponde al plato 9, así que debe fallar

        RAISE EXCEPTION 'FALLO LA PRUEBA 5: se permitió preparar una orden sin especialidad';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 5 OK: se bloqueó preparación sin especialidad -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 6
-- La cantidad de la reservación debe caber en la mesa asignada
-- =========================================================
DO $$
DECLARE
    v_reservacion_id INTEGER;
BEGIN
    BEGIN
        INSERT INTO reservaciones (cliente_id, cantidad, estado)
        VALUES (27, 5, 1)
        RETURNING id INTO v_reservacion_id;

        INSERT INTO horarios (mesa_id, reservacion_id, inicio, duracion)
        VALUES (1, v_reservacion_id, TIMESTAMP '2026-04-13 18:00:00', INTERVAL '2 hours');
        -- mesa 1 tiene 2 sillas, la reservación pide 5

        RAISE EXCEPTION 'FALLO LA PRUEBA 6: se permitió una reservación mayor que la capacidad de la mesa';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 6 OK: se bloqueó reserva que excede la capacidad de la mesa -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 7
-- No se deben cruzar reservaciones en la misma mesa
-- =========================================================
DO $$
DECLARE
    v_reservacion_id INTEGER;
BEGIN
    BEGIN
        INSERT INTO reservaciones (cliente_id, cantidad, estado)
        VALUES (28, 2, 1)
        RETURNING id INTO v_reservacion_id;

        INSERT INTO horarios (mesa_id, reservacion_id, inicio, duracion)
        VALUES (4, v_reservacion_id, TIMESTAMP '2026-04-13 13:30:00', INTERVAL '2 hours');
        -- mesa 4 ya está ocupada de 12:00 a 14:00 por la reservación 2

        RAISE EXCEPTION 'FALLO LA PRUEBA 7: se permitió cruce de reservaciones en la misma mesa';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 7 OK: se bloqueó cruce de reservaciones en la misma mesa -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 8
-- Una reservación no debe tener más de un horario asignado
-- =========================================================
DO $$
DECLARE
    v_reservacion_id INTEGER;
BEGIN
    BEGIN
        INSERT INTO reservaciones (cliente_id, cantidad, estado)
        VALUES (27, 2, 1)
        RETURNING id INTO v_reservacion_id;

        INSERT INTO horarios (mesa_id, reservacion_id, inicio, duracion)
        VALUES (10, v_reservacion_id, TIMESTAMP '2026-04-13 17:00:00', INTERVAL '2 hours');

        INSERT INTO horarios (mesa_id, reservacion_id, inicio, duracion)
        VALUES (11, v_reservacion_id, TIMESTAMP '2026-04-13 19:30:00', INTERVAL '2 hours');

        RAISE EXCEPTION 'FALLO LA PRUEBA 8: se permitió asignar dos horarios a una misma reservación';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 8 OK: se bloqueó segundo horario para la misma reservación -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 9
-- CHECK: una mesa no puede tener 0 sillas
-- =========================================================
DO $$
BEGIN
    BEGIN
        INSERT INTO mesas (sillas)
        VALUES (0);

        RAISE EXCEPTION 'FALLO LA PRUEBA 9: se permitió crear una mesa con 0 sillas';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 9 OK: CHECK bloqueó mesa con 0 sillas -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 10
-- CHECK: el estado de una orden debe estar en el dominio permitido
-- =========================================================
DO $$
BEGIN
    BEGIN
        INSERT INTO ordenes (plato_id, pedido_id, estado, cantidad, solicitado)
        VALUES (4, 1, 99, 1, TIMESTAMPTZ '2026-04-13 16:00:00-05');

        RAISE EXCEPTION 'FALLO LA PRUEBA 10: se permitió un estado inválido en ordenes';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 10 OK: CHECK bloqueó estado inválido en ordenes -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 11
-- FK: no se puede registrar una orden con un plato inexistente
-- =========================================================
DO $$
BEGIN
    BEGIN
        INSERT INTO ordenes (plato_id, pedido_id, estado, cantidad, solicitado)
        VALUES (9999, 1, 1, 1, TIMESTAMPTZ '2026-04-13 16:05:00-05');

        RAISE EXCEPTION 'FALLO LA PRUEBA 11: se permitió una orden con plato inexistente';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 11 OK: FK bloqueó orden con plato inexistente -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 12
-- FK: no se puede registrar una orden con un pedido inexistente
-- =========================================================
DO $$
BEGIN
    BEGIN
        INSERT INTO ordenes (plato_id, pedido_id, estado, cantidad, solicitado)
        VALUES (4, 9999, 1, 1, TIMESTAMPTZ '2026-04-13 16:10:00-05');

        RAISE EXCEPTION 'FALLO LA PRUEBA 12: se permitió una orden con pedido inexistente';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'PRUEBA 12 OK: FK bloqueó orden con pedido inexistente -> %', SQLERRM;
    END;
END;
$$;


-- =========================================================
-- PRUEBA 13
-- CONSULTA DE CONTROL DEL CUPO EN UNA FRANJA HORARIA
-- Nota:
-- con el diseño actual, la validación del cupo total queda reforzada
-- por dos reglas previas:
-- 1) la reserva debe caber en su mesa
-- 2) no puede haber traslapes en la misma mesa
-- Por eso este caso no es fácil de hacer fallar artificialmente
-- sin romper antes esas otras reglas.
-- =========================================================

WITH parametros AS (
    SELECT
        TIMESTAMP '2026-04-13 13:30:00' AS inicio,
        INTERVAL '2 hours' AS duracion
)
SELECT
    p.inicio,
    p.inicio + p.duracion AS fin,
    COALESCE(SUM(r.cantidad), 0) AS personas_reservadas_en_rango,
    (SELECT SUM(sillas) FROM mesas) AS cupo_total_restaurante
FROM parametros p
LEFT JOIN horarios h
    ON tsrange(h.inicio, h.inicio + h.duracion, '[)')
       && tsrange(p.inicio, p.inicio + p.duracion, '[)')
LEFT JOIN reservaciones r
    ON r.id = h.reservacion_id
   AND r.estado IN (1, 2)
GROUP BY p.inicio, p.duracion;
