-- ============================================================
-- V8: Realign the `transactions` table with TransactionModel.
--
-- The original V1 `transactions` table was written for an older
-- ledger shape (user_id / type_code / currency_code / reference /
-- counterparty_* / description / ...). That no longer matches the
-- canonical entity TransactionModel, which is the source of truth for
-- what this table holds. Transaction history (GET /api/transactions)
-- stopped showing rows because the entity's mapped columns did not
-- exist in the real table: writes failed and the history query scanned
-- missing columns.
--
-- This migration reconciles both fresh (V1-shaped) Flyway databases and
-- existing Hibernate/update-created databases to match the entity.
-- Every statement is guarded / 'IF NOT EXISTS' so it is idempotent.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Normalise the receiver leg column.
--    Older builds mapped the entity to a camelCase 'receiverId'
--    column (PostgreSQL folds it to 'receiverid'). Rename that to
--    the canonical snake_case 'receiver_id' when present, so data is
--    preserved and there is no duplicate/aliased column.
-- ------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transactions' AND column_name = 'receiver_id'
  ) THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'transactions' AND column_name = 'receiverid'
    ) THEN
      ALTER TABLE transactions RENAME COLUMN receiverid TO receiver_id;
    ELSIF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'transactions' AND column_name = 'receiverId'
    ) THEN
      ALTER TABLE transactions RENAME COLUMN "receiverId" TO receiver_id;
    END IF;
  END IF;
END $$;

-- ------------------------------------------------------------
-- 2. Add every column the entity maps (no-op where present).
--    Columns are created nullable so applying to a table that
--    already holds rows cannot fail; the application always sets
--    these fields on insert.
-- ------------------------------------------------------------
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS entry_id VARCHAR(255);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS transaction_type VARCHAR(30);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS sender_id UUID;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS receiver_id UUID;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS sender_name VARCHAR(180);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS receiver_name VARCHAR(180);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS source_currency_code CHAR(3);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS destination_currency_code CHAR(3);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS destination_identifier VARCHAR(180);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS purpose TEXT;
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS sender_email VARCHAR(255);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS sender_phone_number VARCHAR(30);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS receiver_email VARCHAR(255);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS receiver_phone_number VARCHAR(30);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS internal_reference_id VARCHAR(100);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS external_reference_id VARCHAR(100);

-- failure_reason is genuinely absent on successful legs -> nullable.
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS failure_reason TEXT;
ALTER TABLE transactions ALTER COLUMN failure_reason DROP NOT NULL;

-- ------------------------------------------------------------
-- 3. Let go of the old V1 NOT NULL-only columns so entity-driven
--    inserts succeed on a fresh Flyway database. These columns are
--    not part of the canonical model and are left in place (nullable)
--    to avoid destroying data / breaking anything still reading them.
-- ------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transactions' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE transactions ALTER COLUMN user_id DROP NOT NULL;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transactions' AND column_name = 'type_code'
  ) THEN
    ALTER TABLE transactions ALTER COLUMN type_code DROP NOT NULL;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transactions' AND column_name = 'currency_code'
  ) THEN
    ALTER TABLE transactions ALTER COLUMN currency_code DROP NOT NULL;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transactions' AND column_name = 'reference'
  ) THEN
    ALTER TABLE transactions ALTER COLUMN reference DROP NOT NULL;
  END IF;
END $$;

-- ------------------------------------------------------------
-- 4. The entity's findUserHistory query scans a user's own debit
--    (sender_id) and credit (receiver_id) legs newest-first.
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_transactions_sender   ON transactions(sender_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_receiver ON transactions(receiver_id, created_at DESC);