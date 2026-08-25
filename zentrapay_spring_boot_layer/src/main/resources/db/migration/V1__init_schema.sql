-- ZentraPay core schema — normalized (3NF), Africa-first.
--
-- Design notes:
--  * All surrogate keys are UUID (gen_random_uuid()), matching the JWT `sub`
--    claim (a UUID string) and avoiding sequential-ID enumeration of users/
--    money movements across the many independent country/currency corridors
--    this app serves.
--  * Reference data (countries, currencies, transaction types, provider
--    categories) is normalized into lookup tables instead of being repeated
--    as free-text on every row — this is what "supports Africa at large"
--    concretely means here: adding a new country or currency is a seed-data
--    INSERT, not a schema change or a new magic string scattered across
--    Java/Dart code.
--  * Money columns are NUMERIC (never FLOAT/DOUBLE) to avoid the rounding
--    bugs already present in the old ad-hoc entities (one had `balance` typed
--    as a String, another as Double). NUMERIC(19,4) covers fiat; crypto gets
--    more decimal places.
--  * One physical table per real-world concept. The old codebase had three
--    independent @Entity classes mapped onto "cards", two onto
--    "crypto_currencies", two onto "user_wallets" — each with a different,
--    incompatible column set. This migration collapses each collision to a
--    single table.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- REFERENCE / LOOKUP TABLES
-- ============================================================

CREATE TABLE currencies (
    currency_code   CHAR(3) PRIMARY KEY,              -- ISO 4217, or a short crypto ticker
    currency_name   VARCHAR(60) NOT NULL,
    symbol          VARCHAR(8) NOT NULL,
    is_crypto       BOOLEAN NOT NULL DEFAULT FALSE,
    decimal_places  SMALLINT NOT NULL DEFAULT 2,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE countries (
    country_code            CHAR(2) PRIMARY KEY,      -- ISO 3166-1 alpha-2
    iso3_code                CHAR(3) NOT NULL UNIQUE,
    country_name             VARCHAR(80) NOT NULL,
    dial_code                VARCHAR(6) NOT NULL,      -- e.g. +233
    default_currency_code    CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    region                   VARCHAR(40),               -- e.g. West Africa, East Africa
    is_active                BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX idx_countries_region ON countries(region);

CREATE TABLE transaction_types (
    type_code       VARCHAR(30) PRIMARY KEY,          -- e.g. TRANSFER_INTERNAL
    description     VARCHAR(120) NOT NULL,
    is_credit       BOOLEAN NOT NULL                  -- true = increases wallet balance
);

CREATE TABLE provider_categories (
    category_code   VARCHAR(30) PRIMARY KEY,          -- e.g. UTILITY, AIRTIME, TV
    category_name   VARCHAR(60) NOT NULL
);

-- Bank / mobile-money channel directory, cached from gateway providers
-- (Paystack/Flutterwave/Onafriq bank lists) so bank-select UIs and account
-- resolution don't depend on a live third-party call every keystroke.
CREATE TABLE payment_channels (
    channel_code     VARCHAR(30) PRIMARY KEY,          -- gateway-provided bank/momo code
    channel_name     VARCHAR(120) NOT NULL,
    channel_type     VARCHAR(20) NOT NULL CHECK (channel_type IN ('BANK','MOBILE_MONEY')),
    country_code     CHAR(2) NOT NULL REFERENCES countries(country_code),
    gateway          VARCHAR(30) NOT NULL,             -- which gateway this code belongs to
    is_active        BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX idx_payment_channels_country ON payment_channels(country_code);

-- ============================================================
-- IDENTITY
-- ============================================================

CREATE TABLE users (
    user_id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name              VARCHAR(60) NOT NULL,
    last_name                VARCHAR(60) NOT NULL,
    email                    VARCHAR(120) NOT NULL UNIQUE,
    phone_number             VARCHAR(20) NOT NULL UNIQUE,   -- full E.164, e.g. +233241234567
    country_code             CHAR(2) NOT NULL REFERENCES countries(country_code),
    password_hash             VARCHAR(120) NOT NULL,
    transaction_pin_hash      VARCHAR(120) NOT NULL,
    zentag                    VARCHAR(40) NOT NULL UNIQUE,
    user_type                 VARCHAR(20) NOT NULL DEFAULT 'INDIVIDUAL' CHECK (user_type IN ('INDIVIDUAL','MERCHANT')),
    status                    VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','PENDING_VERIFICATION','CLOSED')),
    kyc_tier                  SMALLINT NOT NULL DEFAULT 0,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_users_country ON users(country_code);

-- 1:1 KYC/identity extension — split out of `users` because most rows here
-- start NULL (progressive KYC: full name/phone/email at signup, documents
-- only once a user tries to move meaningful amounts of money).
CREATE TABLE user_profiles (
    user_id                     UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    date_of_birth               DATE,
    id_document_type            VARCHAR(30) CHECK (id_document_type IN ('NATIONAL_ID','PASSPORT','VOTERS_ID','DRIVERS_LICENSE','RESIDENCE_PERMIT')),
    id_document_number          VARCHAR(60),
    id_document_country_code    CHAR(2) REFERENCES countries(country_code),
    address_line1                VARCHAR(120),
    address_line2                VARCHAR(120),
    city                          VARCHAR(60),
    region_state                  VARCHAR(60),
    postal_code                   VARCHAR(20),
    occupation                    VARCHAR(80),
    aml_status                    VARCHAR(20) NOT NULL DEFAULT 'CLEAR' CHECK (aml_status IN ('CLEAR','PENDING_REVIEW','FLAGGED')),
    is_pep                         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at                     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1:1 merchant extension, only present when users.user_type = 'MERCHANT'.
CREATE TABLE merchant_profiles (
    user_id                          UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    business_name                     VARCHAR(120) NOT NULL,
    business_registration_number      VARCHAR(60),
    tax_identification_number         VARCHAR(60),
    business_category_code            VARCHAR(30) REFERENCES provider_categories(category_code),
    business_country_code             CHAR(2) NOT NULL REFERENCES countries(country_code),
    business_address                  VARCHAR(200),
    created_at                        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- WALLETS, CARDS, TRANSACTIONS
-- ============================================================

-- Consolidates the old fiat_currency_accounts / fiat_currencies /
-- user_wallets (x2 conflicting mappings) into one fiat wallet table.
CREATE TABLE wallets (
    wallet_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    wallet_name     VARCHAR(60) NOT NULL,
    currency_code   CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    country_code    CHAR(2) REFERENCES countries(country_code),
    balance         NUMERIC(19,4) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','FROZEN','CLOSED')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, wallet_name)
);
CREATE INDEX idx_wallets_user ON wallets(user_id);

-- Crypto wallet holding. Table only — service logic for balances/transfers
-- here is intentionally left as TODO (implemented in a later pass).
CREATE TABLE crypto_wallets (
    crypto_wallet_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    currency_code     CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    network           VARCHAR(30),
    wallet_address    VARCHAR(120) NOT NULL UNIQUE,
    balance           NUMERIC(28,10) NOT NULL DEFAULT 0,
    status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','FROZEN','CLOSED')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_crypto_wallets_user ON crypto_wallets(user_id);

-- Consolidates cards.CardsModel / zpay.CardModel (both previously mapped to
-- "cards" with different columns) into one table.
CREATE TABLE cards (
    card_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    wallet_id       UUID REFERENCES wallets(wallet_id),
    brand           VARCHAR(30) NOT NULL,
    card_type       VARCHAR(20) NOT NULL DEFAULT 'VIRTUAL' CHECK (card_type IN ('VIRTUAL','PHYSICAL')),
    last4           CHAR(4) NOT NULL,
    expiry_month    SMALLINT NOT NULL CHECK (expiry_month BETWEEN 1 AND 12),
    expiry_year     SMALLINT NOT NULL,
    nfc_enabled     BOOLEAN NOT NULL DEFAULT TRUE,
    qr_enabled      BOOLEAN NOT NULL DEFAULT TRUE,
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','FROZEN','CLOSED')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_cards_user ON cards(user_id);

-- Canonical money-movement ledger — every wallet balance change (transfer,
-- bill payment, savings deposit, loan disbursement, remittance, card
-- payment, reward credit...) is recorded here exactly once.
CREATE TABLE transactions (
    transaction_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL REFERENCES users(user_id),
    wallet_id             UUID REFERENCES wallets(wallet_id),
    type_code             VARCHAR(30) NOT NULL REFERENCES transaction_types(type_code),
    amount                NUMERIC(19,4) NOT NULL CHECK (amount >= 0),
    currency_code         CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    status                VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SUCCESS','FAILED','REVERSED')),
    gateway               VARCHAR(30),
    reference             VARCHAR(100) NOT NULL UNIQUE,
    gateway_reference     VARCHAR(100),
    counterparty_user_id  UUID REFERENCES users(user_id),
    counterparty_name     VARCHAR(120),
    counterparty_identifier VARCHAR(120),
    description           TEXT,
    metadata              JSONB,
    failure_reason        TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_transactions_user ON transactions(user_id, created_at DESC);
CREATE INDEX idx_transactions_type ON transactions(type_code);
CREATE INDEX idx_transactions_status ON transactions(status);

-- ============================================================
-- BILLS & SERVICES
-- ============================================================

CREATE TABLE bill_providers (
    provider_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    biller_code              VARCHAR(40) NOT NULL UNIQUE,
    biller_name              VARCHAR(120) NOT NULL,
    category_code            VARCHAR(30) NOT NULL REFERENCES provider_categories(category_code),
    country_code             CHAR(2) NOT NULL REFERENCES countries(country_code),
    logo_url                 TEXT,
    customer_params_schema   JSONB,
    fetch_requirement        VARCHAR(60),
    status                   VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE')),
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_bill_providers_category ON bill_providers(category_code);
CREATE INDEX idx_bill_providers_country ON bill_providers(country_code);

CREATE TABLE service_providers (
    provider_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_code            VARCHAR(40) NOT NULL UNIQUE,
    provider_name            VARCHAR(120) NOT NULL,
    category_code            VARCHAR(30) NOT NULL REFERENCES provider_categories(category_code),
    aggregator_gateway       VARCHAR(30),
    country_code             CHAR(2) NOT NULL REFERENCES countries(country_code),
    logo_url                  TEXT,
    metadata                  JSONB,
    min_amount                 NUMERIC(19,2),
    max_amount                 NUMERIC(19,2),
    is_active                  BOOLEAN NOT NULL DEFAULT TRUE,
    is_maintenance_mode         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_service_providers_category ON service_providers(category_code);
CREATE INDEX idx_service_providers_country ON service_providers(country_code);

CREATE TABLE bill_payments (
    payment_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES users(user_id),
    provider_id          UUID NOT NULL REFERENCES bill_providers(provider_id),
    transaction_id       UUID NOT NULL UNIQUE REFERENCES transactions(transaction_id),
    customer_reference   VARCHAR(60) NOT NULL,       -- e.g. meter number, account number
    amount               NUMERIC(19,4) NOT NULL,
    currency_code        CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    status               VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SUCCESS','FAILED')),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_bill_payments_user ON bill_payments(user_id);

-- ============================================================
-- REMITTANCE & FX
-- ============================================================

-- Append-only rate history; the "current" rate for a pair is the row with
-- the latest effective_at (see the ConverterService/RemittanceService
-- query, not a separate mutable "current rate" table — avoids update
-- anomalies between a history table and a duplicate current-value table).
CREATE TABLE exchange_rates (
    rate_id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    base_currency_code    CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    quote_currency_code   CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    rate                  NUMERIC(24,10) NOT NULL CHECK (rate > 0),
    source                VARCHAR(40) NOT NULL,
    effective_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (base_currency_code, quote_currency_code, effective_at)
);
CREATE INDEX idx_exchange_rates_pair_latest ON exchange_rates(base_currency_code, quote_currency_code, effective_at DESC);

CREATE TABLE remittances (
    remittance_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id                 UUID NOT NULL REFERENCES users(user_id),
    receiver_id                UUID REFERENCES users(user_id),      -- NULL when receiver isn't an app user
    transaction_id             UUID NOT NULL UNIQUE REFERENCES transactions(transaction_id),
    amount                     NUMERIC(19,4) NOT NULL,
    source_currency_code       CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    destination_currency_code  CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    exchange_rate               NUMERIC(24,10) NOT NULL,
    fee                          NUMERIC(19,4) NOT NULL DEFAULT 0,
    status                       VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SUCCESS','FAILED','REVERSED')),
    channel                      VARCHAR(30) NOT NULL,
    recipient_name                VARCHAR(120) NOT NULL,
    recipient_phone_number        VARCHAR(20),
    recipient_country_code        CHAR(2) NOT NULL REFERENCES countries(country_code),
    reference                     VARCHAR(100) NOT NULL UNIQUE,
    created_at                    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_remittances_sender ON remittances(sender_id, created_at DESC);

-- ============================================================
-- ZBANKING: SAVINGS & LOANS
-- ============================================================

CREATE TABLE savings_accounts (
    savings_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    wallet_id         UUID REFERENCES wallets(wallet_id),
    savings_name      VARCHAR(80) NOT NULL,
    currency_code     CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    balance           NUMERIC(19,4) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    description       TEXT,
    target_date       DATE,
    target_amount     NUMERIC(19,4),
    status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','CLOSED')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_savings_user ON savings_accounts(user_id);

CREATE TABLE loans (
    loan_id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID NOT NULL REFERENCES users(user_id),
    currency_code                CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    principal_amount              NUMERIC(19,4) NOT NULL CHECK (principal_amount > 0),
    interest_rate                  NUMERIC(6,4) NOT NULL,      -- annual percentage rate
    term_months                     SMALLINT NOT NULL CHECK (term_months > 0),
    outstanding_balance              NUMERIC(19,4) NOT NULL,
    status                            VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','REJECTED','ACTIVE','CLOSED','DEFAULTED')),
    disbursement_transaction_id       UUID REFERENCES transactions(transaction_id),
    applied_at                        TIMESTAMPTZ NOT NULL DEFAULT now(),
    approved_at                       TIMESTAMPTZ,
    due_date                          DATE,
    created_at                        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_loans_user ON loans(user_id);

CREATE TABLE loan_repayments (
    repayment_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id           UUID NOT NULL REFERENCES loans(loan_id) ON DELETE CASCADE,
    transaction_id    UUID NOT NULL UNIQUE REFERENCES transactions(transaction_id),
    amount            NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    paid_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_loan_repayments_loan ON loan_repayments(loan_id);

-- ============================================================
-- ZGROW: CHALLENGES, LITERACY, REWARDS
-- ============================================================

CREATE TABLE challenges (
    challenge_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title             VARCHAR(120) NOT NULL,
    description       TEXT,
    category          VARCHAR(40),
    duration_days     INTEGER NOT NULL,
    points_reward     INTEGER NOT NULL DEFAULT 0,
    difficulty        VARCHAR(20) CHECK (difficulty IN ('EASY','MEDIUM','HARD')),
    status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','ARCHIVED')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
    -- participant count is derived via COUNT(*) on challenge_participants,
    -- not stored here, to avoid a second source of truth going stale.
);

CREATE TABLE challenge_participants (
    participant_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id       UUID NOT NULL REFERENCES challenges(challenge_id) ON DELETE CASCADE,
    user_id            UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    joined_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    progress_percent   SMALLINT NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
    completed_at       TIMESTAMPTZ,
    points_earned      INTEGER NOT NULL DEFAULT 0,
    UNIQUE (challenge_id, user_id)
);
CREATE INDEX idx_challenge_participants_user ON challenge_participants(user_id);

CREATE TABLE financial_literacy_content (
    content_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title             VARCHAR(150) NOT NULL,
    category          VARCHAR(40),
    content_url       TEXT,
    duration_minutes  INTEGER,
    points_reward     INTEGER NOT NULL DEFAULT 0,
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE content_completions (
    completion_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id        UUID NOT NULL REFERENCES financial_literacy_content(content_id) ON DELETE CASCADE,
    user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    completed_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    points_earned     INTEGER NOT NULL DEFAULT 0,
    UNIQUE (content_id, user_id)
);
CREATE INDEX idx_content_completions_user ON content_completions(user_id);

-- Append-only ledger of every point award (challenge completion, learn-and-
-- earn, referral, ...). `user_reward_balances` is a transactionally
-- maintained running total kept only so reads don't need to SUM() the
-- whole ledger every time — the ledger remains the source of truth.
CREATE TABLE points_ledger (
    ledger_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    points            INTEGER NOT NULL,
    reason            VARCHAR(60) NOT NULL,
    reference_type    VARCHAR(30),                     -- CHALLENGE, LITERACY_CONTENT, REFERRAL...
    reference_id      UUID,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_points_ledger_user ON points_ledger(user_id, created_at DESC);

CREATE TABLE user_reward_balances (
    user_id       UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    total_points  INTEGER NOT NULL DEFAULT 0,
    tier          VARCHAR(20) NOT NULL DEFAULT 'BRONZE' CHECK (tier IN ('BRONZE','SILVER','GOLD','PLATINUM')),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- ZINVEST: INVESTMENTS
-- ============================================================

CREATE TABLE investments (
    investment_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name              VARCHAR(120) NOT NULL,
    investment_type   VARCHAR(20) NOT NULL CHECK (investment_type IN ('STOCK','ETF','COMMODITY','CRYPTO','OTHER')),
    symbol            VARCHAR(20),
    quantity          NUMERIC(19,4) NOT NULL CHECK (quantity > 0),
    buy_price         NUMERIC(19,4) NOT NULL,
    currency_code     CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    status            VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','CLOSED')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_investments_user ON investments(user_id);

-- Historical price points so liquidity-trend can plot a real series instead
-- of a single "Now" data point.
CREATE TABLE investment_price_snapshots (
    snapshot_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investment_id   UUID NOT NULL REFERENCES investments(investment_id) ON DELETE CASCADE,
    price           NUMERIC(19,4) NOT NULL,
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_price_snapshots_investment ON investment_price_snapshots(investment_id, recorded_at DESC);

-- ============================================================
-- SECURITY
-- ============================================================

CREATE TABLE security_settings (
    settings_id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                    UUID NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    biometric_enabled           BOOLEAN NOT NULL DEFAULT FALSE,
    biometric_type              VARCHAR(20),
    two_factor_enabled            BOOLEAN NOT NULL DEFAULT FALSE,
    two_factor_method              VARCHAR(20),
    fraud_protection_enabled         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE login_history (
    login_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    ip_address    VARCHAR(45),
    device_info   VARCHAR(200),
    location      VARCHAR(120),
    success       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_login_history_user ON login_history(user_id, created_at DESC);

CREATE TABLE fraud_alerts (
    alert_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    alert_type              VARCHAR(40) NOT NULL,
    message                 TEXT NOT NULL,
    severity                VARCHAR(20) NOT NULL DEFAULT 'LOW' CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    is_resolved             BOOLEAN NOT NULL DEFAULT FALSE,
    related_transaction_id  UUID REFERENCES transactions(transaction_id),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_fraud_alerts_user ON fraud_alerts(user_id, created_at DESC);

-- ============================================================
-- ZVOICE
-- ============================================================

CREATE TABLE voice_commands (
    command_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    command_type    VARCHAR(20) NOT NULL CHECK (command_type IN ('VOICE','CHAT')),
    language        VARCHAR(10) NOT NULL DEFAULT 'en',
    transcript      TEXT NOT NULL,
    response_text   TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'PROCESSED',
    fraud_alert     BOOLEAN NOT NULL DEFAULT FALSE,
    fraud_reason    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_voice_commands_user ON voice_commands(user_id, created_at DESC);
