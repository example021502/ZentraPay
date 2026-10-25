-- V3: Remittances, conversions, bank catalogue and linked banks, payment channels, mobile money, gateway customers and recipients, loans, savings, budgets.

-- remittances
CREATE TABLE remittances (
    remittance_id uuid DEFAULT gen_random_uuid() NOT NULL,
    sender_id uuid NOT NULL,
    receiver_id uuid,
    transaction_id uuid NOT NULL,
    amount numeric(19,4) NOT NULL,
    source_currency_code character varying(8) NOT NULL,
    destination_currency_code character varying(8) NOT NULL,
    exchange_rate numeric(24,10) NOT NULL,
    fee numeric(19,4) DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    channel character varying(30) NOT NULL,
    recipient_name character varying(120) NOT NULL,
    recipient_phone_number character varying(20),
    recipient_country_code character varying(2) NOT NULL,
    reference character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT remittances_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SUCCESS'::character varying, 'FAILED'::character varying, 'REVERSED'::character varying])::text[])))
);

ALTER TABLE ONLY remittances
    ADD CONSTRAINT remittances_pkey PRIMARY KEY (remittance_id);

ALTER TABLE ONLY remittances
    ADD CONSTRAINT remittances_reference_key UNIQUE (reference);

ALTER TABLE ONLY remittances
    ADD CONSTRAINT remittances_transaction_id_key UNIQUE (transaction_id);

CREATE INDEX idx_remittances_sender ON remittances USING btree (sender_id, created_at DESC);

-- conversions
CREATE TABLE conversions (
    conversion_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    from_currency_code character varying(3) NOT NULL,
    to_currency_code character varying(3) NOT NULL,
    amount numeric(19,4) NOT NULL,
    converted_amount numeric(19,4) NOT NULL,
    rate numeric(24,10) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY conversions
    ADD CONSTRAINT conversions_pkey PRIMARY KEY (conversion_id);

CREATE INDEX idx_conversions_user ON conversions USING btree (user_id, created_at DESC);

-- banks
CREATE TABLE banks (
    bank_id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(120) NOT NULL,
    bank_name character varying(180) NOT NULL,
    gateway character varying(30) NOT NULL,
    iban character varying(120),
    currency_code character varying(3) NOT NULL,
    pay_with_bank boolean,
    swift_bic character varying(40),
    country_code character varying(3),
    country character varying(120),
    routing_number character varying(60),
    type character varying(60),
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    max_daily_value character varying(60),
    max_monthly_value character varying(60),
    min_txn_limit character varying(60),
    max_txn_limit character varying(60),
    max_weekly_value character varying(60)
);

ALTER TABLE ONLY banks
    ADD CONSTRAINT banks_pkey PRIMARY KEY (bank_id);

CREATE INDEX idx_banks_code_gateway_country ON banks USING btree (code, gateway, country_code);

CREATE UNIQUE INDEX idx_banks_routing_number ON banks USING btree (routing_number) WHERE (routing_number IS NOT NULL);

-- user_bank
CREATE TABLE user_bank (
    user_bank_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    balance numeric(19,4) DEFAULT 0 NOT NULL,
    bank_id uuid NOT NULL,
    last_digits character varying(16) NOT NULL,
    connection_status character varying(50) DEFAULT 'active'::character varying NOT NULL,
    connection_id character varying(128) NOT NULL,
    linked_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    link_label character varying(120)
);

ALTER TABLE ONLY user_bank
    ADD CONSTRAINT user_bank_pkey PRIMARY KEY (user_bank_id);

CREATE INDEX idx_user_bank_user ON user_bank USING btree (user_id);

CREATE UNIQUE INDEX uq_user_bank_primary_per_user ON user_bank USING btree (user_id) WHERE is_primary;

-- payment_channels
CREATE TABLE payment_channels (
    channel_code character varying(30) NOT NULL,
    channel_name character varying(120) NOT NULL,
    channel_type character varying(20) NOT NULL,
    country_code character varying(3) NOT NULL,
    gateway character varying(30) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    CONSTRAINT payment_channels_channel_type_check CHECK (((channel_type)::text = ANY ((ARRAY['BANK'::character varying, 'MOBILE_MONEY'::character varying])::text[])))
);

ALTER TABLE ONLY payment_channels
    ADD CONSTRAINT payment_channels_pkey PRIMARY KEY (channel_code);

CREATE INDEX idx_payment_channels_country ON payment_channels USING btree (country_code);

-- momo_providers
CREATE TABLE momo_providers (
    provider_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(180) NOT NULL,
    global_code character varying(30) NOT NULL,
    country_code character varying(3) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY momo_providers
    ADD CONSTRAINT momo_providers_pkey PRIMARY KEY (provider_id);

CREATE INDEX idx_momo_providers_global_code ON momo_providers USING btree (global_code);

-- momo_gateway_mappings
CREATE TABLE momo_gateway_mappings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_id uuid NOT NULL,
    gateway character varying(30) NOT NULL,
    gateway_code character varying(60) NOT NULL,
    country_code character varying(3) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY momo_gateway_mappings
    ADD CONSTRAINT momo_gateway_mappings_pkey PRIMARY KEY (id);

CREATE INDEX idx_momo_gateway_mappings_provider ON momo_gateway_mappings USING btree (provider_id, gateway);

-- gateway_customers
CREATE TABLE gateway_customers (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    gateway_id uuid NOT NULL,
    email character varying(100),
    gateway_customer_id character varying(128) NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE gateway_customers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gateway_customers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE ONLY gateway_customers
    ADD CONSTRAINT gateway_customers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY gateway_customers
    ADD CONSTRAINT uq_gateway_customer_id_gateway UNIQUE (id, gateway_id);

ALTER TABLE ONLY gateway_customers
    ADD CONSTRAINT uq_gateway_customer_user_gateway UNIQUE (user_id, gateway_id);

-- gateway_recipients
CREATE TABLE gateway_recipients (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    gateway_id uuid NOT NULL,
    checkout_type character varying(32) NOT NULL,
    channel_code character varying(32) NOT NULL,
    account_identifier character varying(64) NOT NULL,
    account_name character varying(150) NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    gateway_recipient_code character varying(128) NOT NULL,
    customer_id integer NOT NULL
);

ALTER TABLE gateway_recipients ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME gateway_recipients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE ONLY gateway_recipients
    ADD CONSTRAINT gateway_recipients_pkey PRIMARY KEY (id);

ALTER TABLE ONLY gateway_recipients
    ADD CONSTRAINT uq_gateway_recipient_destination UNIQUE (user_id, gateway_id, checkout_type, channel_code, account_identifier);

-- transfer_recipients
CREATE TABLE transfer_recipients (
    recipient_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    recipient_name character varying(120) NOT NULL,
    destination_type character varying(20) NOT NULL,
    account_identifier character varying(50) NOT NULL,
    provider_code character varying(30) NOT NULL,
    provider_name character varying(120) NOT NULL,
    country_code character varying(3) NOT NULL,
    currency_code character varying(3) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY transfer_recipients
    ADD CONSTRAINT transfer_recipients_pkey PRIMARY KEY (recipient_id);

ALTER TABLE ONLY transfer_recipients
    ADD CONSTRAINT uq_recipient_owner_destination UNIQUE (user_id, destination_type, account_identifier);

CREATE INDEX idx_transfer_recipients_user ON transfer_recipients USING btree (user_id);

-- loans
CREATE TABLE loans (
    loan_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    currency_code character varying(8) NOT NULL,
    principal_amount numeric(19,4) NOT NULL,
    interest_rate numeric(6,4) NOT NULL,
    term_months smallint NOT NULL,
    outstanding_balance numeric(19,4) NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    disbursement_transaction_id uuid,
    applied_at timestamp with time zone DEFAULT now() NOT NULL,
    approved_at timestamp with time zone,
    due_date date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT loans_principal_amount_check CHECK ((principal_amount > (0)::numeric)),
    CONSTRAINT loans_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'ACTIVE'::character varying, 'CLOSED'::character varying, 'DEFAULTED'::character varying])::text[]))),
    CONSTRAINT loans_term_months_check CHECK ((term_months > 0))
);

ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (loan_id);

CREATE INDEX idx_loans_user ON loans USING btree (user_id);

-- loan_repayments
CREATE TABLE loan_repayments (
    repayment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    loan_id uuid NOT NULL,
    transaction_id uuid NOT NULL,
    amount numeric(19,4) NOT NULL,
    paid_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT loan_repayments_amount_check CHECK ((amount > (0)::numeric))
);

ALTER TABLE ONLY loan_repayments
    ADD CONSTRAINT loan_repayments_pkey PRIMARY KEY (repayment_id);

ALTER TABLE ONLY loan_repayments
    ADD CONSTRAINT loan_repayments_transaction_id_key UNIQUE (transaction_id);

CREATE INDEX idx_loan_repayments_loan ON loan_repayments USING btree (loan_id);

-- savings_accounts
CREATE TABLE savings_accounts (
    savings_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    wallet_id uuid,
    savings_name character varying(80) NOT NULL,
    currency_code character varying(8) NOT NULL,
    balance numeric(19,4) DEFAULT 0 NOT NULL,
    description text,
    target_date date,
    target_amount numeric(19,4),
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT savings_accounts_balance_check CHECK ((balance >= (0)::numeric)),
    CONSTRAINT savings_accounts_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'CLOSED'::character varying])::text[])))
);

ALTER TABLE ONLY savings_accounts
    ADD CONSTRAINT savings_accounts_pkey PRIMARY KEY (savings_id);

CREATE INDEX idx_savings_user ON savings_accounts USING btree (user_id);

-- user_budgets
CREATE TABLE user_budgets (
    user_id uuid NOT NULL,
    monthly_limit numeric(19,4) NOT NULL,
    currency_code character varying(3) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY user_budgets
    ADD CONSTRAINT user_budgets_pkey PRIMARY KEY (user_id);

-- foreign keys (after all tables of this file exist)
ALTER TABLE ONLY remittances
    ADD CONSTRAINT remittances_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES users(user_id);
ALTER TABLE ONLY remittances
    ADD CONSTRAINT remittances_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES users(user_id);
ALTER TABLE ONLY remittances
    ADD CONSTRAINT remittances_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id);
ALTER TABLE ONLY conversions
    ADD CONSTRAINT conversions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY user_bank
    ADD CONSTRAINT fk_user_bank_bank FOREIGN KEY (bank_id) REFERENCES banks(bank_id);
ALTER TABLE ONLY user_bank
    ADD CONSTRAINT fk_user_bank_user FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE ONLY momo_gateway_mappings
    ADD CONSTRAINT momo_gateway_mappings_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES momo_providers(provider_id) ON DELETE CASCADE;
ALTER TABLE ONLY gateway_customers
    ADD CONSTRAINT fk_gateway_customers_user FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE ONLY gateway_customers
    ADD CONSTRAINT gateway_customers_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES gateway_providers(provider_id);
ALTER TABLE ONLY gateway_recipients
    ADD CONSTRAINT fk_gateway_recipients_customer_same_gateway FOREIGN KEY (customer_id, gateway_id) REFERENCES gateway_customers(id, gateway_id);
ALTER TABLE ONLY gateway_recipients
    ADD CONSTRAINT fk_gateway_recipients_user FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE ONLY gateway_recipients
    ADD CONSTRAINT gateway_recipients_gateway_id_fkey FOREIGN KEY (gateway_id) REFERENCES gateway_providers(provider_id);
ALTER TABLE ONLY transfer_recipients
    ADD CONSTRAINT fk_transfer_recipients_user FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_disbursement_transaction_id_fkey FOREIGN KEY (disbursement_transaction_id) REFERENCES transactions(transaction_id);
ALTER TABLE ONLY loans
    ADD CONSTRAINT loans_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE ONLY loan_repayments
    ADD CONSTRAINT loan_repayments_loan_id_fkey FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE;
ALTER TABLE ONLY loan_repayments
    ADD CONSTRAINT loan_repayments_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id);
ALTER TABLE ONLY savings_accounts
    ADD CONSTRAINT savings_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY savings_accounts
    ADD CONSTRAINT savings_accounts_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES wallets(wallet_id);
ALTER TABLE ONLY user_budgets
    ADD CONSTRAINT user_budgets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
