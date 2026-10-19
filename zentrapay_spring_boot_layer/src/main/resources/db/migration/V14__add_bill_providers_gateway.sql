-- MAKING CHANGES TO THE BILL PROVIDERS TABLE
ALTER TABLE bill_providers ADD COLUMN IF NOT EXISTS gateway VARCHAR(30);

-- Backfill before the NOT NULL is enforced, otherwise the SET NOT NULL
-- below fails on pre-existing rows.

ALTER TABLE bill_providers ALTER COLUMN gateway SET DEFAULT NULL;
