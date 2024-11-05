

CREATE TYPE private.system_config_type AS ENUM (
    'SYSTEM',
    'TENANT',
    'ENTITY',
    'ROLE',
    'USER'
);
COMMENT ON TYPE private.system_config_type IS 'used in code to drive system configuration visibility and functionality';

CREATE TABLE private.stk_system_config_type (
  stk_system_config_type_uu UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true,
  system_config_type private.system_config_type NOT NULL,
  search_key TEXT NOT NULL DEFAULT gen_random_uuid(),
  description TEXT,
  configuration JSONB NOT NULL -- used to hold a template json object. Used as the source when creating a new stk_system_config record.
);
COMMENT ON TABLE private.stk_system_config_type IS 'Holds the types of stk_system_config records. Configuration column holds a json template to be used when creating a new stk_system_config record.';

CREATE TABLE private.stk_system_config (
  stk_system_config_uu UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true,
  stk_system_config_type_uu UUID DEFAULT gen_random_uuid(),
  CONSTRAINT fk_stk_system_config_sysconfigtype FOREIGN KEY (stk_system_config_type_uu) REFERENCES private.stk_system_config_type(stk_system_config_type_uu),
  search_key TEXT NOT NULL DEFAULT gen_random_uuid(),
  description TEXT,
  configuration JSONB NOT NULL -- settings and configuration
);
COMMENT ON TABLE private.stk_system_config IS 'Holds the system configuration records that dictates how the system behaves. Configuration column holds the actual json configuration values used to describe the system configuration.';

--sample data for stk_system_config_type
INSERT INTO private.stk_system_config_type (system_config_type, search_key, description, configuration) VALUES
('SYSTEM', 'SYSTEM_CONFIG', 'System-wide configuration', '{"theme": "default", "language": "en", "timezone": "UTC"}'),
('TENANT', 'TENANT_CONFIG', 'Tenant-specific configuration', '{"name": "", "domain": "", "max_users": 100}'),
('ENTITY', 'ENTITY_CONFIG', 'Entity-level configuration', '{"entity_type": "", "custom_fields": {}}'),
('ROLE', 'ROLE_CONFIG', 'Role-based configuration', '{"permissions": [], "access_level": "standard"}'),
('USER', 'USER_CONFIG', 'User-specific configuration', '{"theme_preference": "default", "notification_settings": {}}');

--sample data for stk_system_config
-- System configuration
INSERT INTO private.stk_system_config (
    stk_system_config_type_uu,
    search_key,
    description,
    configuration
) VALUES (
    (SELECT stk_system_config_type_uu FROM private.stk_system_config_type WHERE system_config_type = 'SYSTEM'),
    'GLOBAL_SYSTEM_CONFIG',
    'Global system-wide configuration',
    '{
        "theme": "dark",
        "language": "en",
        "timezone": "UTC",
        "max_file_upload_size": 10,
        "session_timeout": 30
    }'
);

-- Tenant configuration 1
INSERT INTO private.stk_system_config (
    stk_system_config_type_uu,
    search_key,
    description,
    configuration
) VALUES (
    (SELECT stk_system_config_type_uu FROM private.stk_system_config_type WHERE system_config_type = 'TENANT'),
    'TENANT_CONFIG_ACME',
    'Configuration for Acme Corporation',
    '{
        "name": "Acme Corporation",
        "domain": "acme.com",
        "max_users": 500,
        "storage_limit": 1000,
        "features_enabled": ["analytics", "integrations"]
    }'
);

-- Tenant configuration 2
INSERT INTO private.stk_system_config (
    stk_system_config_type_uu,
    search_key,
    description,
    configuration
) VALUES (
    (SELECT stk_system_config_type_uu FROM private.stk_system_config_type WHERE system_config_type = 'TENANT'),
    'TENANT_CONFIG_GLOBEX',
    'Configuration for Globex Corporation',
    '{
        "name": "Globex Corporation",
        "domain": "globex.com",
        "max_users": 250,
        "storage_limit": 500,
        "features_enabled": ["reporting", "custom_branding"]
    }'
);
