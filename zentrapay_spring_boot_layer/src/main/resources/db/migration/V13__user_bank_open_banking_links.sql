-- V13: user_bank becomes the table of OPEN-BANKING linked accounts (AfriLink).
--
-- Why not reuse `banks`?  `banks` is the payout catalogue synced from Paystack / Flutterwave
-- (each row carries a gateway-specific code).  A bank the user links through the AfriLink
-- widget is a different thing - it is identified by AfriLink's own account id and may not exist
-- in that catalogue at all.  So the link keeps its own provider data on `user_bank` and the
-- catalogue reference (bank_id) becomes an optional, best-effort match instead of a requirement.
--
-- Nothing sensitive is stored: no full account number, no credentials - only AfriLink's opaque
-- account id, the institution name and the last digits AfriLink reports.

ALTER TABLE user_bank ALTER COLUMN bank_id DROP NOT NULL;
ALTER TABLE user_bank ALTER COLUMN last_digits SET DEFAULT '';

ALTER TABLE user_bank ADD COLUMN IF NOT EXISTS provider character varying(30) NOT NULL DEFAULT 'LEGACY';
ALTER TABLE user_bank ADD COLUMN IF NOT EXISTS provider_account_id character varying(128);
ALTER TABLE user_bank ADD COLUMN IF NOT EXISTS institution_id character varying(128);
ALTER TABLE user_bank ADD COLUMN IF NOT EXISTS institution_name character varying(180);
ALTER TABLE user_bank ADD COLUMN IF NOT EXISTS account_type character varying(40);
ALTER TABLE user_bank ADD COLUMN IF NOT EXISTS currency_code character varying(3);
ALTER TABLE user_bank ADD COLUMN IF NOT EXISTS country_code character varying(3);

-- One AfriLink account can be linked to exactly one ZentraPay user, ever.
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_bank_provider_account
    ON user_bank USING btree (provider, provider_account_id)
    WHERE provider_account_id IS NOT NULL;

-- Funding sources offered on the wallet top-up screen (GET /api/zgrow/sources).
-- The entity existed but its table was never migrated, so the screen had nothing to list.
-- Dropped first: with ddl-auto=update Hibernate may already have created an empty copy of this table
-- with an ordinal (smallint) payment_method column.  It is a pure catalogue with no references.
DROP TABLE IF EXISTS funding_sources;
CREATE TABLE funding_sources (
    source_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    name character varying(120) NOT NULL,
    payment_method character varying(40) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT funding_sources_method_check CHECK (payment_method IN ('BANK_TRANSFER', 'MOBILE_MONEY_TRANSFER', 'CARD_TRANSFER'))
);

INSERT INTO funding_sources (name, payment_method)
SELECT v.name, v.payment_method
FROM (VALUES ('Card', 'CARD_TRANSFER'),
             ('Bank', 'BANK_TRANSFER'),
             ('Mobile Money', 'MOBILE_MONEY_TRANSFER')) AS v(name, payment_method)
WHERE NOT EXISTS (SELECT 1 FROM funding_sources);
