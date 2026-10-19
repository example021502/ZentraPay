\pset pager off
\a
\t
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name IN ('merchant_profiles','momo_gateway_mappings','momo_providers','points_ledger','remittances','loans','loan_repayments')
ORDER BY table_name, ordinal_position;