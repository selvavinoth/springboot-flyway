CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


CREATE TABLE IF NOT EXISTS user_activedirectory_map122
(
    pkid           UUID NOT NULL DEFAULT uuid_generate_v1(),
    xk_objectguid  UUID NOT NULL,
    samaccountname VARCHAR(256),
    fk_users       UUID NOT NULL
);
