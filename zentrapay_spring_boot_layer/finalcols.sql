\pset pager off
\a
\t
SELECT 'COL|'||table_name||'|'||column_name||'|'||data_type||'|'||is_nullable||'|'||coalesce(column_default,'')
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name IN ('transactions','cards','user_cards','bill_payments','crypto_wallets','fraud_alerts','ledger_entries','savings_accounts','content_completions','investments','investment_price_snapshots','user_budgets','conversions','voice_commands','remittances')
ORDER BY table_name, ordinal_position;
