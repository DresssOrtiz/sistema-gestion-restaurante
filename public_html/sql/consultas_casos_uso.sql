SET TIME ZONE 'America/Bogota';

-- =========================================================
-- CONSULTAS SQL POR CASO DE USO
-- Base de datos: Restaurante_Proyecto1
-- =========================================================

-- =========================================================
-- CASO DE USO 1. GESTION DE MESAS
-- =========================================================

-- 1.1 Listar todas las mesas
SELECT id, sillas
FROM mesas
ORDER BY id;

-- 1.2 Calcular el cupo total del restaurante
SELECT SUM(sillas) AS cupo_total_restaurante
FROM mesas;

-- 1.3 Ver mesas con reservaciones asignadas
SELECT
    m.id AS mesa_id,
    m.sillas,
    h.inicio,
    h.inicio + h.duracion AS fin,
    r.id AS reservacion_id,
    r.cantidad AS personas_reserva
FROM mesas m
LEFT JOIN horarios h ON h.mesa_id = m.id
LEFT JOIN reservaciones r ON r.id = h.reservacion_id
ORDER BY m.id, h.inicio;

-- 1.4 DEMO: agregar, modificar y eliminar una mesa
BEGIN;

INSERT INTO mesas (sillas)
VALUES (4)
RETURNING *;

UPDATE mesas
SET sillas = 6
WHERE id = currval(pg_get_serial_sequence('mesas', 'id'))
RETURNING *;

DELETE FROM mesas
WHERE id = currval(pg_get_serial_sequence('mesas', 'id'))
RETURNING *;

ROLLBACK;


-- =========================================================
-- CASO DE USO 2. GESTION DE RESERVACIONES
-- =========================================================

-- 2.1 Listar reservaciones con cliente, mesa y horario
SELECT
    r.id AS reservacion,
    u.nombre AS cliente,
    r.cantidad,
    CASE r.estado
        WHEN 1 THEN 'reservada'
        WHEN 2 THEN 'ocupada'
        WHEN 3 THEN 'liberada'
        WHEN 4 THEN 'cancelada'
    END AS estado,
    h.mesa_id,
    h.inicio,
    h.duracion,
    h.inicio + h.duracion AS fin
FROM reservaciones r
JOIN usuarios u ON u.id = r.cliente_id
LEFT JOIN horarios h ON h.reservacion_id = r.id
ORDER BY h.inicio;

-- 2.2 Validar si una mesa está disponible en un horario dado
WITH parametros AS (
    SELECT
        4::INTEGER AS mesa_id,
        TIMESTAMP '2026-04-13 16:00:00' AS inicio,
        INTERVAL '2 hours' AS duracion
)
SELECT
    p.mesa_id,
    p.inicio,
    p.inicio + p.duracion AS fin,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM horarios h
            JOIN reservaciones r ON r.id = h.reservacion_id
            WHERE h.mesa_id = p.mesa_id
              AND r.estado <> 4
              AND tsrange(h.inicio, h.inicio + h.duracion, '[)')
                  && tsrange(p.inicio, p.inicio + p.duracion, '[)')
        )
        THEN 'NO DISPONIBLE'
        ELSE 'DISPONIBLE'
    END AS disponibilidad
FROM parametros p;

-- 2.3 Validar cupo del restaurante para un horario dado
WITH parametros AS (
    SELECT
        TIMESTAMP '2026-04-13 13:00:00' AS inicio,
        INTERVAL '2 hours' AS duracion
)
SELECT
    p.inicio,
    p.inicio + p.duracion AS fin,
    COALESCE(SUM(r.cantidad), 0) AS personas_reservadas_en_rango,
    (SELECT SUM(sillas) FROM mesas) AS cupo_total
FROM parametros p
LEFT JOIN horarios h
    ON tsrange(h.inicio, h.inicio + h.duracion, '[)')
       && tsrange(p.inicio, p.inicio + p.duracion, '[)')
LEFT JOIN reservaciones r
    ON r.id = h.reservacion_id
   AND r.estado IN (1, 2)
GROUP BY p.inicio, p.duracion;

-- 2.4 DEMO: crear una reservación válida con su horario
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
FROM nueva_reserva
RETURNING *;

ROLLBACK;

-- 2.5 Reservaciones próximas a comenzar (notificación al maitre)
WITH referencia AS (
    SELECT TIMESTAMP '2026-04-13 12:45:00' AS ahora
)
SELECT
    r.id AS reservacion,
    u.nombre AS cliente,
    h.mesa_id,
    h.inicio,
    h.inicio + h.duracion AS fin
FROM referencia ref
JOIN horarios h
    ON h.inicio BETWEEN ref.ahora AND ref.ahora + INTERVAL '30 minutes'
JOIN reservaciones r
    ON r.id = h.reservacion_id
JOIN usuarios u
    ON u.id = r.cliente_id
WHERE r.estado = 1
ORDER BY h.inicio;


-- =========================================================
-- CASO DE USO 3. GESTION DEL MENU
-- =========================================================

-- 3.1 Listar menú completo por categoría
SELECT
    t.nombre AS categoria,
    p.id,
    p.nombre AS plato,
    p.descripcion,
    p.tiempo,
    p.precio
FROM platos p
JOIN tipos t ON t.id = p.tipo_id
ORDER BY t.nombre, p.nombre;

-- 3.2 Consultar platos por categoría
SELECT
    p.id,
    p.nombre,
    p.descripcion,
    p.tiempo,
    p.precio
FROM platos p
JOIN tipos t ON t.id = p.tipo_id
WHERE t.nombre = 'PLATO FUERTE'
ORDER BY p.nombre;

-- 3.3 DEMO: agregar, modificar y eliminar un ítem del menú
BEGIN;

INSERT INTO platos (tipo_id, nombre, descripcion, tiempo, precio)
VALUES (
    (SELECT id FROM tipos WHERE nombre = 'POSTRE'),
    'Oblea con Arequipe',
    'Oblea tradicional con arequipe y queso',
    INTERVAL '7 minutes',
    12000.00
)
RETURNING *;

UPDATE platos
SET precio = 13000.00
WHERE id = currval(pg_get_serial_sequence('platos', 'id'))
RETURNING *;

DELETE FROM platos
WHERE id = currval(pg_get_serial_sequence('platos', 'id'))
RETURNING *;

ROLLBACK;


-- =========================================================
-- CASO DE USO 4. REGISTRO DE PEDIDOS
-- =========================================================

-- 4.1 Listar pedidos con cliente, mesero y mesa
SELECT
    p.id AS pedido,
    c.nombre AS cliente,
    m.nombre AS mesero,
    p.mesa_id
FROM pedidos p
JOIN usuarios c ON c.id = p.cliente_id
JOIN usuarios m ON m.id = p.mesero_id
ORDER BY p.id;

-- 4.2 Listar detalle de cada pedido
SELECT
    pe.id AS pedido,
    cli.nombre AS cliente,
    mes.nombre AS mesero,
    pe.mesa_id,
    o.id AS orden,
    pl.nombre AS plato,
    o.cantidad,
    CASE o.estado
        WHEN 1 THEN 'solicitado'
        WHEN 2 THEN 'preparado'
        WHEN 3 THEN 'entregado'
    END AS estado,
    o.solicitado
FROM pedidos pe
JOIN usuarios cli ON cli.id = pe.cliente_id
JOIN usuarios mes ON mes.id = pe.mesero_id
JOIN ordenes o ON o.pedido_id = pe.id
JOIN platos pl ON pl.id = o.plato_id
ORDER BY pe.id, o.id;

-- 4.3 DEMO: crear un pedido con múltiples ítems
BEGIN;

WITH nuevo_pedido AS (
    INSERT INTO pedidos (cliente_id, mesero_id, mesa_id)
    VALUES (24, 3, 10)
    RETURNING id
)
INSERT INTO ordenes (plato_id, pedido_id, estado, cantidad, solicitado)
SELECT 4,  id, 1, 1, TIMESTAMPTZ '2026-04-13 15:10:00-05' FROM nuevo_pedido
UNION ALL
SELECT 12, id, 1, 2, TIMESTAMPTZ '2026-04-13 15:11:00-05' FROM nuevo_pedido
RETURNING *;

ROLLBACK;

-- 4.4 Actualizar estado de una orden
BEGIN;

UPDATE ordenes
SET estado = 2
WHERE id = 5
RETURNING *;

ROLLBACK;

-- 4.5 Vista del cocinero:
-- solo pedidos solicitados, solo platos que sabe preparar,
-- ordenados por mayor tiempo de preparación
SELECT
    o.id AS orden,
    pl.nombre AS plato,
    pl.tiempo,
    o.cantidad,
    o.solicitado
FROM ordenes o
JOIN platos pl
    ON pl.id = o.plato_id
JOIN especialidades e
    ON e.plato_id = o.plato_id
WHERE e.cocinero_id = 9
  AND o.estado = 1
ORDER BY pl.tiempo DESC, o.solicitado ASC;


-- =========================================================
-- CASO DE USO 5. GESTION DE ENTREGAS
-- =========================================================

-- 5.1 Órdenes listas para entregar (notificación al mesero)
SELECT
    pe.id AS pedido,
    pe.mesa_id,
    mes.nombre AS mesero,
    o.id AS orden,
    pl.nombre AS plato,
    o.cantidad,
    o.solicitado
FROM ordenes o
JOIN pedidos pe ON pe.id = o.pedido_id
JOIN usuarios mes ON mes.id = pe.mesero_id
JOIN platos pl ON pl.id = o.plato_id
WHERE o.estado = 2
ORDER BY pe.mesa_id, o.solicitado;

-- 5.2 Marcar una orden como entregada
BEGIN;

UPDATE ordenes
SET estado = 3
WHERE id = 3
RETURNING *;

ROLLBACK;

-- 5.3 Ver órdenes ya entregadas
SELECT
    o.id AS orden,
    pe.id AS pedido,
    pe.mesa_id,
    pl.nombre AS plato,
    o.cantidad,
    o.solicitado
FROM ordenes o
JOIN pedidos pe ON pe.id = o.pedido_id
JOIN platos pl ON pl.id = o.plato_id
WHERE o.estado = 3
ORDER BY o.solicitado;


-- =========================================================
-- CASO DE USO 6. REPORTES Y ESTADISTICAS
-- =========================================================

-- 6.1 Reporte de reservaciones por día
SELECT
    date_trunc('day', h.inicio)::date AS dia,
    COUNT(*) AS total_reservaciones,
    SUM(r.cantidad) AS total_personas
FROM horarios h
JOIN reservaciones r ON r.id = h.reservacion_id
GROUP BY 1
ORDER BY 1;

-- 6.2 Reporte de reservaciones por semana
SELECT
    date_trunc('week', h.inicio)::date AS semana,
    COUNT(*) AS total_reservaciones,
    SUM(r.cantidad) AS total_personas
FROM horarios h
JOIN reservaciones r ON r.id = h.reservacion_id
GROUP BY 1
ORDER BY 1;

-- 6.3 Reporte de reservaciones por mes
SELECT
    date_trunc('month', h.inicio)::date AS mes,
    COUNT(*) AS total_reservaciones,
    SUM(r.cantidad) AS total_personas
FROM horarios h
JOIN reservaciones r ON r.id = h.reservacion_id
GROUP BY 1
ORDER BY 1;

-- 6.4 Reporte de platos más solicitados
SELECT
    pl.nombre AS plato,
    SUM(o.cantidad) AS total_unidades,
    COUNT(*) AS veces_en_pedidos
FROM ordenes o
JOIN platos pl ON pl.id = o.plato_id
GROUP BY pl.nombre
ORDER BY total_unidades DESC, veces_en_pedidos DESC, pl.nombre;

-- 6.5 Reporte de ventas totales por día
SELECT
    date_trunc('day', o.solicitado)::date AS dia,
    SUM(o.cantidad * pl.precio) AS ventas_totales
FROM ordenes o
JOIN platos pl ON pl.id = o.plato_id
WHERE o.estado = 3
GROUP BY 1
ORDER BY 1;

-- 6.6 Reporte de ventas totales por semana
SELECT
    date_trunc('week', o.solicitado)::date AS semana,
    SUM(o.cantidad * pl.precio) AS ventas_totales
FROM ordenes o
JOIN platos pl ON pl.id = o.plato_id
WHERE o.estado = 3
GROUP BY 1
ORDER BY 1;

-- 6.7 Reporte de ventas totales por mes
SELECT
    date_trunc('month', o.solicitado)::date AS mes,
    SUM(o.cantidad * pl.precio) AS ventas_totales
FROM ordenes o
JOIN platos pl ON pl.id = o.plato_id
WHERE o.estado = 3
GROUP BY 1
ORDER BY 1;


-- =========================================================
-- CONSULTAS EXTRA UTILES
-- =========================================================

-- E1. Historial de reservaciones de un cliente
SELECT
    u.nombre AS cliente,
    r.id AS reservacion,
    r.cantidad,
    CASE r.estado
        WHEN 1 THEN 'reservada'
        WHEN 2 THEN 'ocupada'
        WHEN 3 THEN 'liberada'
        WHEN 4 THEN 'cancelada'
    END AS estado,
    h.mesa_id,
    h.inicio
FROM reservaciones r
JOIN usuarios u ON u.id = r.cliente_id
LEFT JOIN horarios h ON h.reservacion_id = r.id
WHERE r.cliente_id = 17
ORDER BY h.inicio;

-- E2. Historial de pedidos de un cliente
SELECT
    cli.nombre AS cliente,
    pe.id AS pedido,
    pe.mesa_id,
    pl.nombre AS plato,
    o.cantidad,
    CASE o.estado
        WHEN 1 THEN 'solicitado'
        WHEN 2 THEN 'preparado'
        WHEN 3 THEN 'entregado'
    END AS estado,
    o.solicitado
FROM pedidos pe
JOIN usuarios cli ON cli.id = pe.cliente_id
JOIN ordenes o ON o.pedido_id = pe.id
JOIN platos pl ON pl.id = o.plato_id
WHERE pe.cliente_id = 17
ORDER BY pe.id, o.id;

-- E3. Empleados por rol
SELECT
    r.nombre AS rol,
    u.id AS usuario_id,
    u.nombre AS usuario
FROM actuaciones a
JOIN roles r ON r.id = a.rol_id
JOIN usuarios u ON u.id = a.usuario_id
WHERE r.nombre IN ('ADMINISTRADOR', 'MAITRE', 'MESERO', 'COCINERO')
ORDER BY r.nombre, u.nombre;

-- E4. Cocineros y platos que saben preparar
SELECT
    u.nombre AS cocinero,
    p.nombre AS plato
FROM especialidades e
JOIN usuarios u ON u.id = e.cocinero_id
JOIN platos p ON p.id = e.plato_id
ORDER BY u.nombre, p.nombre;
