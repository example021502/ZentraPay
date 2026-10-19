\o c:\Users\Desire\Desktop\Zentrapay_Workspace\zentrapay_spring_boot_layer\entcols.out
\pset pager off
SELECT table_name || char(9) || column_name || char(9) || data_type || char(9) || is_nullable
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name IN ('transactions','cards','user_cards','crypto_wallets','bill_payments','fraud_alerts','ledger_entries')
ORDER BY table_name, ordinal_position;
\o
