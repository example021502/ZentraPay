-- dropping the extra unnecessary fields (legacy V1 columns not on TransactionModel)
-- NOTE: `gateway` is intentionally KEPT — TransactionModel maps it as an enum.
ALTER TABLE transactions
    DROP COLUMN IF EXISTS user_id,
    DROP COLUMN IF EXISTS wallet_id,
    DROP COLUMN IF EXISTS type_code,
    DROP COLUMN IF EXISTS currency_code,
    DROP COLUMN IF EXISTS reference,
    DROP COLUMN IF EXISTS gateway_reference,
    DROP COLUMN IF EXISTS counterparty_user_id,
    DROP COLUMN IF EXISTS counterparty_name,
    DROP COLUMN IF EXISTS counterparty_identifier,
    DROP COLUMN IF EXISTS description;
