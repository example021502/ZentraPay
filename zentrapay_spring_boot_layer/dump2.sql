\pset pager off
\a
\t
SELECT '===COLUMNS===' ;
SELECT table_name||'|'||column_name||'|'||data_type||'|'||is_nullable||'|'||COALESCE(column_default,'-')
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name IN ('savings_accounts','crypto_wallets','bill_payments','content_completions','investments','investment_price_snapshots','user_budgets','fraud_alerts','conversions','voice_commands','transactions','cards','user_cards','ledger_entries')
ORDER BY table_name, ordinal_position;
