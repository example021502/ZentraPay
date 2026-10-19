-- Always put comments on all responses.
-- ============================================================
-- V33: Reconcile user_cards expiry column types to the entity.
--
-- V16 created user_cards.expiry_month / expiry_year as SMALLINT (the
-- `length=2` on the entity's @Column was misread as a width that should
-- become SMALLINT). But UserCardsModel types both fields as `Integer`,
-- which Hibernate validate expects as INTEGER (int4), not SMALLINT (int2).
-- Widen both columns to integer so ddl-auto=validate passes.
--
-- Each statement is guarded on the current type so this migration is safe
-- to re-run and never double-converts.
-- ============================================================
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='user_cards' AND column_name='expiry_month' AND data_type='smallint') THEN
    ALTER TABLE user_cards ALTER COLUMN expiry_month TYPE INTEGER;
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name='user_cards' AND column_name='expiry_year' AND data_type='smallint') THEN
    ALTER TABLE user_cards ALTER COLUMN expiry_year TYPE INTEGER;
  END IF;
END $$;