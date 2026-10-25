-- V1: Reference data tables (gateways, supported countries and currencies, FX rates) and identity (users, profiles, consents, logins).

-- gateway_providers
CREATE TABLE gateway_providers (
    provider_id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone
);

ALTER TABLE ONLY gateway_providers
    ADD CONSTRAINT gateway_providers_pkey PRIMARY KEY (provider_id);

ALTER TABLE ONLY gateway_providers
    ADD CONSTRAINT gateway_providers_provider_name_key UNIQUE (provider_name);

-- gateway_countries
CREATE TABLE gateway_countries (
    country_code character varying(3) NOT NULL,
    country_name character varying(80) NOT NULL,
    iso3_code character varying(3),
    dial_code character varying(6),
    region character varying(40),
    currency_code character varying(8) DEFAULT ''::character varying NOT NULL,
    gateways text DEFAULT ''::text NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY gateway_countries
    ADD CONSTRAINT gateway_countries_pkey PRIMARY KEY (country_code);

CREATE INDEX idx_gateway_countries_active ON gateway_countries USING btree (active);

-- gateway_currencies
CREATE TABLE gateway_currencies (
    currency_code character varying(8) NOT NULL,
    currency_name character varying(60) NOT NULL,
    symbol character varying(8) DEFAULT ''::character varying NOT NULL,
    is_crypto boolean DEFAULT false NOT NULL,
    decimal_places smallint DEFAULT 2 NOT NULL,
    country_code character varying(3) DEFAULT ''::character varying NOT NULL,
    gateways text DEFAULT ''::text NOT NULL,
    is_default boolean DEFAULT true NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY gateway_currencies
    ADD CONSTRAINT gateway_currencies_pkey PRIMARY KEY (currency_code);

CREATE INDEX idx_gateway_currencies_country ON gateway_currencies USING btree (country_code);

-- exchange_rates
CREATE TABLE exchange_rates (
    rate_id uuid DEFAULT gen_random_uuid() NOT NULL,
    base_currency_code character varying(8) NOT NULL,
    quote_currency_code character varying(8) NOT NULL,
    rate numeric(24,10) NOT NULL,
    source character varying(40) NOT NULL,
    effective_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT exchange_rates_rate_check CHECK ((rate > (0)::numeric))
);

ALTER TABLE ONLY exchange_rates
    ADD CONSTRAINT exchange_rates_base_currency_code_quote_currency_code_effec_key UNIQUE (base_currency_code, quote_currency_code, effective_at);

ALTER TABLE ONLY exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (rate_id);

-- provider_categories
CREATE TABLE provider_categories (
    category_code character varying(30) NOT NULL,
    category_name character varying(60) NOT NULL
);

ALTER TABLE ONLY provider_categories
    ADD CONSTRAINT provider_categories_pkey PRIMARY KEY (category_code);

-- legal_documents
CREATE TABLE legal_documents (
    document_id uuid DEFAULT gen_random_uuid() NOT NULL,
    document_type character varying(64) NOT NULL,
    document_version character varying(32) NOT NULL,
    title character varying(255) NOT NULL,
    file_url character varying(500) NOT NULL,
    content_hash character varying(128) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    effective_date timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY legal_documents
    ADD CONSTRAINT legal_documents_file_url_key UNIQUE (file_url);

ALTER TABLE ONLY legal_documents
    ADD CONSTRAINT legal_documents_pkey PRIMARY KEY (document_id);

ALTER TABLE ONLY legal_documents
    ADD CONSTRAINT legal_documents_title_key UNIQUE (title);

-- users
CREATE TABLE users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    first_name character varying(60) NOT NULL,
    last_name character varying(60) NOT NULL,
    email character varying(120) NOT NULL,
    phone_number character varying(20) NOT NULL,
    country_code character varying(2) NOT NULL,
    password_hash character varying(120) NOT NULL,
    transaction_pin_hash character varying(120) NOT NULL,
    user_type character varying(20) DEFAULT 'APP_USER'::character varying NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    kyc_tier smallint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY users
    ADD CONSTRAINT users_email_key UNIQUE (email);

ALTER TABLE ONLY users
    ADD CONSTRAINT users_phone_number_key UNIQUE (phone_number);

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);

CREATE INDEX idx_users_country ON users USING btree (country_code);

-- user_profiles
CREATE TABLE user_profiles (
    user_id uuid NOT NULL,
    date_of_birth date,
    identity_document_type character varying(30),
    identity_document_number character varying(60),
    identity_document_issuing_country_code character varying(255),
    address_1 character varying(120),
    address_2 character varying(120),
    city_name character varying(60),
    state_or_region character varying(60),
    postal_code character varying(20),
    occupation_title character varying(80),
    anti_money_laundering_status character varying(20) DEFAULT 'CLEAR'::character varying CONSTRAINT user_profiles_aml_status_not_null NOT NULL,
    politically_exposed_person boolean DEFAULT false CONSTRAINT user_profiles_is_pep_not_null NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    nationality_country_code character varying(3),
    identity_document_expiration_date date,
    kyc_status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    id_document_front_path character varying(255),
    id_document_back_path character varying(255),
    selfie_path character varying(255),
    id_document_front_image_url character varying(500),
    id_document_back_image_url character varying(500),
    selfie_image_url character varying(500),
    risk_score_level character varying(20),
    CONSTRAINT user_profiles_aml_status_check CHECK (((anti_money_laundering_status)::text = ANY ((ARRAY['CLEAR'::character varying, 'PENDING_REVIEW'::character varying, 'FLAGGED'::character varying])::text[]))),
    CONSTRAINT user_profiles_id_document_type_check CHECK (((identity_document_type)::text = ANY ((ARRAY['NATIONAL_ID'::character varying, 'PASSPORT'::character varying, 'VOTERS_ID'::character varying, 'DRIVERS_LICENSE'::character varying, 'RESIDENCE_PERMIT'::character varying])::text[])))
);

ALTER TABLE ONLY user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (user_id);

-- merchant_profiles
CREATE TABLE merchant_profiles (
    user_id uuid NOT NULL,
    business_name character varying(120) NOT NULL,
    business_registration_number character varying(60),
    tax_identification_number character varying(60),
    business_category_code character varying(30),
    business_country_code character varying(2) NOT NULL,
    business_address character varying(200),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY merchant_profiles
    ADD CONSTRAINT merchant_profiles_pkey PRIMARY KEY (user_id);

-- user_consents
CREATE TABLE user_consents (
    consent_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    document_id uuid NOT NULL,
    ip_address character varying(20) NOT NULL,
    accepted_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY user_consents
    ADD CONSTRAINT user_consents_pkey PRIMARY KEY (consent_id);

CREATE INDEX idx_user_consents_user ON user_consents USING btree (user_id);

-- login_history
CREATE TABLE login_history (
    login_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    ip_address character varying(45),
    device_info character varying(200),
    location character varying(120),
    success boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE ONLY login_history
    ADD CONSTRAINT login_history_pkey PRIMARY KEY (login_id);

CREATE INDEX idx_login_history_user ON login_history USING btree (user_id, created_at DESC);

-- foreign keys (after all tables of this file exist)
ALTER TABLE ONLY user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY merchant_profiles
    ADD CONSTRAINT merchant_profiles_business_category_code_fkey FOREIGN KEY (business_category_code) REFERENCES provider_categories(category_code);
ALTER TABLE ONLY merchant_profiles
    ADD CONSTRAINT merchant_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE ONLY user_consents
    ADD CONSTRAINT fk_user_consents_document FOREIGN KEY (document_id) REFERENCES legal_documents(document_id);
ALTER TABLE ONLY user_consents
    ADD CONSTRAINT fk_user_consents_user FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE ONLY login_history
    ADD CONSTRAINT login_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
