-- V5: Security settings, fraud alerts, voice commands, notifications and the double-entry ledger.

-- security_settings
CREATE TABLE security_settings (
    settings_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    biometric_enabled boolean DEFAULT false NOT NULL,
    biometric_type character varying(20),
    two_factor_enabled boolean DEFAULT false NOT NULL,
    two_factor_method character varying(20),
    fraud_protection_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY security_settings
    ADD CONSTRAINT security_settings_pkey PRIMARY KEY (settings_id);

ALTER TABLE ONLY security_settings
    ADD CONSTRAINT security_settings_user_id_key UNIQUE (user_id);

-- fraud_alerts
CREATE TABLE fraud_alerts (
    alert_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    alert_type character varying(40) NOT NULL,
    message text NOT NULL,
    severity character varying(20) DEFAULT 'LOW'::character varying NOT NULL,
    is_resolved boolean DEFAULT false NOT NULL,
    related_transaction_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT fraud_alerts_severity_check CHECK (((severity)::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'CRITICAL'::character varying])::text[])))
);

ALTER TABLE ONLY fraud_alerts
    ADD CONSTRAINT fraud_alerts_pkey PRIMARY KEY (alert_id);

CREATE INDEX idx_fraud_alerts_user ON fraud_alerts USING btree (user_id, created_at DESC);

-- voice_commands
CREATE TABLE voice_commands (
    command_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    command_type character varying(20) NOT NULL,
    language character varying(10) DEFAULT 'en'::character varying NOT NULL,
    transcript text NOT NULL,
    response_text text,
    status character varying(20) DEFAULT 'PROCESSED'::character varying NOT NULL,
    fraud_alert boolean DEFAULT false NOT NULL,
    fraud_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT voice_commands_command_type_check CHECK (((command_type)::text = ANY ((ARRAY['VOICE'::character varying, 'CHAT'::character varying])::text[])))
);

ALTER TABLE ONLY voice_commands
    ADD CONSTRAINT voice_commands_pkey PRIMARY KEY (command_id);

CREATE INDEX idx_voice_commands_user ON voice_commands USING btree (user_id, created_at DESC);

-- notifications
CREATE TABLE notifications (
    notification_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    title character varying(120) NOT NULL,
    message character varying(500) NOT NULL,
    type character varying(30) NOT NULL,
    reference_id character varying(100),
    is_read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);

CREATE INDEX idx_notifications_user_created ON notifications USING btree (user_id, created_at DESC);

-- ledger_entries
CREATE TABLE ledger_entries (
    ledger_id uuid DEFAULT gen_random_uuid() NOT NULL,
    transaction_id uuid NOT NULL,
    entry_id character varying(64) NOT NULL,
    account_id uuid NOT NULL,
    type character varying(10) NOT NULL,
    amount numeric(19,4) NOT NULL,
    running_balance numeric(19,4) NOT NULL,
    currency_code character varying(3) DEFAULT 'GHS'::character varying NOT NULL,
    narration character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE ONLY ledger_entries
    ADD CONSTRAINT ledger_entries_entry_id_key UNIQUE (entry_id);

ALTER TABLE ONLY ledger_entries
    ADD CONSTRAINT ledger_entries_pkey PRIMARY KEY (ledger_id);

CREATE INDEX idx_ledger_account_created ON ledger_entries USING btree (account_id, created_at DESC);

CREATE INDEX idx_ledger_entry_id_prefix ON ledger_entries USING btree (entry_id varchar_pattern_ops);

CREATE INDEX idx_ledger_transaction ON ledger_entries USING btree (transaction_id);

-- foreign keys (after all tables of this file exist)
ALTER TABLE ONLY security_settings
    ADD CONSTRAINT security_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY fraud_alerts
    ADD CONSTRAINT fraud_alerts_related_transaction_id_fkey FOREIGN KEY (related_transaction_id) REFERENCES transactions(transaction_id);
ALTER TABLE ONLY fraud_alerts
    ADD CONSTRAINT fraud_alerts_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY voice_commands
    ADD CONSTRAINT voice_commands_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY notifications
    ADD CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE ONLY ledger_entries
    ADD CONSTRAINT ledger_entries_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE RESTRICT;
