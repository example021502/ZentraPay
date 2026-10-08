-- dropping the extra unnecessary fields
ALTER TABLE transactions
    DROP COLUMN user_id,
    DROP COLUMN wallet_id,
    DROP COLUMN type_code,
    DROP COLUMN type_code,
    DROP COLUMN currency_code,
    DROP COLUMN gateway,
    DROP COLUMN reference,
    DROP COLUMN gateway_reference,
    DROP COLUMN counterparty_user_id,
    DROP COLUMN counterparty_name,
    DROP COLUMN counterparty_identifier,
    DROP COLUMN description;
