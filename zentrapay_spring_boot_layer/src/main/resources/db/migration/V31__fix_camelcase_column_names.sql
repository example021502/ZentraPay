-- Always put comments on all responses.
-- ============================================================
-- V31: Reconcile camelCase column names to the physical snake_case
--      names Hibernate's naming strategy actually validates against.
--
-- Why this exists: several entities declare their @Column(name=...) using
-- camelCase (e.g. "checkoutType", "countryCode", "currencyCode"). Spring Boot's
-- default physical naming strategy (CamelCaseToUnderscoresNamingStrategy)
-- converts those logical names to snake_case (checkout_type, country_code,
-- currency_code) when it validates the schema with ddl-auto=validate. But V27
-- created those columns with the literal camelCase identifiers, so Hibernate
-- looked for the snake_case physical column, couldn't find it, and boot failed
-- with "missing column [checkout_type] in table [gateway_recipients]".
--
-- This migration renames the physical columns to the snake_case form the
-- entities now require and adds the one genuinely-missing column
-- (gateway_recipients.gateway_recipient_code). Every statement is guarded so
-- it is safe to re-run.
-- ============================================================

-- ------------------------------------------------------------
-- gateway_recipients
--   checkoutType (camelCase)  -> checkout_type
--   add gateway_recipient_code (entity maps it, was never created)
-- ------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='gateway_recipients' AND column_name='checkoutType')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='gateway_recipients' AND column_name='checkout_type')
  THEN
    ALTER TABLE gateway_recipients RENAME COLUMN "checkoutType" TO checkout_type;
  END IF;
END $$;

ALTER TABLE gateway_recipients
    ADD COLUMN IF NOT EXISTS gateway_recipient_code VARCHAR(128);

-- ------------------------------------------------------------
-- momo_providers
--   countryCode (camelCase) -> country_code
-- ------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='momo_providers' AND column_name='countryCode')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='momo_providers' AND column_name='country_code')
  THEN
    ALTER TABLE momo_providers RENAME COLUMN "countryCode" TO country_code;
  END IF;
END $$;

-- ------------------------------------------------------------
-- user_cards
--   currencyCode / currencycode (both wrong) -> currency_code
--   drop provider_card_id (entity maps provider_id, which already exists)
-- ------------------------------------------------------------
DO $$
BEGIN
  -- Prefer the populated currencyCode, else currencycode, rename whichever
  -- exists into the canonical snake_case column.
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name='user_cards' AND column_name='currency_code')
  THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name='user_cards' AND column_name='currencyCode') THEN
      ALTER TABLE user_cards RENAME COLUMN "currencyCode" TO currency_code;
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name='user_cards' AND column_name='currencycode') THEN
      ALTER TABLE user_cards RENAME COLUMN currencycode TO currency_code;
    END IF;
  END IF;
END $$;

-- Any leftover camelCase duplicates are now redundant; drop them so validate
-- sees exactly one physical column per mapped field.
ALTER TABLE user_cards DROP COLUMN IF EXISTS "currencyCode";
ALTER TABLE user_cards DROP COLUMN IF EXISTS currencycode;

-- provider_card_id is not on UserCardsModel (it maps provider_id). Remove it.
ALTER TABLE user_cards DROP COLUMN IF EXISTS provider_card_id;
