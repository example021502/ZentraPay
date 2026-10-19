\pset pager off
\o 'c:\Users\Desire\Desktop\Zentrapay_Workspace\zentrapay_spring_boot_layer\seedcols.out'
SELECT table_name||'|'||column_name||'|'||data_type||'|'||CASE WHEN is_nullable='NO' THEN 'NOTNULL' ELSE 'null' END||'|'||COALESCE(column_default,'')
FROM information_schema.columns
WHERE table_schema='public'
AND table_name IN ('transactions','cards','user_cards','ledger_entries','bill_payments','crypto_wallets','fraud_alerts','savings_accounts','content_completions','investments','investment_price_snapshots','user_budgets','conversions','voice_commands')
ORDER BY table_name, ordinal_position;

SELECT 'CHECK|'||tc.table_name||'|'||cc.check_clause
FROM information_schema.check_constraints cc
JOIN information_schema.constraint_column_usage ccu USING (constraint_name)
JOIN information_schema.table_constraints tc USING (constraint_name)
WHERE tc.table_schema='public'
AND tc.table_name IN ('transactions','cards','user_cards','crypto_wallets','bill_payments','fraud_alerts','remittances','momo_gateway_mappings','merchant_profiles');

SELECT 'FK|'||tc.table_name||'|'||kcu.column_name||'->'||ccu.table_name||'.'||ccu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name=kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name=ccu.constraint_name
WHERE tc.constraint_type='FOREIGN KEY' AND tc.table_schema='public'
AND tc.table_name IN ('transactions','cards','user_cards','ledger_entries','bill_payments','crypto_wallets','fraud_alerts','savings_accounts','content_completions','investments','investment_price_snapshots','user_budgets','conversions','voice_commands','momo_gateway_mappings','remittances','merchant_profiles','loans','loan_repayments');
\o
