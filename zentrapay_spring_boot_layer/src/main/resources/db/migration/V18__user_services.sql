-- V18: user_services - the services a user has added to their Home screen with the "New" button.
--
-- Home only shows these (not the whole provider directory). A row links a user to ONE provider of either
-- directory: service_kind BILL -> bill_providers, SERVICE -> service_providers. provider_id points at two
-- different tables, so it carries no foreign key; the service checks that the provider exists and is active
-- before a row is added. A provider can be added once per user.
CREATE TABLE IF NOT EXISTS user_services (
    user_service_id uuid NOT NULL,
    user_id         uuid NOT NULL,
    service_kind    character varying(10) NOT NULL,
    provider_id     uuid NOT NULL,
    created_at      timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT user_services_pkey PRIMARY KEY (user_service_id),
    CONSTRAINT user_services_kind_check CHECK (service_kind IN ('BILL', 'SERVICE')),
    CONSTRAINT uq_user_services UNIQUE (user_id, service_kind, provider_id),
    CONSTRAINT fk_user_services_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_services_user ON user_services (user_id, created_at);
