SET TIME ZONE 'America/Bogota';

-- Para poder sacar SHA256 se necesita la extensión phcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- BASE DE DATOS: Restaurante_Proyecto1
-- USUARIO: paula
-- =========================================================

-- =========================================================
-- 1. TABLAS BASE
-- =========================================================

CREATE TABLE roles (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE
);

CREATE TABLE usuarios (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre TEXT NOT NULL,
    clave BYTEA NOT NULL,
    fecha_clave TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    login VARCHAR(50) UNIQUE,
    token VARCHAR(13)
);

CREATE TABLE actuaciones (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rol_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
    usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    CONSTRAINT uq_actuacion UNIQUE (rol_id, usuario_id)
);

CREATE TABLE mesas (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sillas INTEGER NOT NULL,
    CONSTRAINT chk_mesas_sillas CHECK (sillas > 0)
);

CREATE TABLE tipos (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE
);

CREATE TABLE platos (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_id INTEGER NOT NULL REFERENCES tipos(id) ON DELETE RESTRICT,
    nombre TEXT NOT NULL UNIQUE,
    descripcion TEXT,
    tiempo INTERVAL NOT NULL,
    precio NUMERIC(10,2) NOT NULL,
    CONSTRAINT chk_platos_tiempo CHECK (tiempo > INTERVAL '0 minutes'),
    CONSTRAINT chk_platos_precio CHECK (precio >= 0)
);

CREATE TABLE reservaciones (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    cantidad INTEGER NOT NULL,
    estado INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT chk_reservaciones_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_reservaciones_estado CHECK (estado IN (1,2,3,4))
);

-- ---------------------------------------------------------
-- TABLA PARTICIONADA POR FECHA: horarios
-- Se particiona por inicio
-- Como es tabla particionada, la PK debe incluir la clave
-- de partición. Por eso usamos (id, inicio).
-- ---------------------------------------------------------
CREATE TABLE horarios (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    mesa_id INTEGER NOT NULL REFERENCES mesas(id) ON DELETE RESTRICT,
    reservacion_id INTEGER NOT NULL REFERENCES reservaciones(id) ON DELETE CASCADE,
    inicio TIMESTAMP NOT NULL,
    duracion INTERVAL NOT NULL DEFAULT INTERVAL '2 hours',
    CONSTRAINT pk_horarios PRIMARY KEY (id, inicio),
    CONSTRAINT chk_horarios_duracion CHECK (
        duracion > INTERVAL '0 minutes'
        AND duracion <= INTERVAL '2 hours'
    )
) PARTITION BY RANGE (inicio);

CREATE TABLE pedidos (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    mesero_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    mesa_id INTEGER NOT NULL REFERENCES mesas(id) ON DELETE RESTRICT,
    CONSTRAINT chk_pedidos_cliente_mesero_distintos CHECK (cliente_id <> mesero_id)
);

CREATE TABLE ordenes (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    plato_id INTEGER NOT NULL REFERENCES platos(id) ON DELETE RESTRICT,
    pedido_id INTEGER NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    estado INTEGER NOT NULL DEFAULT 1,
    cantidad INTEGER NOT NULL,
    solicitado TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ordenes_estado CHECK (estado IN (1,2,3)),
    CONSTRAINT chk_ordenes_cantidad CHECK (cantidad > 0)
);

CREATE TABLE especialidades (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cocinero_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    plato_id INTEGER NOT NULL REFERENCES platos(id) ON DELETE CASCADE,
    CONSTRAINT uq_especialidad UNIQUE (cocinero_id, plato_id)
);

CREATE TABLE preparaciones (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cocinero_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    orden_id INTEGER NOT NULL REFERENCES ordenes(id) ON DELETE CASCADE,
    CONSTRAINT uq_preparacion UNIQUE (cocinero_id, orden_id)
);

-- =========================================================
-- 2. PARTICIONES DE horarios EN LOS TABLESPACES
-- =========================================================

CREATE TABLE horarios_2026_01
PARTITION OF horarios
FOR VALUES FROM ('2026-01-01 00:00:00') TO ('2026-02-01 00:00:00')
TABLESPACE ts_restaurante_1;

CREATE TABLE horarios_2026_02
PARTITION OF horarios
FOR VALUES FROM ('2026-02-01 00:00:00') TO ('2026-03-01 00:00:00')
TABLESPACE ts_restaurante_2;

CREATE TABLE horarios_2026_03
PARTITION OF horarios
FOR VALUES FROM ('2026-03-01 00:00:00') TO ('2026-04-01 00:00:00')
TABLESPACE ts_restaurante_1;

CREATE TABLE horarios_2026_04
PARTITION OF horarios
FOR VALUES FROM ('2026-04-01 00:00:00') TO ('2026-05-01 00:00:00')
TABLESPACE ts_restaurante_2;

CREATE TABLE horarios_2026_05
PARTITION OF horarios
FOR VALUES FROM ('2026-05-01 00:00:00') TO ('2026-06-01 00:00:00')
TABLESPACE ts_restaurante_1;

CREATE TABLE horarios_2026_06
PARTITION OF horarios
FOR VALUES FROM ('2026-06-01 00:00:00') TO ('2026-07-01 00:00:00')
TABLESPACE ts_restaurante_2;

CREATE TABLE horarios_default
PARTITION OF horarios DEFAULT
TABLESPACE ts_restaurante_2;

-- =========================================================
-- 3. ÍNDICES
-- =========================================================

CREATE INDEX idx_actuaciones_usuario ON actuaciones(usuario_id);
CREATE INDEX idx_actuaciones_rol ON actuaciones(rol_id);

CREATE INDEX idx_platos_tipo ON platos(tipo_id);

CREATE INDEX idx_reservaciones_cliente ON reservaciones(cliente_id);
CREATE INDEX idx_reservaciones_estado ON reservaciones(estado);

CREATE INDEX idx_horarios_mesa_inicio ON horarios(mesa_id, inicio);
CREATE INDEX idx_horarios_reservacion ON horarios(reservacion_id);

CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_mesero ON pedidos(mesero_id);
CREATE INDEX idx_pedidos_mesa ON pedidos(mesa_id);

CREATE INDEX idx_ordenes_pedido ON ordenes(pedido_id);
CREATE INDEX idx_ordenes_plato ON ordenes(plato_id);
CREATE INDEX idx_ordenes_estado ON ordenes(estado);
CREATE INDEX idx_ordenes_solicitado ON ordenes(solicitado);

CREATE INDEX idx_especialidades_cocinero ON especialidades(cocinero_id);
CREATE INDEX idx_especialidades_plato ON especialidades(plato_id);

CREATE INDEX idx_preparaciones_cocinero ON preparaciones(cocinero_id);
CREATE INDEX idx_preparaciones_orden ON preparaciones(orden_id);

-- =========================================================
-- 4. DATOS MAESTROS MÍNIMOS
-- =========================================================

INSERT INTO roles (nombre) VALUES
('ADMINISTRADOR'),
('MAITRE'),
('MESERO'),
('COCINERO'),
('CLIENTE');

INSERT INTO tipos (nombre) VALUES
('ENTRADA'),
('PLATO FUERTE'),
('POSTRE'),
('BEBIDA');

-- =========================================================
-- 5. COMENTARIOS DOCUMENTALES
-- =========================================================

COMMENT ON COLUMN reservaciones.estado IS
'1=reservada, 2=ocupada, 3=liberada, 4=cancelada';

COMMENT ON COLUMN ordenes.estado IS
'1=solicitado, 2=preparado, 3=entregado';

COMMENT ON TABLE horarios IS
'Tabla particionada por fecha (columna inicio) y distribuida en dos tablespaces';

-- =========================================================
-- 6. FUNCIÓN AUXILIAR: VALIDAR ROL
-- =========================================================

CREATE OR REPLACE FUNCTION usuario_tiene_rol(p_usuario_id INTEGER, p_rol TEXT)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM actuaciones a
        JOIN roles r ON r.id = a.rol_id
        WHERE a.usuario_id = p_usuario_id
          AND UPPER(r.nombre) = UPPER(p_rol)
    );
$$;

-- =========================================================
-- 7. TRIGGERS DE INTEGRIDAD
-- =========================================================

-- Validar que una reservación la haga un cliente
CREATE OR REPLACE FUNCTION trg_validar_reservacion_cliente()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT usuario_tiene_rol(NEW.cliente_id, 'CLIENTE') THEN
        RAISE EXCEPTION 'El usuario % no tiene rol CLIENTE', NEW.cliente_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validar_reservacion_cliente
BEFORE INSERT OR UPDATE ON reservaciones
FOR EACH ROW
EXECUTE FUNCTION trg_validar_reservacion_cliente();


-- Validar que el mesero realmente sea mesero y el cliente sea cliente
CREATE OR REPLACE FUNCTION trg_validar_pedido_roles()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT usuario_tiene_rol(NEW.mesero_id, 'MESERO') THEN
        RAISE EXCEPTION 'El usuario % no tiene rol MESERO', NEW.mesero_id;
    END IF;

    IF NOT usuario_tiene_rol(NEW.cliente_id, 'CLIENTE') THEN
        RAISE EXCEPTION 'El usuario % no tiene rol CLIENTE', NEW.cliente_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validar_pedido_roles
BEFORE INSERT OR UPDATE ON pedidos
FOR EACH ROW
EXECUTE FUNCTION trg_validar_pedido_roles();


-- Validar que en especialidades solo aparezcan cocineros
CREATE OR REPLACE FUNCTION trg_validar_especialidad_cocinero()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT usuario_tiene_rol(NEW.cocinero_id, 'COCINERO') THEN
        RAISE EXCEPTION 'El usuario % no tiene rol COCINERO', NEW.cocinero_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validar_especialidad_cocinero
BEFORE INSERT OR UPDATE ON especialidades
FOR EACH ROW
EXECUTE FUNCTION trg_validar_especialidad_cocinero();


-- Validar que una preparación la haga un cocinero con especialidad
CREATE OR REPLACE FUNCTION trg_validar_preparacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_tiene_especialidad BOOLEAN;
BEGIN
    IF NOT usuario_tiene_rol(NEW.cocinero_id, 'COCINERO') THEN
        RAISE EXCEPTION 'El usuario % no tiene rol COCINERO', NEW.cocinero_id;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM ordenes o
        JOIN especialidades e
          ON e.plato_id = o.plato_id
         AND e.cocinero_id = NEW.cocinero_id
        WHERE o.id = NEW.orden_id
    )
    INTO v_tiene_especialidad;

    IF NOT v_tiene_especialidad THEN
        RAISE EXCEPTION 'El cocinero % no tiene especialidad para la orden %', NEW.cocinero_id, NEW.orden_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validar_preparacion
BEFORE INSERT OR UPDATE ON preparaciones
FOR EACH ROW
EXECUTE FUNCTION trg_validar_preparacion();


-- Validar horarios:
-- 1) la cantidad debe caber en la mesa
-- 2) una misma mesa no puede tener reservas cruzadas
-- 3) el cupo total del restaurante no se puede exceder
-- 4) una reservación solo tendrá un horario asignado
CREATE OR REPLACE FUNCTION trg_validar_horario()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_cantidad INTEGER;
    v_sillas_mesa INTEGER;
    v_cupo_total INTEGER;
    v_ocupado INTEGER;
BEGIN
    SELECT cantidad
    INTO v_cantidad
    FROM reservaciones
    WHERE id = NEW.reservacion_id;

    IF v_cantidad IS NULL THEN
        RAISE EXCEPTION 'La reservación % no existe', NEW.reservacion_id;
    END IF;

    SELECT sillas
    INTO v_sillas_mesa
    FROM mesas
    WHERE id = NEW.mesa_id;

    IF v_sillas_mesa IS NULL THEN
        RAISE EXCEPTION 'La mesa % no existe', NEW.mesa_id;
    END IF;

    IF v_cantidad > v_sillas_mesa THEN
        RAISE EXCEPTION
        'La mesa % tiene % sillas y la reservación requiere %',
        NEW.mesa_id, v_sillas_mesa, v_cantidad;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM horarios h
        JOIN reservaciones r ON r.id = h.reservacion_id
        WHERE h.mesa_id = NEW.mesa_id
          AND r.estado <> 4
          AND tsrange(h.inicio, h.inicio + h.duracion, '[)')
              && tsrange(NEW.inicio, NEW.inicio + NEW.duracion, '[)')
          AND (TG_OP = 'INSERT' OR h.id <> NEW.id)
    ) THEN
        RAISE EXCEPTION 'La mesa % ya tiene una reservación cruzada en ese horario', NEW.mesa_id;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM horarios h
        WHERE h.reservacion_id = NEW.reservacion_id
          AND (TG_OP = 'INSERT' OR h.id <> NEW.id)
    ) THEN
        RAISE EXCEPTION 'La reservación % ya tiene un horario asignado', NEW.reservacion_id;
    END IF;

    SELECT COALESCE(SUM(sillas), 0)
    INTO v_cupo_total
    FROM mesas;

    SELECT COALESCE(SUM(r.cantidad), 0)
    INTO v_ocupado
    FROM horarios h
    JOIN reservaciones r ON r.id = h.reservacion_id
    WHERE r.estado IN (1,2)
      AND tsrange(h.inicio, h.inicio + h.duracion, '[)')
          && tsrange(NEW.inicio, NEW.inicio + NEW.duracion, '[)')
      AND (TG_OP = 'INSERT' OR h.id <> NEW.id);

    IF v_ocupado + v_cantidad > v_cupo_total THEN
        RAISE EXCEPTION
        'Se excede el cupo total del restaurante. Ocupado=% Nuevo=% Cupo total=%',
        v_ocupado, v_cantidad, v_cupo_total;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER validar_horario
BEFORE INSERT OR UPDATE ON horarios
FOR EACH ROW
EXECUTE FUNCTION trg_validar_horario();
