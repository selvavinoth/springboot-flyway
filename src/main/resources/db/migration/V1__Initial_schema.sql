-- postgres 9.2 compatible
CREATE EXTENSION "uuid-ossp";

CREATE TYPE ISE_EVENT_LEVEL AS ENUM ('DEBUG', 'ERROR', 'INFO', 'WARN');
CREATE TYPE ISE_EVENT_ENTITY_TYPE AS ENUM ('GROUP', 'MAC_ADDRESS', 'PROPERTY', 'USER', 'USER_ROLE');
CREATE TYPE ISE_EVENT_TYPE AS ENUM ('GROUP_ADD', 'GROUP_REMOVE', 'GROUP_SYNC', 'GROUP_UPDATE', 'MAC_ADDRESS_ACCEPT_GRACE', 'MAC_ADDRESS_ADD', 'MAC_ADDRESS_BULK_REMOVE', 'MAC_ADDRESS_IMPORT', 'MAC_ADDRESS_REMOVE', 'MAC_ADDRESS_SYNC', 'MAC_ADDRESS_UPDATE', 'PROPERTY_UPDATE', 'USER_ADD', 'USER_LOGIN', 'USER_LOGOUT', 'USER_UPDATE', 'USER_REMOVE', 'USER_ROLE_ADD', 'USER_ROLE_UPDATE');


CREATE TABLE user_roles
(
    role           VARCHAR(45) NOT NULL UNIQUE,
    grace_period   INTEGER              DEFAULT 700000,
    description    VARCHAR(250),
    is_gracer      BOOLEAN              DEFAULT FALSE,
    rank           INTEGER     NOT NULL DEFAULT 0,
    version_number INTEGER     NOT NULL DEFAULT 0,
    CONSTRAINT user_roles_key PRIMARY KEY (role)
);


/* FOR APPLICATION USER */
CREATE TABLE application_user_roles
(
    role           VARCHAR(45) NOT NULL UNIQUE,
    grace_period   INTEGER              DEFAULT 700000,
    description    VARCHAR(250),
    is_gracer      BOOLEAN              DEFAULT FALSE,
    rank           INTEGER     NOT NULL DEFAULT 0,
    version_number INTEGER     NOT NULL DEFAULT 0,
    CONSTRAINT application_user_roles_key PRIMARY KEY (role)
);


CREATE TABLE application_users
(
    username       VARCHAR(45) NOT NULL,
    email          VARCHAR,
    password       VARCHAR     NOT NULL,
    role           VARCHAR(45) NOT NULL,
    enabled        BOOLEAN     NOT NULL,
    version_number INTEGER     NOT NULL DEFAULT 0,
    CONSTRAINT application_users_pkey PRIMARY KEY (username),
    CONSTRAINT application_user_roles_fk FOREIGN KEY (role) REFERENCES application_user_roles (role) ON DELETE NO ACTION ON UPDATE NO ACTION
);


CREATE TABLE users
(
    pkid           UUID        NOT NULL UNIQUE DEFAULT uuid_generate_v1mc(),
    username       VARCHAR(45) NOT NULL,
    email          VARCHAR     NOT NULL UNIQUE,
    password       VARCHAR     NOT NULL,
    role           VARCHAR(45) NOT NULL,
    enabled        BOOLEAN     NOT NULL,
    version_number INTEGER     NOT NULL        DEFAULT 0,
    CONSTRAINT users_pkey PRIMARY KEY (pkid),
    CONSTRAINT users_user_roles_fk FOREIGN KEY (role) REFERENCES user_roles (role) ON DELETE NO ACTION ON UPDATE NO ACTION
);


CREATE TABLE events
(
    id            VARCHAR(45)     NOT NULL,
    level         ISE_EVENT_LEVEL NOT NULL,
    entity_type   ISE_EVENT_ENTITY_TYPE    DEFAULT NULL,
    executor      VARCHAR(45)     NOT NULL,
    target_entity VARCHAR(45)              DEFAULT NULL,
    description   TEXT,
    creation_date TIMESTAMP       NOT NULL DEFAULT now(),
    type          ISE_EVENT_TYPE           DEFAULT NULL,
    CONSTRAINT events_pkey PRIMARY KEY (id)
);


CREATE TABLE endpoint_groups
(
    pkid           UUID        NOT NULL UNIQUE DEFAULT uuid_generate_v1mc(),
    id             VARCHAR(50) NOT NULL,
    name           VARCHAR(45) NOT NULL,
    description    VARCHAR,
    version_number INTEGER     NOT NULL        DEFAULT 0,
    grace_period   INTEGER                     DEFAULT 700000,
    CONSTRAINT endpoint_groups_pkey PRIMARY KEY (id),
    CONSTRAINT name_UNIQUE UNIQUE (name)
);


CREATE TABLE endpoints
(
    id                      VARCHAR(45) NOT NULL,
    mac_address             VARCHAR(45) NOT NULL UNIQUE,
    group_id                VARCHAR(50) NOT NULL,
    description             VARCHAR(1000),
    creation_date           TIMESTAMP   NOT NULL DEFAULT now(),
    latest_modified_date    TIMESTAMP,
    portal_user             VARCHAR(45)          DEFAULT NULL,
    latest_modified_by      VARCHAR(45),
    static_group_assignment BOOLEAN     NOT NULL DEFAULT FALSE,
    permanent               BOOLEAN     NOT NULL DEFAULT FALSE,
    days_to_expiration      INTEGER              DEFAULT 700000,
    deletion_date           TIMESTAMP,
    grace_registered        BOOLEAN     NOT NULL DEFAULT FALSE,
    version_number          INTEGER     NOT NULL DEFAULT 0,
    created_by              VARCHAR(45),
    pkid                    UUID        NOT NULL DEFAULT uuid_generate_v1(),
    CONSTRAINT endpoints_pkey PRIMARY KEY (pkid),
    CONSTRAINT fk_endpoints_1 FOREIGN KEY (group_id) REFERENCES endpoint_groups (id) ON DELETE NO ACTION ON UPDATE NO ACTION
);


-- user_permissions (endpoint groups permitted to see and change endpoints within)
CREATE TABLE user_permissions
(
    username          VARCHAR(45) NOT NULL,
    endpoint_group_id VARCHAR(50) NOT NULL,
    version_number    INTEGER     NOT NULL DEFAULT 0,
    users_pkid        UUID,
    CONSTRAINT user_permissions_pkey PRIMARY KEY (username, endpoint_group_id),
    CONSTRAINT fk_user_permissions_endpoint_group_id FOREIGN KEY (endpoint_group_id)
        REFERENCES endpoint_groups (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT user_permissions_users_pkid_fkey FOREIGN KEY (users_pkid)
        REFERENCES users (pkid) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);


CREATE TABLE endpoint_group_versions
(
    version_id     SERIAL,
    id             VARCHAR(50)  NOT NULL,
    name           VARCHAR(100) NOT NULL,
    description    VARCHAR(1000),
    grace_period   INTEGER               DEFAULT 700000,
    version_number INTEGER      NOT NULL,
    event_id       VARCHAR(50),
    timestamp      TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT endpoint_group_versions_pkey PRIMARY KEY (version_id)
);


CREATE TABLE endpoint_versions
(
    version_id              SERIAL,
    id                      VARCHAR(45) NOT NULL,
    mac_address             VARCHAR(45) NOT NULL,
    group_id                VARCHAR(50) NOT NULL,
    description             VARCHAR(1000),
    creation_date           TIMESTAMP   NOT NULL DEFAULT now(),
    latest_modified_date    TIMESTAMP,
    portal_user             VARCHAR(45)          DEFAULT NULL,
    latest_modified_by      VARCHAR(45),
    static_group_assignment BOOLEAN     NOT NULL DEFAULT FALSE,
    permanent               BOOLEAN     NOT NULL DEFAULT FALSE,
    group_name              VARCHAR(100),
    days_to_expiration      INTEGER              DEFAULT 700000,
    deletion_date           TIMESTAMP,
    grace_registered        BOOLEAN     NOT NULL DEFAULT FALSE,
    version_number          INTEGER     NOT NULL,
    event_id                VARCHAR(50),
    timestamp               TIMESTAMP   NOT NULL DEFAULT now(),
    created_by              VARCHAR(45),
    fk_endpoints            UUID,
    CONSTRAINT endpoint_versions_pkey PRIMARY KEY (version_id)
);


CREATE TABLE user_permission_versions
(
    version_id          SERIAL,
    event_id            VARCHAR(50),
    version_number      INTEGER      NOT NULL DEFAULT 0,
    username            VARCHAR(45)  NOT NULL,
    endpoint_group_id   VARCHAR(50)  NOT NULL,
    endpoint_group_name VARCHAR(100) NOT NULL,
    timestamp           TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT user_permission_versions_pkey PRIMARY KEY (version_id)
);


CREATE TABLE user_role_versions
(
    version_id     SERIAL,
    version_number INTEGER     NOT NULL DEFAULT 0,
    event_id       VARCHAR(50),
    role           VARCHAR(45) NOT NULL,
    grace_period   INTEGER              DEFAULT 700000,
    description    VARCHAR(250),
    is_gracer      BOOLEAN              DEFAULT FALSE,
    rank           INTEGER     NOT NULL DEFAULT 0,
    timestamp      TIMESTAMP   NOT NULL DEFAULT now(),
    CONSTRAINT user_role_versions_pkey PRIMARY KEY (version_id)
);


CREATE TABLE user_versions
(
    version_id      SERIAL,
    version_number  INTEGER     NOT NULL DEFAULT 0,
    event_id        VARCHAR(50),
    username        VARCHAR(45) NOT NULL,
    email           VARCHAR     NOT NULL,
    password        VARCHAR     NOT NULL,
    role            VARCHAR(45) NOT NULL,
    role_version_id INTEGER     NOT NULL DEFAULT 0,
    enabled         BOOLEAN     NOT NULL,
    timestamp       TIMESTAMP   NOT NULL DEFAULT now(),
    CONSTRAINT fk_user_versions_user_role_versions FOREIGN KEY (role_version_id) REFERENCES user_role_versions (version_id),
    CONSTRAINT user_versions_pkey PRIMARY KEY (version_id)
);


CREATE TABLE password_reset_tokens
(
    id              SERIAL PRIMARY KEY,
    user_email      VARCHAR   NOT NULL,
    expiration_date TIMESTAMP NOT NULL,
    used            BOOLEAN DEFAULT FALSE,
    token           VARCHAR   NOT NULL
);


CREATE TABLE user_activedirectory_map
(
    pkid           uuid NOT NULL DEFAULT uuid_generate_v1mc(),
    xk_objectguid  uuid NOT NULL,
    samaccountname VARCHAR(256),
    fk_users       uuid NOT NULL,
    CONSTRAINT user_activedirectory_map_pkey PRIMARY KEY (pkid),
    CONSTRAINT user_activedirectory_map_fk_users_fkey FOREIGN KEY (fk_users)
        REFERENCES users (pkid) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);


CREATE TABLE endpoint_ise_map
(
    fk_endpoints uuid NOT NULL,
    ise_id uuid NOT NULL,
    pkid uuid NOT NULL DEFAULT uuid_generate_v1(),
    CONSTRAINT endpoint_ise_map_pkey PRIMARY KEY (pkid),
    CONSTRAINT endpoint_ise_map_fk_endpoints_key UNIQUE (fk_endpoints)
    ,
    CONSTRAINT endpoint_ise_map_ise_id_key UNIQUE (ise_id)
    ,
    CONSTRAINT endpoint_ise_map_pkid_key UNIQUE (pkid)
    ,
    CONSTRAINT endpoint_ise_map_endpoints_pkid_fk FOREIGN KEY (fk_endpoints)
        REFERENCES public.endpoints (pkid) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);

COMMENT ON TABLE public.endpoint_ise_map
    IS 'Maps ISE endpoint id:s to local endpoint pkid';


-- INITIAL USER ROLES
INSERT INTO user_roles (role, grace_period, description, is_gracer, rank)
VALUES ('SD_USER', 7, 'Service Desk User', TRUE, 10);

INSERT INTO user_roles (role, description, rank)
VALUES ('USER', 'User', 25);
INSERT INTO user_roles (role, description, rank)
VALUES ('ADMIN', 'Administrator', 50);
INSERT INTO user_roles (role, description, rank)
VALUES ('SUPERADMIN', 'Super Administrator', 100);


-- INITIAL EVENTS FOR INSERTION OF USER ROLE VERSIONS
INSERT INTO events (id, level, entity_type, executor, target_entity, description, creation_date, type)
VALUES ('c6c490ea-f81e-44d6-a55e-1b4a3e45212b', 'INFO', 'USER_ROLE', 'CAX', 'SUPERADMIN', 'User role created', now(),
        'USER_ROLE_ADD');
INSERT INTO events (id, level, entity_type, executor, target_entity, description, creation_date, type)
VALUES ('510f798d-2648-4007-a93a-e2fdfb8c5452', 'INFO', 'USER_ROLE', 'CAX', 'SD_USER', 'User role created', now(),
        'USER_ROLE_ADD');
INSERT INTO events (id, level, entity_type, executor, target_entity, description, creation_date, type)
VALUES ('7492c023-8de3-443b-b0c2-acc4d3651eb5', 'INFO', 'USER_ROLE', 'CAX', 'USER', 'User role created', now(),
        'USER_ROLE_ADD');
INSERT INTO events (id, level, entity_type, executor, target_entity, description, creation_date, type)
VALUES ('acc8f1c5-b875-4b79-8a5a-40bc845b3b5a', 'INFO', 'USER_ROLE', 'CAX', 'ADMIN', 'User role created', now(),
        'USER_ROLE_ADD');
-- INSERT INITIAL USER ROLE VERSIONS WITH EVENTS IDS
INSERT INTO user_role_versions (version_id, event_id, role, description, rank)
VALUES (1, 'c6c490ea-f81e-44d6-a55e-1b4a3e45212b', 'USER', 'User', 25);
INSERT INTO user_role_versions (version_id, event_id, role, description, rank)
VALUES (2, '510f798d-2648-4007-a93a-e2fdfb8c5452', 'ADMIN', 'Administrator', 50);
INSERT INTO user_role_versions (version_id, event_id, role, description, rank)
VALUES (3, '00a8c75b-6522-4c14-aea7-f1f8990fedba', 'SUPERADMIN', 'Super Administrator', 100);
INSERT INTO user_role_versions (version_id, event_id, role, grace_period, description, is_gracer, rank)
VALUES (4, '7492c023-8de3-443b-b0c2-acc4d3651eb5', 'SD_USER', 7, 'Service Desk User', TRUE, 10);

-- RESET TO VALUE AFTER
SELECT setval('user_role_versions_version_id_seq', (SELECT MAX(version_id) FROM user_role_versions));


-- REPLACE <username> AND <user@email.com> WITH REAL VALUES. THIS WILL BE THE FIRST USER THAT CAN LOGIN, SETUP THE APPLICATION AND ADD NEW USERS
INSERT INTO users (username, role, email, password, enabled)
VALUES ('superadmin1', 'SUPERADMIN', 'superadmin1@email.com',
        '$2a$10$I.6OaBcnRfIRm470uUFO4eKR3xsW/.cjHQ6rYfsusIW2svp1vz.1q', TRUE);

-- ADD INITIAL USERS EVENTS
INSERT INTO events (id, level, entity_type, executor, target_entity, description, creation_date, type)
VALUES ('f647c516-beb0-47e8-bb89-1208fce40e22', 'INFO', 'USER', 'CAX', '<username>', 'User created', now(), 'USER_ADD');
--  INSERT USER VERSIONS WITH EVENT IDS
INSERT INTO user_versions (event_id, username, role, email, password, role_version_id, enabled)
VALUES ('f647c516-beb0-47e8-bb89-1208fce40e22', '<username>', 'SUPERADMIN', '<user@email.com>',
        '$2a$10$I.6OaBcnRfIRm470uUFO4eKR3xsW/.cjHQ6rYfsusIW2svp1vz.1q', 3, TRUE);


-- Application user (CAX itself)
INSERT INTO application_user_roles (role, description, rank)
VALUES ('APPLICATION_ADMIN', 'Application administrator. Highest possible role assigned to the application itself',
        999999);
INSERT INTO application_users (username, role, password, enabled)
VALUES ('CAX', 'APPLICATION_ADMIN', '$2a$10$I.6OaBcnRfIRm470uUFO4eKR3xsW/.cjHQ6rYfsusIW2svp1vz.1q', TRUE);
