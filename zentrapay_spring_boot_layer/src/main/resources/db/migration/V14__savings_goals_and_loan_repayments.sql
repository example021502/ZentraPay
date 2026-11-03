-- V14: savings goals (the "Save Goal" section) and loan repayments.
--
-- Savings goals: one row per goal the user creates. `saved_amount` is the running balance of money moved
-- from the user's wallet account into the goal; every move is also a row in `transactions`
-- (SAVINGS_DEPOSIT / SAVINGS_WITHDRAWAL) and in the `user_savings` ledger that feeds the ZGrow
-- "Overall Savings" total, so history and reporting see it.
CREATE TABLE IF NOT EXISTS savings_goals (
    goal_id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL,
    goal_name character varying(120) NOT NULL,
    currency_code character varying(3) NOT NULL,
    saved_amount numeric(19,4) DEFAULT 0 NOT NULL,
    target_amount numeric(19,4),
    target_date date,
    description character varying(255),
    status character varying(20) DEFAULT 'ACTIVE' NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT savings_goals_saved_check CHECK (saved_amount >= 0),
    CONSTRAINT savings_goals_target_check CHECK (target_amount IS NULL OR target_amount > 0),
    CONSTRAINT savings_goals_status_check CHECK (status IN ('ACTIVE', 'COMPLETED', 'CLOSED'))
);

CREATE INDEX IF NOT EXISTS idx_savings_goals_user ON savings_goals USING btree (user_id, created_at DESC);

-- Taking money back out of a goal is a negative row in the savings ledger, so the per-currency SUM stays right.
ALTER TABLE user_savings DROP CONSTRAINT IF EXISTS user_savings_amount_check;

-- Loans: remember when the loan was paid off and how much has been repaid so far.
ALTER TABLE loans ADD COLUMN IF NOT EXISTS repaid_amount numeric(19,4) DEFAULT 0 NOT NULL;
ALTER TABLE loans ADD COLUMN IF NOT EXISTS closed_at timestamp with time zone;
