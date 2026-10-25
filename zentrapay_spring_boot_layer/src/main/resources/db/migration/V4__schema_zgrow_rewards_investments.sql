-- V4: ZGrow challenges, rewards, tutorials and literacy content, savings ledger, investments.

-- rewards
CREATE TABLE rewards (
    reward_id integer NOT NULL,
    reward_type character varying(50) NOT NULL,
    title character varying(150) NOT NULL,
    description text NOT NULL,
    worth numeric(10,2) NOT NULL,
    currency_code character varying(3) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE rewards ALTER COLUMN reward_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME rewards_reward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE ONLY rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (reward_id);

-- challenges
CREATE TABLE challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying(150) NOT NULL,
    description text,
    category character varying(50) NOT NULL,
    challenge_type character varying(50) NOT NULL,
    duration_days integer NOT NULL,
    is_active boolean DEFAULT true CONSTRAINT challenges_active_not_null NOT NULL,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    reward_id integer
);

ALTER TABLE ONLY challenges
    ADD CONSTRAINT challenges_pkey PRIMARY KEY (id);

-- challenges_targets
CREATE TABLE challenges_targets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    challenge_id uuid NOT NULL,
    target_amount numeric(19,4) NOT NULL,
    reward_type character varying(50) NOT NULL,
    reward_value character varying(100) NOT NULL,
    tier_level integer DEFAULT 1 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY challenges_targets
    ADD CONSTRAINT challenges_targets_pkey PRIMARY KEY (id);

CREATE INDEX idx_challenge_targets_challenge ON challenges_targets USING btree (challenge_id);

-- user_challenges
CREATE TABLE user_challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    challenge_id uuid NOT NULL,
    status character varying(30) DEFAULT 'IN_PROGRESS'::character varying NOT NULL,
    current_amount numeric(19,4) DEFAULT 0.0000 NOT NULL,
    target_amount numeric(19,4) NOT NULL,
    started_at timestamp without time zone DEFAULT now() NOT NULL,
    ends_at timestamp without time zone NOT NULL,
    completed_at timestamp without time zone
);

ALTER TABLE ONLY user_challenges
    ADD CONSTRAINT unique_user_active_challenge UNIQUE (user_id, challenge_id);

ALTER TABLE ONLY user_challenges
    ADD CONSTRAINT user_challenges_pkey PRIMARY KEY (id);

CREATE INDEX idx_user_challenges_user_status ON user_challenges USING btree (user_id, status);

-- challenges_progress
CREATE TABLE challenges_progress (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_challenge_id uuid NOT NULL,
    amount_contributed numeric(19,4) NOT NULL,
    new_total_amount numeric(19,4) NOT NULL,
    transaction_reference uuid,
    notes character varying(255),
    created_at timestamp without time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY challenges_progress
    ADD CONSTRAINT challenges_progress_pkey PRIMARY KEY (id);

-- declined_challenges
CREATE TABLE declined_challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    challenge_id uuid NOT NULL,
    declined_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY declined_challenges
    ADD CONSTRAINT declined_challenges_pkey PRIMARY KEY (id);

ALTER TABLE ONLY declined_challenges
    ADD CONSTRAINT declined_challenges_user_id_challenge_id_key UNIQUE (user_id, challenge_id);

CREATE INDEX idx_declined_challenges_user ON declined_challenges USING btree (user_id);

-- user_gamification_settings
CREATE TABLE user_gamification_settings (
    user_id uuid NOT NULL,
    challenges_enabled boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE user_gamification_settings IS 'Per-user gamification preferences (challenges_enabled).';

COMMENT ON COLUMN user_gamification_settings.challenges_enabled IS 'When FALSE the ZGrow challenges section stays collapsed and never tracks.';

ALTER TABLE ONLY user_gamification_settings
    ADD CONSTRAINT pk_user_gamification_settings PRIMARY KEY (user_id);

-- user_savings
CREATE TABLE user_savings (
    saving_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    currency_code character varying(3) NOT NULL,
    amount numeric(19,4) NOT NULL,
    source character varying(30) NOT NULL,
    reference_id uuid,
    note character varying(255),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_user_savings_source CHECK (((source)::text = ANY ((ARRAY['MILESTONE'::character varying, 'CHALLENGE'::character varying, 'MANUAL'::character varying, 'DEPOSIT'::character varying])::text[]))),
    CONSTRAINT user_savings_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT user_savings_source_check CHECK (((source)::text = ANY ((ARRAY['MILESTONE'::character varying, 'CHALLENGE'::character varying, 'MANUAL'::character varying, 'DEPOSIT'::character varying])::text[])))
);

COMMENT ON TABLE user_savings IS 'Per-user savings ledger — source of truth for the "Overall Savings" hero total.';

COMMENT ON COLUMN user_savings.source IS 'Where the saved money came from (challenge progress, manual top-up, milestone, deposit).';

ALTER TABLE ONLY user_savings
    ADD CONSTRAINT pk_user_savings PRIMARY KEY (saving_id);

CREATE INDEX idx_user_savings_user_created ON user_savings USING btree (user_id, created_at DESC);

CREATE INDEX idx_user_savings_user_currency ON user_savings USING btree (user_id, currency_code);

-- tutorials
CREATE TABLE tutorials (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    type character varying(50) NOT NULL,
    description text NOT NULL,
    video_url character varying(500) NOT NULL,
    thumbnail_url character varying(500) NOT NULL,
    duration_seconds integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE tutorials IS 'Learn & Earn catalog behind GET /api/zgrow/tutorials (created in V26 because no earlier migration ever defined it).';

ALTER TABLE ONLY tutorials
    ADD CONSTRAINT pk_tutorials PRIMARY KEY (id);

CREATE INDEX idx_tutorials_active ON tutorials USING btree (is_active);

CREATE INDEX idx_tutorials_type ON tutorials USING btree (type);

-- financial_literacy_content
CREATE TABLE financial_literacy_content (
    content_id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying(150) NOT NULL,
    category character varying(40),
    content_url text,
    duration_minutes integer,
    points_reward integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY financial_literacy_content
    ADD CONSTRAINT financial_literacy_content_pkey PRIMARY KEY (content_id);

-- content_completions
CREATE TABLE content_completions (
    completion_id uuid DEFAULT gen_random_uuid() NOT NULL,
    content_id uuid NOT NULL,
    user_id uuid NOT NULL,
    completed_at timestamp with time zone DEFAULT now() NOT NULL,
    points_earned integer DEFAULT 0 NOT NULL
);

ALTER TABLE ONLY content_completions
    ADD CONSTRAINT content_completions_content_id_user_id_key UNIQUE (content_id, user_id);

ALTER TABLE ONLY content_completions
    ADD CONSTRAINT content_completions_pkey PRIMARY KEY (completion_id);

CREATE INDEX idx_content_completions_user ON content_completions USING btree (user_id);

-- points_ledger
CREATE TABLE points_ledger (
    ledger_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    points integer NOT NULL,
    reason character varying(60) NOT NULL,
    reference_type character varying(30),
    reference_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY points_ledger
    ADD CONSTRAINT points_ledger_pkey PRIMARY KEY (ledger_id);

CREATE INDEX idx_points_ledger_user ON points_ledger USING btree (user_id, created_at DESC);

-- investments
CREATE TABLE investments (
    investment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    name character varying(120) NOT NULL,
    investment_type character varying(20) NOT NULL,
    symbol character varying(20),
    quantity numeric(19,4) NOT NULL,
    buy_price numeric(19,4) NOT NULL,
    currency_code character varying(8) NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT investments_investment_type_check CHECK (((investment_type)::text = ANY ((ARRAY['STOCK'::character varying, 'ETF'::character varying, 'COMMODITY'::character varying, 'CRYPTO'::character varying, 'OTHER'::character varying])::text[]))),
    CONSTRAINT investments_quantity_check CHECK ((quantity > (0)::numeric)),
    CONSTRAINT investments_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'CLOSED'::character varying])::text[])))
);

ALTER TABLE ONLY investments
    ADD CONSTRAINT investments_pkey PRIMARY KEY (investment_id);

CREATE INDEX idx_investments_user ON investments USING btree (user_id);

-- investment_price_snapshots
CREATE TABLE investment_price_snapshots (
    snapshot_id uuid DEFAULT gen_random_uuid() NOT NULL,
    investment_id uuid NOT NULL,
    price numeric(19,4) NOT NULL,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY investment_price_snapshots
    ADD CONSTRAINT investment_price_snapshots_pkey PRIMARY KEY (snapshot_id);

CREATE INDEX idx_price_snapshots_investment ON investment_price_snapshots USING btree (investment_id, recorded_at DESC);

-- foreign keys (after all tables of this file exist)
ALTER TABLE ONLY challenges
    ADD CONSTRAINT rewards_ids_fkey FOREIGN KEY (reward_id) REFERENCES rewards(reward_id) ON DELETE SET NULL;
ALTER TABLE ONLY challenges_targets
    ADD CONSTRAINT challenges_targets_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE;
ALTER TABLE ONLY user_challenges
    ADD CONSTRAINT user_challenges_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE;
ALTER TABLE ONLY challenges_progress
    ADD CONSTRAINT challenges_progress_user_challenge_id_fkey FOREIGN KEY (user_challenge_id) REFERENCES user_challenges(id) ON DELETE CASCADE;
ALTER TABLE ONLY declined_challenges
    ADD CONSTRAINT declined_challenges_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY user_gamification_settings
    ADD CONSTRAINT fk_ugs_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY content_completions
    ADD CONSTRAINT content_completions_content_id_fkey FOREIGN KEY (content_id) REFERENCES financial_literacy_content(content_id) ON DELETE CASCADE;
ALTER TABLE ONLY content_completions
    ADD CONSTRAINT content_completions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY points_ledger
    ADD CONSTRAINT points_ledger_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY investments
    ADD CONSTRAINT investments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY investment_price_snapshots
    ADD CONSTRAINT investment_price_snapshots_investment_id_fkey FOREIGN KEY (investment_id) REFERENCES investments(investment_id) ON DELETE CASCADE;
