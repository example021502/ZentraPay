-- ============================================================
-- V27: CREATE ENTITY TABLES MISSING FROM THE FLYWAY SCHEMA
--
-- With `ddl-auto=validate`, Hibernate refuses to boot if ANY @Entity has no
-- matching table. The following @Entity classes were never given a CREATE TABLE
-- by V1–V26 (they only ever existed via ad-hoc Hibernate DDL / hand-made dev
-- state), so the backend failed with a schema-validation "missing table" error.
-- This migration creates each table to match its entity field-for-field so the
-- final schema passes validation on a fresh database.
--
-- It also (re)creates `user_reward_balances`, which V18 dropped but which is
-- still mapped by the UserRewardBalances @Entity — the entity is canonical, so
-- the schema must provide the table again (created AFTER V18's drop).
-- ============================================================

-- accounts  (FiatAccountModel) — canonical fiat wallet
CREATE TABLE IF NOT EXISTS accounts (
    account_id     UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    wallet_id      UUID NOT NULL,
    account_name   VARCHAR(255) NOT NULL,
    currency_code  VARCHAR(3) NOT NULL,
    zentag         VARCHAR(64) NOT NULL,
    balance        NUMERIC(19,4) NOT NULL DEFAULT 0,
    is_default     BOOLEAN NOT NULL DEFAULT FALSE,
    status         VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_accounts_wallet ON accounts(wallet_id);

-- crypto_accounts  (CryptoAccountModel) — canonical crypto wallet
-- NOTE: currency_code is VARCHAR(20) — UsersService seeds the placeholder
--       "Unknown", which does not fit a CHAR(3) column.
CREATE TABLE IF NOT EXISTS crypto_accounts (
    account_id      UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    wallet_id       UUID NOT NULL,
    currency_code   VARCHAR(20) NOT NULL,
    network         VARCHAR(30),
    wallet_address  VARCHAR(120) NOT NULL UNIQUE,
    balance         NUMERIC(28,10) NOT NULL DEFAULT 0,
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    status          VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_crypto_accounts_wallet ON crypto_accounts(wallet_id);

-- gateway_providers  (GatewayModel) — created first: other gateway_* tables
-- reference gateway_providers.provider_id.
CREATE TABLE IF NOT EXISTS gateway_providers (
    provider_id    UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    provider_name  VARCHAR(255) NOT NULL UNIQUE,
    description    VARCHAR(255) NOT NULL,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ
);

-- gateway_customers  (GatewayCustomerModel)
-- NOTE: id is a 32-bit INT identity (entity field is Integer).
CREATE TABLE IF NOT EXISTS gateway_customers (
    id                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id             UUID NOT NULL,
    gateway_id          UUID NOT NULL REFERENCES gateway_providers(provider_id),
    gateway             VARCHAR(100),
    email               VARCHAR(100),
    gateway_customer_id VARCHAR(128) NOT NULL,
    created_at          TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_gateway_customers_user ON gateway_customers(user_id);
-- gateway_recipients  (GatewayRecipientsModel)
-- NOTE: id is a 64-bit BIGINT identity (entity field is Long); `checkoutType`
-- is the exact column name the entity maps (Postgres folds it to lowercase).
CREATE TABLE IF NOT EXISTS gateway_recipients (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id             UUID NOT NULL,
    gateway_id          UUID NOT NULL REFERENCES gateway_providers(provider_id),
    gateway             VARCHAR(100),
    gateway_recipient_id VARCHAR(128) NOT NULL,
    "checkoutType"      VARCHAR(32) NOT NULL,
    channel_code        VARCHAR(32) NOT NULL,
    account_identifier  VARCHAR(64) NOT NULL,
    account_name        VARCHAR(150) NOT NULL,
    created_at          TIMESTAMPTZ,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_gateway_recipients_user ON gateway_recipients(user_id);

-- legal_documents  (LegalDocumentsModel) — T&C / privacy policy versions
CREATE TABLE IF NOT EXISTS legal_documents (
    document_id       UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    document_type     VARCHAR(64) NOT NULL,
    document_version  VARCHAR(32) NOT NULL,
    title             VARCHAR(255) NOT NULL UNIQUE,
    file_url          VARCHAR(500) NOT NULL UNIQUE,
    content_hash      VARCHAR(128) NOT NULL,
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    effective_date    TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- user_consents  (UserConsentsModel)
-- NOTE: entity declares ip_address UNIQUE (and has NO updated_at column).
CREATE TABLE IF NOT EXISTS user_consents (
    consent_id   UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id      UUID NOT NULL,
    document_id  UUID NOT NULL,
    ip_address   VARCHAR(20) NOT NULL UNIQUE,
    accepted_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_consents_user ON user_consents(user_id);

-- transfer_recipients  (TransferRecipientModel) — gateway-neutral payout target
CREATE TABLE IF NOT EXISTS transfer_recipients (
    recipient_id       UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id            UUID NOT NULL,
    recipient_name     VARCHAR(120) NOT NULL,
    destination_type   VARCHAR(20) NOT NULL,
    account_identifier VARCHAR(50) NOT NULL,
    provider_code      VARCHAR(30) NOT NULL,
    provider_name      VARCHAR(120) NOT NULL,
    country_code       VARCHAR(3) NOT NULL,
    currency_code      VARCHAR(3) NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_recipient_owner_destination UNIQUE (user_id, destination_type, account_identifier)
);
CREATE INDEX IF NOT EXISTS idx_transfer_recipients_user ON transfer_recipients(user_id);

-- user_bank  (UserBankModel) — a user's linked bank / mobile-money account
CREATE TABLE IF NOT EXISTS user_bank (
    user_bank_id      UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id           UUID NOT NULL,
    balance           NUMERIC(19,4) NOT NULL DEFAULT 0,
    bank_id           UUID NOT NULL,
    last_digits       VARCHAR(16) NOT NULL,
    connection_status VARCHAR(50) NOT NULL DEFAULT 'active',
    connection_id     VARCHAR(128) NOT NULL,
    linked_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_bank_user ON user_bank(user_id);

-- user_bill_providers  (UserBillProviderModel)
-- NOTE: entity marks user_id UNIQUE (one saved biller reference per user).
CREATE TABLE IF NOT EXISTS user_bill_providers (
    user_bill_provider_id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id              UUID NOT NULL UNIQUE,
    provider_id          UUID NOT NULL,
    account_reference    VARCHAR(128) NOT NULL,
    linked_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- user_payment_gateways  (UserPaymentGatewayModel) — per-user gateway identity
CREATE TABLE IF NOT EXISTS user_payment_gateways (
    user_gateway_id     UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id             UUID NOT NULL,
    gateway_name        VARCHAR(30) NOT NULL,
    gateway_customer_id VARCHAR(100) NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_user_gateway UNIQUE (user_id, gateway_name)
);
CREATE INDEX IF NOT EXISTS idx_user_payment_gateways_user ON user_payment_gateways(user_id);

-- user_reward_balances  (UserRewardBalances) — recreated AFTER V18 dropped it;
-- the entity is canonical so the schema must provide the table again.
-- NOTE: `id` is a plain INT (identity) primary key; column updated_on (no updated_at).
CREATE TABLE IF NOT EXISTS user_reward_balances (
    id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    total_points INT NOT NULL DEFAULT 0,
    reward_type  VARCHAR(50) NOT NULL,
    updated_on   TIMESTAMPTZ NOT NULL DEFAULT now()
);

