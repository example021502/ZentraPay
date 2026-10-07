-- ADD A COLUMN FOR REWARD ID STORING AND REFRENCING
ALTER TABLE challenges ADD COLUMN reward_id INT CONSTRAINT rewards_ids_fkey FOREIGN KEY (reward_id) REFERENCES rewards(reward_id) ON DELETE SET NULL;

-- DROP TRANSACTION TYPE TABLE
DROP TABLE transaction_types

-- Always add inline comments for context
-- Migration to optimize transactions table for high throughput

-- 1. Create Enums for static domain constants
CREATE TYPE payment_status AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'EXPIRED', 'REVERSED');
CREATE TYPE transaction_type AS ENUM ('MOMO_TRANSFER', 'BANK_TRANSFER', 'CARD_PAYMENT', 'WALLET_TOPUP', 'INTERNAL');
CREATE TYPE payment_gateway AS ENUM ('PAYSTACK', 'FLUTTERWAVE', 'ONAFRIQ');


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