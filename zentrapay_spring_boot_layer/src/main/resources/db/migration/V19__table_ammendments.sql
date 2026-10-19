-- ADD A COLUMN FOR REWARD ID STORING AND REFERENCING
-- PostgreSQL does not allow an inline `CONSTRAINT ... FOREIGN KEY` clause on
-- ADD COLUMN, so add the (nullable) column and its FK separately. The FK is
-- added guarded + DEFERRABLE-free ON DELETE SET NULL; challenges rows seeded
-- before this point simply have NULL reward_id, which is valid.
ALTER TABLE challenges ADD COLUMN IF NOT EXISTS reward_id INT;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'rewards_ids_fkey') THEN
        ALTER TABLE challenges
            ADD CONSTRAINT rewards_ids_fkey
            FOREIGN KEY (reward_id) REFERENCES rewards(reward_id) ON DELETE SET NULL;
    END IF;
END $$;

-- DROP TRANSACTION TYPE TABLE
-- IF EXISTS + CASCADE keeps this idempotent and safe even if another table
-- ever references it (V1 created it, but nothing depends on it today).
DROP TABLE IF EXISTS transaction_types CASCADE;

-- Always add inline comments for context
-- Migration to optimize transactions table for high throughput

-- 1. Create Enums for static domain constants
CREATE TYPE payment_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'EXPIRED', 'REVERSED');
-- NOTE: labels must exactly match Datatypes.TransactionType (mapped as VARCHAR, NOT this enum,
-- so this type is created only for reuse/consistency and is left unused by the transactions table).
CREATE TYPE transaction_type AS ENUM ('MOMO_TRANSFER', 'BANK_TRANSFER', 'CARD_PAYMENT', 'WALLET_TOPUP', 'INTERNAL');
-- NOTE: enum labels must exactly match Datatypes.PaymentGateway (PAYSTACK, FLUTTERWAV, ONAFRI).
-- The entity actually spells the second label FLUTTERWAV and third ONAFRI, so the enum
-- matches the entity exactly. (transactions.gateway is stored as VARCHAR, not this enum.)
CREATE TYPE payment_gateway AS ENUM ('PAYSTACK', 'FLUTTERWAV', 'ONAFRI');


-- 2. Modify existing transactions table constraints
ALTER TABLE transactions
    ALTER COLUMN external_reference_id DROP NOT NULL,
ALTER COLUMN failure_reason DROP NOT NULL,
    ALTER COLUMN amount TYPE NUMERIC(19, 4),
    ALTER COLUMN internal_reference_id SET NOT NULL;

-- 3. Add composite indexes for high-concurrency lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_txn_internal_ref ON transactions (internal_reference_id);
CREATE INDEX IF NOT EXISTS idx_txn_external_ref ON transactions (external_reference_id);
CREATE INDEX IF NOT EXISTS idx_txn_sender_created ON transactions (sender_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_txn_receiver_created ON transactions (receiver_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_txn_status_created ON transactions (status, created_at) WHERE status = 'PENDING';

-- CREATING THE LEDGER TABLE

-- Always put comments on all responses.
-- Create ENUM for double-entry direction
CREATE TYPE ledger_entry_type AS ENUM ('DEBIT', 'CREDIT');

-- Create immutable double-entry ledger table
CREATE TABLE ledger_entries (
                                ledger_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Links back to the high-level transaction
                                transaction_id UUID NOT NULL REFERENCES transactions(transaction_id) ON DELETE RESTRICT,

    -- Base entryId with directional suffix (e.g., ENT-20261004-99812-DEBIT)
                                entry_id VARCHAR(64) UNIQUE NOT NULL,

    -- Target account being debited or credited
                                account_id UUID NOT NULL,

    -- Financial direction
                                type ledger_entry_type NOT NULL,

    -- Financial values
                                amount NUMERIC(19, 4) NOT NULL,
                                running_balance NUMERIC(19, 4) NOT NULL, -- Account balance snapshot immediately after entry
                                currency_code VARCHAR(3) NOT NULL DEFAULT 'GHS',

    -- Audit trail
                                narration VARCHAR(255) NOT NULL,
                                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance Indexes
-- Fast audit lookup by account ID (for account statement generation)
CREATE INDEX idx_ledger_account_created ON ledger_entries(account_id, created_at DESC);

-- Fast lookup by parent transaction
CREATE INDEX idx_ledger_transaction ON ledger_entries(transaction_id);

-- Prefix query lookup for balanced pair validation
CREATE INDEX idx_ledger_entry_id_prefix ON ledger_entries(entry_id varchar_pattern_ops);