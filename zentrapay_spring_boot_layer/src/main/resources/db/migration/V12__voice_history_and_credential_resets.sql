-- V12: richer voice history, and the one-time codes behind "forgot password / forgot PIN".

-- ZVoice: every spoken or typed instruction is stored with what the app understood from it
ALTER TABLE voice_commands
    ADD COLUMN intent character varying(40),
    ADD COLUMN duration_ms integer,
    ADD COLUMN confidence numeric(4,3);

CREATE INDEX idx_voice_commands_user_type ON voice_commands USING btree (user_id, command_type, created_at DESC);

-- Forgot password / forgot PIN. A request is created when the user asks for a reset; the emailed
-- code (only its hash is stored) is exchanged for a short-lived reset token (again only the hash),
-- and the token is exchanged for the new password / PIN. Each step can be used once.
CREATE TABLE credential_reset_requests (
    request_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    purpose character varying(10) NOT NULL,
    code_hash character varying(128) NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    reset_token_hash character varying(128),
    reset_token_expires_at timestamp with time zone,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT credential_reset_requests_pkey PRIMARY KEY (request_id),
    CONSTRAINT credential_reset_requests_purpose_check CHECK (((purpose)::text = ANY ((ARRAY['PASSWORD'::character varying, 'PIN'::character varying])::text[]))),
    CONSTRAINT credential_reset_requests_user_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_credential_reset_user ON credential_reset_requests USING btree (user_id, purpose, created_at DESC);
