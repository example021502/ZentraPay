\pset pager off
\a
\t
SELECT '===CHECKS===' ;
SELECT tc.table_name||' :: '||cc.check_clause
FROM information_schema.check_constraints cc
JOIN information_schema.table_constraints tc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema='public'
  AND tc.table_name IN ('cards','bill_payments','user_cards','crypto_wallets','savings_accounts','investments','fraud_alerts','voice_commands','transactions','remittances','loans','ledger_entries')
ORDER BY tc.table_name;
SELECT '===FKS===' ;
SELECT tc.table_name||'.'||kcu.column_name||' -> '||ccu.table_name||'.'||ccu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type='FOREIGN KEY' AND tc.table_schema='public'
  AND tc.table_name IN ('bill_payments','user_cards','crypto_wallets','savings_accounts','investments','investment_price_snapshots','user_budgets','conversions','voice_commands','transactions','remittances','loans','loan_repayments','ledger_entries','fraud_alerts','content_completions','points_ledger')
ORDER BY tc.table_name;
SELECT '===REFCOUNTS===' ;
SELECT 'users='||count(*) FROM users;
SELECT 'wallets='||count(*) FROM wallets;
SELECT 'accounts='||count(*) FROM accounts;
SELECT 'bill_providers='||count(*) FROM bill_providers;
SELECT 'financial_literacy_content='||count(*) FROM financial_literacy_content;
