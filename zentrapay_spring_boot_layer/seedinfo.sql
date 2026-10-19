\pset pager off
\echo ===COLS===
SELECT table_name||'.'||column_name||CASE WHEN is_nullable='NO' THEN ' NOTNULL' ELSE '' END
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name IN ('transactions','cards','user_cards','crypto_wallets','merchant_profiles','momo_gateway_mappings','remittances','fraud_alerts','bill_payments','ledger_entries','savings_accounts','loans','loan_repayments','content_completions','points_ledger','investments','investment_price_snapshots','user_budgets','conversions','voice_commands')
ORDER BY table_name, ordinal_position;
\echo ===CHECKS===
SELECT rel.relname AS tbl, con.conname, pg_get_constraintdef(con.oid)
FROM pg_constraint con JOIN pg_class rel ON rel.oid=con.conrelid
WHERE con.contype='c' AND rel.relname IN ('transactions','cards','user_cards','crypto_wallets','remittances','bill_payments','fraud_alerts','loans','savings_accounts','investments','voice_commands','momo_gateway_mappings')
ORDER BY rel.relname;
\echo ===FKS===
SELECT con.conrelid::regclass AS tbl, con.conname, pg_get_constraintdef(con.oid)
FROM pg_constraint con
WHERE con.contype='f' AND con.conrelid::regclass::text IN ('transactions','cards','user_cards','crypto_wallets','merchant_profiles','momo_gateway_mappings','remittances','fraud_alerts','bill_payments','ledger_entries','savings_accounts','loans','loan_repayments','content_completions','points_ledger','investments','investment_price_snapshots','user_budgets','conversions','voice_commands')
ORDER BY tbl;
\echo ===SEEDIDS===
SELECT 'users', user_id::text FROM users ORDER BY created_at LIMIT 5;
SELECT 'wallets', wallet_id::text FROM wallets ORDER BY created_at LIMIT 5;
SELECT 'accounts', account_id::text FROM accounts ORDER BY created_at LIMIT 5;
SELECT 'bill_providers', provider_id::text FROM bill_providers ORDER BY created_at LIMIT 5;
SELECT 'momo_providers', provider_id::text FROM momo_providers ORDER BY created_at LIMIT 5;
SELECT 'service_providers', provider_id::text FROM service_providers ORDER BY created_at LIMIT 5;
SELECT 'challenges', id::text FROM challenges ORDER BY created_at LIMIT 5;
SELECT 'content', id::text FROM financial_literacy_content ORDER BY created_at LIMIT 5;
\echo ===CURRS===
SELECT currency_code FROM currencies ORDER BY currency_code;
\echo ===DONE===
