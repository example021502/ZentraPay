1. Drop the existing cards table
DROP TABLE IF EXISTS cards CASCADE;

-- 2. Create the Cards Catalog / Template Table
-- Frontend queries this to display selectable cards to the user
CREATE TABLE cards (
    card_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,        -- e.g. 'Standard Virtual Card', 'Premium Metal Card'
    brand           VARCHAR(30) NOT NULL,         -- e.g. 'VISA', 'MASTERCARD'
    card_type       VARCHAR(20) NOT NULL DEFAULT 'VIRTUAL' CHECK (card_type IN ('VIRTUAL','PHYSICAL')),
    description     TEXT,                         -- Optional text for UI display
    active       BOOLEAN NOT NULL DEFAULT TRUE, -- Controls if available for users to pick
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Create the Issued User Cards Table
-- Stores actual card instance data returned by provider after user selects a template
CREATE TABLE user_cards (
    id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    card_id         UUID NOT NULL REFERENCES cards(card_id) ON DELETE RESTRICT, -- Links to chosen template
    wallet_id       UUID REFERENCES wallets(wallet_id) ON DELETE SET NULL,
    provider_card_id VARCHAR(100) UNIQUE NOT NULL, -- Card token / ID returned by provider API
    last4           CHAR(4) NOT NULL,
    expiry_month    SMALLINT NOT NULL CHECK (expiry_month BETWEEN 1 AND 12),
    expiry_year     SMALLINT NOT NULL,
    nfc_enabled     BOOLEAN NOT NULL DEFAULT TRUE,
    qr_enabled      BOOLEAN NOT NULL DEFAULT TRUE,
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','FROZEN','CLOSED')),
    issued_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for fast querying
CREATE INDEX idx_cards_active ON cards(is_active);
CREATE INDEX idx_user_cards_user ON user_cards(user_id);
CREATE INDEX idx_user_cards_provider ON user_cards(provider_card_id);