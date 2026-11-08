-- V17: savings goal controls - freeze (pause saving for up to 7 days) and auto-save (a fixed amount
-- moved from the wallet into the goal every day / week / month).
--
-- frozen_until   : while this is in the future no money can be saved into the goal (manual or automatic).
--                  It simply runs out - there is no job that has to "unfreeze" anything.
-- auto_*         : the recurring save. `auto_next_run` is when the next automatic save is due; a background
--                  job claims a due run by moving it forward BEFORE it saves, so a run can never happen twice.
ALTER TABLE savings_goals ADD COLUMN IF NOT EXISTS frozen_until timestamp without time zone;
ALTER TABLE savings_goals ADD COLUMN IF NOT EXISTS auto_enabled boolean DEFAULT false NOT NULL;
ALTER TABLE savings_goals ADD COLUMN IF NOT EXISTS auto_amount numeric(19,4);
ALTER TABLE savings_goals ADD COLUMN IF NOT EXISTS auto_frequency character varying(10);
ALTER TABLE savings_goals ADD COLUMN IF NOT EXISTS auto_next_run timestamp without time zone;

ALTER TABLE savings_goals DROP CONSTRAINT IF EXISTS savings_goals_auto_check;
ALTER TABLE savings_goals ADD CONSTRAINT savings_goals_auto_check CHECK (
    auto_enabled = false
    OR (auto_amount IS NOT NULL AND auto_amount > 0
        AND auto_frequency IN ('DAILY', 'WEEKLY', 'MONTHLY')
        AND auto_next_run IS NOT NULL)
);

-- The job looks only at goals with auto-save on, soonest first
CREATE INDEX IF NOT EXISTS idx_savings_goals_auto_due ON savings_goals USING btree (auto_next_run) WHERE auto_enabled;

-- The "recent saving activity" list reads a user's SAVINGS_* transactions, newest first
CREATE INDEX IF NOT EXISTS idx_transactions_savings_activity ON transactions USING btree (created_at DESC)
    WHERE transaction_type IN ('SAVINGS_DEPOSIT', 'SAVINGS_WITHDRAWAL');
