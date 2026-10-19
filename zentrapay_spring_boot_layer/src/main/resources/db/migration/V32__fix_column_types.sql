-- Always put comments on all responses.
-- ============================================================
-- V32: Reconcile column TYPES to what the entities expect.
--
-- With ddl-auto=validate, Hibernate checks not just column NAMES but the
-- column TYPE category. Two classes of drift were left by earlier migrations:
--
--  1. CHAR / bpchar columns (from V1's CHAR(2)/CHAR(3) country & currency
--     codes) that the entities map as plain String -> VARCHAR.
--  2. PostgreSQL native enum columns (users.user_type, users.status,
--     ledger_entries.type) that the entities map with @Enumerated(EnumType.STRING)
--     -> Hibernate expects a VARCHAR holding the enum's .name() text.
--
-- Every statement is guarded by a check on the column's current type so the
-- migration is safe to re-run and never double-converts.
-- ============================================================

-- ------------------------------------------------------------
-- 1. bpchar (CHAR) -> varchar, matching the entity's String mapping.
-- ------------------------------------------------------------
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='merchant_profiles' AND column_name='business_country_code' AND data_type='character') THEN
    ALTER TABLE merchant_profiles ALTER COLUMN business_country_code TYPE VARCHAR(2);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='remittances' AND column_name='recipient_country_code' AND data_type='character') THEN
    ALTER TABLE remittances ALTER COLUMN recipient_country_code TYPE VARCHAR(2);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='transactions' AND column_name='source_currency_code' AND data_type='character') THEN
    ALTER TABLE transactions ALTER COLUMN source_currency_code TYPE VARCHAR(3);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='transactions' AND column_name='destination_currency_code' AND data_type='character') THEN
    ALTER TABLE transactions ALTER COLUMN destination_currency_code TYPE VARCHAR(3);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='user_cards' AND column_name='last4' AND data_type='character') THEN
    ALTER TABLE user_cards ALTER COLUMN last4 TYPE VARCHAR(4);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='user_profiles' AND column_name='identity_document_issuing_country_code' AND data_type='character') THEN
    ALTER TABLE user_profiles ALTER COLUMN identity_document_issuing_country_code TYPE VARCHAR(255);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='users' AND column_name='country_code' AND data_type='character') THEN
    ALTER TABLE users ALTER COLUMN country_code TYPE VARCHAR(2);
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='wallets' AND column_name='country_code' AND data_type='character') THEN
    ALTER TABLE wallets ALTER COLUMN country_code TYPE VARCHAR(3);
  END IF;
END $$;

-- ------------------------------------------------------------
-- 2. Native enum -> varchar, because the entities persist these
--    fields with @Enumerated(EnumType.STRING) (a plain VARCHAR).
--    The enum label text is preserved via an explicit ::text cast.
-- ------------------------------------------------------------
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='users' AND column_name='user_type' AND data_type='USER-DEFINED') THEN
    ALTER TABLE users ALTER COLUMN user_type TYPE VARCHAR(20) USING user_type::text;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='users' AND column_name='status' AND data_type='USER-DEFINED') THEN
    ALTER TABLE users ALTER COLUMN status TYPE VARCHAR(20) USING status::text;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='ledger_entries' AND column_name='type' AND data_type='USER-DEFINED') THEN
    ALTER TABLE ledger_entries ALTER COLUMN type TYPE VARCHAR(10) USING type::text;
  END IF;
END $$;
