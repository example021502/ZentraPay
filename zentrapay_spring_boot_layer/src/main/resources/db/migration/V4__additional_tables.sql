-- Additional tables identified while writing the API contract (docs/API_CONTRACT.md).

-- ZBanking "Budget" tab — one simple monthly limit per user; spend-so-far is
-- always derived live from `transactions`, not duplicated here.
CREATE TABLE user_budgets (
    user_id        UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    monthly_limit  NUMERIC(19,4) NOT NULL,
    currency_code  CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Converter conversion-history — the old service faked this endpoint by
-- always returning an empty list because nothing was ever persisted.
CREATE TABLE conversions (
    conversion_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    from_currency_code CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    to_currency_code   CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    amount             NUMERIC(19,4) NOT NULL,
    converted_amount   NUMERIC(19,4) NOT NULL,
    rate               NUMERIC(24,10) NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_conversions_user ON conversions(user_id, created_at DESC);
