

CREATE TYPE private.wf_request_type AS ENUM (
    'NONE',
    'SUPPORT',
    'ACTION'
);
COMMENT ON TYPE private.wf_request_type IS 'Enum used in code to automate and validate wf_request types.';

INSERT INTO private.enum_comment (enum_type, enum_value, comment) VALUES 
('wf_request_type', 'NONE', 'General purpose with no automation or validation'),
('wf_request_type', 'SUPPORT', 'Support purpose with limited automation or validation'),
('wf_request_type', 'ACTION', 'Action purpose with no automation or validation')
;

CREATE TABLE private.stk_wf_request_type (
  stk_wf_request_type_uu UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_default BOOLEAN NOT NULL DEFAULT false,
  wf_request_type private.wf_request_type NOT NULL,
  search_key TEXT NOT NULL DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT
);
COMMENT ON TABLE private.stk_wf_request_type IS 'Holds the types of stk_wf_request records. To see a list of all wf_request_type enums and their comments, select from api.enum_value where enum_name is wf_request_type.';

CREATE VIEW api.stk_wf_request_type AS SELECT * FROM private.stk_wf_request_type;
COMMENT ON VIEW api.stk_wf_request_type IS 'Holds the types of stk_wf_request records.';

CREATE TABLE private.stk_wf_request (
  stk_wf_request_uu UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_template BOOLEAN NOT NULL DEFAULT false,
  is_valid BOOLEAN NOT NULL DEFAULT true,
  stk_wf_request_type_uu UUID NOT NULL,
  CONSTRAINT fk_stk_wf_request_type FOREIGN KEY (stk_wf_request_type_uu) REFERENCES private.stk_wf_request_type(stk_wf_request_type_uu),
  stk_wf_request_parent_uu UUID,
  CONSTRAINT fk_stk_wf_request_parent FOREIGN KEY (stk_wf_request_parent_uu) REFERENCES private.stk_wf_request(stk_wf_request_uu),
  date_started TIMESTAMPTZ,
  date_completed TIMESTAMPTZ,
  date_due TIMESTAMPTZ,
  name TEXT NOT NULL,
  description TEXT
);
COMMENT ON TABLE private.stk_wf_request IS 'Holds wf_request records';

CREATE VIEW api.stk_wf_request AS SELECT * FROM private.stk_wf_request;
COMMENT ON VIEW api.stk_wf_request IS 'Holds wf_request records';

--INSERT INTO api.stk_wf_request_type (wf_request_type, name, description)
--VALUES 
--('NONE', 'None', 'General purpose with no automation or validation'),
--('SUPPORT', 'Support', 'Support purpose with limited automation or validation'),
--('ACTION', 'Action', 'Action purpose with no automation or validation')
--;