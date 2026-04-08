SET TIME ZONE 'America/Bogota';

-- Para poder sacar SHA256 se necesita la extensión phcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Se agrega el campo login y token a usuarios
ALTER TABLE usuarios ADD COLUMN login VARCHAR(50) UNIQUE;
ALTER TABLE usuarios ADD COLUMN token VARCHAR(13);