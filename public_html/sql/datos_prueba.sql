BEGIN;

-- =========================================================
-- DATOS DE PRUEBA PARA Restaurante_Proyecto1
-- Este script asume que:
-- 1) ya se ejecutó sentencias.sql
-- 2) ya existen roles y tipos cargados por el esquema
-- 3) la base está vacía de datos operativos o es un ambiente de pruebas
-- =========================================================

SET TIME ZONE 'America/Bogota';

-- =========================================================
-- 1. USUARIOS
-- =========================================================

INSERT INTO usuarios (id, nombre, clave, fecha_clave, login, token)
OVERRIDING SYSTEM VALUE
VALUES
(1,  'Paula Administradora', digest('Admin1234', 'sha256'), '2026-04-01 08:00:00', 'admin.paula', 'ADM001'),
(2,  'Camilo Maitre',        digest('Maitre1234', 'sha256'), '2026-04-01 08:05:00', 'maitre.camilo', 'MAI001'),

(3,  'Laura Mesera',         digest('Mesero1234', 'sha256'), '2026-04-01 08:10:00', 'mesero.laura', 'MES001'),
(4,  'Diego Mesero',         digest('Mesero1234', 'sha256'), '2026-04-01 08:11:00', 'mesero.diego', 'MES002'),
(5,  'Natalia Mesera',       digest('Mesero1234', 'sha256'), '2026-04-01 08:12:00', 'mesero.natalia', 'MES003'),
(6,  'Felipe Mesero',        digest('Mesero1234', 'sha256'), '2026-04-01 08:13:00', 'mesero.felipe', 'MES004'),
(7,  'Sergio Mesero',        digest('Mesero1234', 'sha256'), '2026-04-01 08:14:00', 'mesero.sergio', 'MES005'),
(8,  'Valentina Mesera',     digest('Mesero1234', 'sha256'), '2026-04-01 08:15:00', 'mesero.valentina', 'MES006'),

(9,  'Julian Cocinero',      digest('Cocina1234', 'sha256'), '2026-04-01 08:20:00', 'cocinero.julian', 'COC001'),
(10, 'Mariana Cocinera',     digest('Cocina1234', 'sha256'), '2026-04-01 08:21:00', 'cocinera.mariana', 'COC002'),
(11, 'Andres Cocinero',      digest('Cocina1234', 'sha256'), '2026-04-01 08:22:00', 'cocinero.andres', 'COC003'),
(12, 'Sofia Cocinera',       digest('Cocina1234', 'sha256'), '2026-04-01 08:23:00', 'cocinera.sofia', 'COC004'),
(13, 'Kevin Cocinero',       digest('Cocina1234', 'sha256'), '2026-04-01 08:24:00', 'cocinero.kevin', 'COC005'),
(14, 'Daniela Cocinera',     digest('Cocina1234', 'sha256'), '2026-04-01 08:25:00', 'cocinera.daniela', 'COC006'),
(15, 'Hugo Cocinero',        digest('Cocina1234', 'sha256'), '2026-04-01 08:26:00', 'cocinero.hugo', 'COC007'),
(16, 'Lina Cocinera',        digest('Cocina1234', 'sha256'), '2026-04-01 08:27:00', 'cocinera.lina', 'COC008'),

(17, 'Ana Torres',           digest('Cliente1234', 'sha256'), '2026-04-01 09:00:00', 'cliente.ana', 'CLI001'),
(18, 'Luis Perez',           digest('Cliente1234', 'sha256'), '2026-04-01 09:01:00', 'cliente.luis', 'CLI002'),
(19, 'Marta Gomez',          digest('Cliente1234', 'sha256'), '2026-04-01 09:02:00', 'cliente.marta', 'CLI003'),
(20, 'Juan Rojas',           digest('Cliente1234', 'sha256'), '2026-04-01 09:03:00', 'cliente.juan', 'CLI004'),
(21, 'Carolina Diaz',        digest('Cliente1234', 'sha256'), '2026-04-01 09:04:00', 'cliente.carolina', 'CLI005'),
(22, 'Sebastian Leon',       digest('Cliente1234', 'sha256'), '2026-04-01 09:05:00', 'cliente.sebastian', 'CLI006'),
(23, 'Paula Castro',         digest('Cliente1234', 'sha256'), '2026-04-01 09:06:00', 'cliente.paulac', 'CLI007'),
(24, 'Ricardo Mejia',        digest('Cliente1234', 'sha256'), '2026-04-01 09:07:00', 'cliente.ricardo', 'CLI008'),
(25, 'Tatiana Ruiz',         digest('Cliente1234', 'sha256'), '2026-04-01 09:08:00', 'cliente.tatiana', 'CLI009'),
(26, 'Andres Mora',          digest('Cliente1234', 'sha256'), '2026-04-01 09:09:00', 'cliente.andresm', 'CLI010'),
(27, 'Claudia Peña',         digest('Cliente1234', 'sha256'), '2026-04-01 09:10:00', 'cliente.claudia', 'CLI011'),
(28, 'Jorge Silva',          digest('Cliente1234', 'sha256'), '2026-04-01 09:11:00', 'cliente.jorge', 'CLI012');

-- =========================================================
-- 2. ACTUACIONES / ROLES
-- =========================================================

INSERT INTO actuaciones (rol_id, usuario_id) VALUES
((SELECT id FROM roles WHERE nombre = 'ADMINISTRADOR'), 1),
((SELECT id FROM roles WHERE nombre = 'MAITRE'), 2),

((SELECT id FROM roles WHERE nombre = 'MESERO'), 3),
((SELECT id FROM roles WHERE nombre = 'MESERO'), 4),
((SELECT id FROM roles WHERE nombre = 'MESERO'), 5),
((SELECT id FROM roles WHERE nombre = 'MESERO'), 6),
((SELECT id FROM roles WHERE nombre = 'MESERO'), 7),
((SELECT id FROM roles WHERE nombre = 'MESERO'), 8),

((SELECT id FROM roles WHERE nombre = 'COCINERO'), 9),
((SELECT id FROM roles WHERE nombre = 'COCINERO'), 10),
((SELECT id FROM roles WHERE nombre = 'COCINERO'), 11),
((SELECT id FROM roles WHERE nombre = 'COCINERO'), 12),
((SELECT id FROM roles WHERE nombre = 'COCINERO'), 13),
((SELECT id FROM roles WHERE nombre = 'COCINERO'), 14),
((SELECT id FROM roles WHERE nombre = 'COCINERO'), 15),
((SELECT id FROM roles WHERE nombre = 'COCINERO'), 16),

((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 17),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 18),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 19),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 20),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 21),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 22),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 23),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 24),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 25),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 26),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 27),
((SELECT id FROM roles WHERE nombre = 'CLIENTE'), 28);

-- =========================================================
-- 3. MESAS
-- Total de sillas = 60
-- =========================================================

INSERT INTO mesas (id, sillas)
OVERRIDING SYSTEM VALUE
VALUES
(1, 2),
(2, 2),
(3, 2),
(4, 4),
(5, 4),
(6, 4),
(7, 4),
(8, 6),
(9, 6),
(10, 2),
(11, 2),
(12, 4),
(13, 4),
(14, 6),
(15, 8);

-- =========================================================
-- 4. PLATOS DEL MENÚ
-- tipos:
-- ENTRADA, PLATO FUERTE, POSTRE, BEBIDA
-- =========================================================

INSERT INTO platos (id, tipo_id, nombre, descripcion, tiempo, precio)
OVERRIDING SYSTEM VALUE
VALUES
(1,  (SELECT id FROM tipos WHERE nombre = 'ENTRADA'),      'Arepa con Hogao',        'Arepa asada con hogao tradicional',                       INTERVAL '15 minutes',  9000.00),
(2,  (SELECT id FROM tipos WHERE nombre = 'ENTRADA'),      'Empanadas Vallunas',     'Empanadas crocantes rellenas de carne y papa',          INTERVAL '18 minutes', 12000.00),
(3,  (SELECT id FROM tipos WHERE nombre = 'ENTRADA'),      'Patacones con Suero',    'Patacones verdes con suero costeño',                    INTERVAL '12 minutes', 10000.00),

(4,  (SELECT id FROM tipos WHERE nombre = 'PLATO FUERTE'), 'Bandeja Paisa',          'Frijoles, arroz, carne molida, chicharron y huevo',     INTERVAL '35 minutes', 32000.00),
(5,  (SELECT id FROM tipos WHERE nombre = 'PLATO FUERTE'), 'Ajiaco Santafereño',     'Sopa de papa con pollo, guascas y alcaparras',          INTERVAL '40 minutes', 28000.00),
(6,  (SELECT id FROM tipos WHERE nombre = 'PLATO FUERTE'), 'Sancocho de Gallina',    'Sancocho tradicional con yuca, platano y mazorca',     INTERVAL '45 minutes', 30000.00),
(7,  (SELECT id FROM tipos WHERE nombre = 'PLATO FUERTE'), 'Lechona Tolimense',      'Lechona servida con arepa blanca',                      INTERVAL '35 minutes', 29000.00),
(8,  (SELECT id FROM tipos WHERE nombre = 'PLATO FUERTE'), 'Arroz con Pollo',        'Arroz con pollo, verduras y papa a la francesa',       INTERVAL '30 minutes', 24000.00),
(9,  (SELECT id FROM tipos WHERE nombre = 'PLATO FUERTE'), 'Mojarra Frita',          'Mojarra entera con arroz de coco y patacones',         INTERVAL '32 minutes', 31000.00),

(10, (SELECT id FROM tipos WHERE nombre = 'POSTRE'),       'Tres Leches',            'Porción de torta tres leches',                          INTERVAL '10 minutes', 11000.00),
(11, (SELECT id FROM tipos WHERE nombre = 'POSTRE'),       'Brevas con Arequipe',    'Brevas en almibar acompañadas con arequipe',           INTERVAL '8 minutes',   9500.00),

(12, (SELECT id FROM tipos WHERE nombre = 'BEBIDA'),       'Jugo de Lulo',           'Jugo natural de lulo en agua',                          INTERVAL '5 minutes',   7000.00),
(13, (SELECT id FROM tipos WHERE nombre = 'BEBIDA'),       'Limonada de Coco',       'Limonada cremosa con coco',                             INTERVAL '6 minutes',   8500.00),
(14, (SELECT id FROM tipos WHERE nombre = 'BEBIDA'),       'Aguapanela con Limon',   'Bebida tradicional fria',                               INTERVAL '4 minutes',   5000.00);

-- =========================================================
-- 5. ESPECIALIDADES DE COCINEROS
-- =========================================================

INSERT INTO especialidades (cocinero_id, plato_id) VALUES
(9, 4),
(9, 5),

(10, 6),
(10, 8),

(11, 7),
(11, 4),

(12, 9),
(12, 3),

(13, 1),
(13, 2),

(14, 10),
(14, 11),

(15, 12),
(15, 13),

(16, 14),
(16, 5);

-- =========================================================
-- 6. RESERVACIONES
-- estado:
-- 1=reservada, 2=ocupada, 3=liberada, 4=cancelada
-- =========================================================

INSERT INTO reservaciones (id, cliente_id, cantidad, estado)
OVERRIDING SYSTEM VALUE
VALUES
(1, 17, 2, 2),
(2, 18, 4, 2),
(3, 19, 6, 2),
(4, 20, 4, 2),
(5, 21, 4, 2),
(6, 22, 5, 2),
(7, 23, 4, 1),
(8, 24, 2, 1),
(9, 25, 6, 3),
(10, 26, 3, 4);

-- =========================================================
-- 7. HORARIOS
-- Tabla particionada por fecha (abril 2026)
-- Todos estos registros caerán en horarios_2026_04
-- =========================================================

INSERT INTO horarios (id, mesa_id, reservacion_id, inicio, duracion)
OVERRIDING SYSTEM VALUE
VALUES
(1,  1, 1, '2026-04-13 11:30:00', INTERVAL '2 hours'),
(2,  4, 2, '2026-04-13 12:00:00', INTERVAL '2 hours'),
(3,  8, 3, '2026-04-13 12:30:00', INTERVAL '2 hours'),
(4,  5, 4, '2026-04-13 13:00:00', INTERVAL '2 hours'),
(5,  6, 5, '2026-04-13 13:15:00', INTERVAL '2 hours'),
(6,  9, 6, '2026-04-13 13:30:00', INTERVAL '2 hours'),
(7,  7, 7, '2026-04-13 14:00:00', INTERVAL '2 hours'),
(8, 10, 8, '2026-04-13 15:00:00', INTERVAL '2 hours'),
(9, 14, 9, '2026-04-13 09:00:00', INTERVAL '2 hours');

-- =========================================================
-- 8. PEDIDOS
-- =========================================================

INSERT INTO pedidos (id, cliente_id, mesero_id, mesa_id)
OVERRIDING SYSTEM VALUE
VALUES
(1, 17, 3, 1),
(2, 18, 4, 4),
(3, 19, 5, 8),
(4, 20, 6, 5),
(5, 21, 7, 6),
(6, 22, 8, 9);

-- =========================================================
-- 9. ORDENES
-- estado:
-- 1=solicitado, 2=preparado, 3=entregado
-- =========================================================

INSERT INTO ordenes (id, plato_id, pedido_id, estado, cantidad, solicitado)
OVERRIDING SYSTEM VALUE
VALUES
(1,  4, 1, 3, 1, '2026-04-13 11:40:00-05'),
(2, 12, 1, 3, 2, '2026-04-13 11:42:00-05'),

(3,  5, 2, 2, 1, '2026-04-13 12:10:00-05'),
(4, 13, 2, 3, 2, '2026-04-13 12:12:00-05'),

(5,  9, 3, 1, 2, '2026-04-13 12:45:00-05'),
(6, 14, 3, 3, 3, '2026-04-13 12:46:00-05'),

(7,  7, 4, 1, 1, '2026-04-13 13:05:00-05'),
(8,  2, 4, 2, 2, '2026-04-13 13:07:00-05'),

(9,  8, 5, 1, 1, '2026-04-13 13:20:00-05'),
(10, 12, 5, 1, 4, '2026-04-13 13:22:00-05'),

(11, 6, 6, 2, 1, '2026-04-13 13:35:00-05'),
(12, 10, 6, 3, 2, '2026-04-13 13:37:00-05');

-- =========================================================
-- 10. PREPARACIONES
-- Cada cocinero debe tener especialidad para el plato
-- =========================================================

INSERT INTO preparaciones (cocinero_id, orden_id) VALUES
(9, 1),    -- Bandeja Paisa
(15, 2),   -- Jugo de Lulo

(9, 3),    -- Ajiaco
(15, 4),   -- Limonada de Coco

(12, 5),   -- Mojarra Frita
(16, 6),   -- Aguapanela con Limon

(11, 7),   -- Lechona
(13, 8),   -- Empanadas

(10, 9),   -- Arroz con Pollo
(15, 10),  -- Jugo de Lulo

(10, 11),  -- Sancocho
(14, 12);  -- Tres Leches

-- =========================================================
-- 11. AJUSTE DE SECUENCIAS
-- Como se insertron IDs manuales, se actualizan las secuencias
-- =========================================================

SELECT setval(pg_get_serial_sequence('usuarios',      'id'), (SELECT MAX(id) FROM usuarios), true);
SELECT setval(pg_get_serial_sequence('mesas',         'id'), (SELECT MAX(id) FROM mesas), true);
SELECT setval(pg_get_serial_sequence('platos',        'id'), (SELECT MAX(id) FROM platos), true);
SELECT setval(pg_get_serial_sequence('reservaciones', 'id'), (SELECT MAX(id) FROM reservaciones), true);
SELECT setval(pg_get_serial_sequence('horarios',      'id'), (SELECT MAX(id) FROM horarios), true);
SELECT setval(pg_get_serial_sequence('pedidos',       'id'), (SELECT MAX(id) FROM pedidos), true);
SELECT setval(pg_get_serial_sequence('ordenes',       'id'), (SELECT MAX(id) FROM ordenes), true);

COMMIT;
