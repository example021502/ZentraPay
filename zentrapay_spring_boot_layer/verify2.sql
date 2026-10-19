\pset pager off
\a
\t
SELECT 'CHK|'||conname||'|'||pg_get_constraintdef(oid) FROM pg_constraint
WHERE conrelid IN ('remittances'::regclass,'ledger_entries'::regclass,'momo_gateway_mappings'::regclass) AND contype='c';

SELECT 'FK|'||conrelid::regclass||'|'||conname||'|'||pg_get_constraintdef(oid) FROM pg_constraint
WHERE conrelid IN ('ledger_entries'::regclass,'remittances'::regclass,'savings_accounts'::regclass,'loan_repayments'::regclass) AND contype='f';

SELECT 'ID|users|'||count(*) FROM users;
SELECT 'ID|wallets|'||count(*) FROM wallets;
SELECT 'ID|accounts|'||count(*) FROM accounts;
SELECT 'ID|billprov|'||count(*) FROM bill_providers;
SELECT 'ID|momoprov|'||count(*) FROM momo_providers;
SELECT 'ID|content|'||count(*) FROM financial_literacy_content;
SELECT 'ID|user1111|'||count(*) FROM users WHERE user_id='11111111-1111-1111-1111-111111111111';
SELECT 'ID|acct_b754|'||count(*) FROM accounts WHERE account_id='b754fee0-ed31-4de2-b4ad-81f6973502aa';
