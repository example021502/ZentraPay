-- V2: Wallets and accounts, cards, the transactions table, bill and service providers, bill payments.

-- wallets
CREATE TABLE wallets (
    wallet_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    wallet_name character varying(60) NOT NULL,
    country_code character varying(3),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (wallet_id);

ALTER TABLE ONLY wallets
    ADD CONSTRAINT wallets_user_id_wallet_name_key UNIQUE (user_id, wallet_name);

CREATE INDEX idx_wallets_user ON wallets USING btree (user_id);

-- accounts
CREATE TABLE accounts (
    account_id uuid DEFAULT gen_random_uuid() NOT NULL,
    wallet_id uuid NOT NULL,
    account_name character varying(255) NOT NULL,
    currency_code character varying(3) NOT NULL,
    zentag character varying(64) NOT NULL,
    balance numeric(19,4) DEFAULT 0 NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    status character varying(50) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_accounts_balance_not_negative CHECK ((balance >= (0)::numeric))
);

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (account_id);

ALTER TABLE ONLY accounts
    ADD CONSTRAINT uq_accounts_wallet_currency UNIQUE (wallet_id, currency_code);

ALTER TABLE ONLY accounts
    ADD CONSTRAINT uq_accounts_zentag UNIQUE (zentag);

CREATE INDEX idx_accounts_wallet ON accounts USING btree (wallet_id);

-- crypto_wallets
CREATE TABLE crypto_wallets (
    wallet_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT crypto_wallets_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'FROZEN'::character varying, 'CLOSED'::character varying])::text[])))
);

ALTER TABLE ONLY crypto_wallets
    ADD CONSTRAINT crypto_wallets_pkey PRIMARY KEY (wallet_id);

CREATE INDEX idx_crypto_wallets_user ON crypto_wallets USING btree (user_id);

-- crypto_accounts
CREATE TABLE crypto_accounts (
    account_id uuid DEFAULT gen_random_uuid() NOT NULL,
    wallet_id uuid NOT NULL,
    currency_code character varying(20) NOT NULL,
    network character varying(30),
    wallet_address character varying(120) NOT NULL,
    balance numeric(28,10) DEFAULT 0 NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    status character varying(50) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY crypto_accounts
    ADD CONSTRAINT crypto_accounts_pkey PRIMARY KEY (account_id);

ALTER TABLE ONLY crypto_accounts
    ADD CONSTRAINT crypto_accounts_wallet_address_key UNIQUE (wallet_address);

CREATE INDEX idx_crypto_accounts_wallet ON crypto_accounts USING btree (wallet_id);

-- cards
CREATE TABLE cards (
    card_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    brand character varying(30) NOT NULL,
    card_type character varying(20) DEFAULT 'VIRTUAL'::character varying NOT NULL,
    description text,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT cards_card_type_check CHECK (((card_type)::text = ANY ((ARRAY['VIRTUAL'::character varying, 'PHYSICAL'::character varying])::text[])))
);

ALTER TABLE ONLY cards
    ADD CONSTRAINT cards_pkey PRIMARY KEY (card_id);

CREATE INDEX idx_cards_active ON cards USING btree (active);

-- user_cards
CREATE TABLE user_cards (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    card_id uuid NOT NULL,
    wallet_id uuid,
    last4 character varying(4) NOT NULL,
    balance numeric(19,4) DEFAULT 0.0000 NOT NULL,
    expiry_month integer NOT NULL,
    expiry_year integer NOT NULL,
    nfc_enabled boolean DEFAULT true NOT NULL,
    qr_enabled boolean DEFAULT true NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    currency_code character varying(3),
    provider_id uuid,
    CONSTRAINT user_cards_expiry_month_check CHECK (((expiry_month >= 1) AND (expiry_month <= 12))),
    CONSTRAINT user_cards_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'FROZEN'::character varying, 'CLOSED'::character varying])::text[])))
);

ALTER TABLE ONLY user_cards
    ADD CONSTRAINT user_cards_pkey PRIMARY KEY (id);

CREATE INDEX idx_user_cards_user ON user_cards USING btree (user_id);

-- transactions
CREATE TABLE transactions (
    transaction_id uuid DEFAULT gen_random_uuid() NOT NULL,
    amount numeric(19,4) NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    metadata jsonb,
    failure_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    entry_id character varying(255),
    transaction_type character varying(30),
    sender_id uuid,
    receiver_id uuid,
    sender_name character varying(180),
    receiver_name character varying(180),
    source_currency_code character varying(3),
    destination_currency_code character varying(3),
    destination_identifier character varying(180),
    purpose text,
    sender_email character varying(255),
    sender_phone_number character varying(30),
    receiver_email character varying(255),
    receiver_phone_number character varying(30),
    internal_reference_id character varying(100) NOT NULL,
    external_reference_id character varying(100),
    gateway_id uuid,
    destination_amount numeric(19,4),
    CONSTRAINT transactions_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT transactions_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SUCCESS'::character varying, 'FAILED'::character varying, 'REVERSED'::character varying, 'INITIATED'::character varying, 'STK_PUSH_TRIGGERED'::character varying, 'PENDING_USER_PIN'::character varying, 'EXPIRED'::character varying])::text[])))
);

ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);

CREATE INDEX idx_txn_external_ref ON transactions USING btree (external_reference_id);

CREATE UNIQUE INDEX idx_txn_internal_ref ON transactions USING btree (internal_reference_id);

CREATE INDEX idx_txn_open_status ON transactions USING btree (status, updated_at) WHERE ((status)::text = ANY ((ARRAY['INITIATED'::character varying, 'PENDING'::character varying])::text[]));

CREATE INDEX idx_txn_receiver_created ON transactions USING btree (receiver_id, created_at DESC);

CREATE INDEX idx_txn_sender_created ON transactions USING btree (sender_id, created_at DESC);

-- bill_providers
CREATE TABLE bill_providers (
    provider_id uuid DEFAULT gen_random_uuid() NOT NULL,
    biller_code character varying(40) NOT NULL,
    biller_name character varying(120) NOT NULL,
    category_code character varying(30) NOT NULL,
    country_code character varying(3) NOT NULL,
    logo_url text,
    customer_params_schema text,
    fetch_requirement jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    channel_code character varying(60),
    is_crossborder_allowed boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    gateway character varying(30) DEFAULT NULL::character varying
);

ALTER TABLE ONLY bill_providers
    ADD CONSTRAINT bill_providers_pkey PRIMARY KEY (provider_id);

CREATE INDEX idx_bill_providers_category ON bill_providers USING btree (category_code);

CREATE INDEX idx_bill_providers_country ON bill_providers USING btree (country_code);

-- service_providers
CREATE TABLE service_providers (
    provider_id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_code character varying(40) NOT NULL,
    provider_name character varying(120) NOT NULL,
    category_code character varying(30) NOT NULL,
    aggregator_gateway character varying(30),
    country_code character varying(3) NOT NULL,
    logo_url text,
    metadata jsonb,
    min_amount numeric(19,2),
    max_amount numeric(19,2),
    is_active boolean DEFAULT true NOT NULL,
    is_maintenance_mode boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY service_providers
    ADD CONSTRAINT service_providers_pkey PRIMARY KEY (provider_id);

ALTER TABLE ONLY service_providers
    ADD CONSTRAINT service_providers_provider_code_key UNIQUE (provider_code);

CREATE INDEX idx_service_providers_category ON service_providers USING btree (category_code);

CREATE INDEX idx_service_providers_country ON service_providers USING btree (country_code);

-- bill_payments
CREATE TABLE bill_payments (
    payment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    provider_id uuid NOT NULL,
    transaction_id uuid NOT NULL,
    customer_reference character varying(60) NOT NULL,
    amount numeric(19,4) NOT NULL,
    currency_code character varying(8) NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT bill_payments_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SUCCESS'::character varying, 'FAILED'::character varying])::text[])))
);

ALTER TABLE ONLY bill_payments
    ADD CONSTRAINT bill_payments_pkey PRIMARY KEY (payment_id);

ALTER TABLE ONLY bill_payments
    ADD CONSTRAINT bill_payments_transaction_id_key UNIQUE (transaction_id);

CREATE INDEX idx_bill_payments_user ON bill_payments USING btree (user_id);

-- user_bill_providers
CREATE TABLE user_bill_providers (
    user_bill_provider_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    provider_id uuid NOT NULL,
    account_reference character varying(128) NOT NULL,
    linked_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY user_bill_providers
    ADD CONSTRAINT uq_user_bill_provider UNIQUE (user_id, provider_id);

ALTER TABLE ONLY user_bill_providers
    ADD CONSTRAINT user_bill_providers_pkey PRIMARY KEY (user_bill_provider_id);

-- foreign keys (after all tables of this file exist)
ALTER TABLE ONLY wallets
    ADD CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY accounts
    ADD CONSTRAINT fk_accounts_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id);
ALTER TABLE ONLY crypto_wallets
    ADD CONSTRAINT crypto_wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY crypto_accounts
    ADD CONSTRAINT fk_crypto_accounts_wallet FOREIGN KEY (wallet_id) REFERENCES crypto_wallets(wallet_id);
ALTER TABLE ONLY user_cards
    ADD CONSTRAINT user_cards_card_id_fkey FOREIGN KEY (card_id) REFERENCES cards(card_id) ON DELETE RESTRICT;
ALTER TABLE ONLY user_cards
    ADD CONSTRAINT user_cards_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY user_cards
    ADD CONSTRAINT user_cards_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id) ON DELETE SET NULL;
ALTER TABLE ONLY transactions
    ADD CONSTRAINT fk_transactions_receiver FOREIGN KEY (receiver_id) REFERENCES users(user_id);
ALTER TABLE ONLY transactions
    ADD CONSTRAINT fk_transactions_sender FOREIGN KEY (sender_id) REFERENCES users(user_id);
ALTER TABLE ONLY transactions
    ADD CONSTRAINT transactions_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES gateway_providers(provider_id);
ALTER TABLE ONLY bill_providers
    ADD CONSTRAINT bill_providers_category_code_fkey FOREIGN KEY (category_code) REFERENCES provider_categories(category_code);
ALTER TABLE ONLY bill_providers
    ADD CONSTRAINT fk_bill_providers_category_code FOREIGN KEY (category_code) REFERENCES provider_categories(category_code);
ALTER TABLE ONLY service_providers
    ADD CONSTRAINT service_providers_category_code_fkey FOREIGN KEY (category_code) REFERENCES provider_categories(category_code);
ALTER TABLE ONLY bill_payments
    ADD CONSTRAINT bill_payments_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES bill_providers(provider_id);
ALTER TABLE ONLY bill_payments
    ADD CONSTRAINT bill_payments_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id);
ALTER TABLE ONLY bill_payments
    ADD CONSTRAINT bill_payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE ONLY user_bill_providers
    ADD CONSTRAINT fk_user_bill_providers_provider FOREIGN KEY (provider_id) REFERENCES bill_providers(provider_id);
ALTER TABLE ONLY user_bill_providers
    ADD CONSTRAINT fk_user_bill_providers_user FOREIGN KEY (user_id) REFERENCES users(user_id);
