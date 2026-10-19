-- ============================================================
-- V34: FIX transactions.status CHECK + SEED 5 RECORDS PER EMPTY TABLE
--
-- Two parts:
--  1. transactions_status_check only allowed the legacy V1 values
--     (PENDING/SUCCESS/FAILED/REVERSED) but TransactionModel writes the
--     Datatypes.TransactionStatus enum values (INITIATED/STK_PUSH_TRIGGERED/
--     PENDING_USER_PIN/SUCCESS/FAILED/EXPIRED). Hibernate validate never
--     checks CHECK constraints, so the backend booted but EVERY real
--     transaction write would fail at runtime. Widen to the union.
--  2. Seed 5 test records into each empty table so the Flutter screens
--     (ZPay history, cards, ZGrow, ZBanking, remittances, ...) render real
--     data on a fresh database. All inserts are guarded (only when the
--     target table is empty) so they never duplicate data.
--
-- Seed reference IDs (from V17/V25/V28 seeds):
--   users  : 1111..0001 ama, 2222..0002 kofi, 3333..0003 zanele,
--            4444..0004 chidi, 5555..0005 wanjiru
--   wallets: 838cd4ea.. (ama), f11af259.. (kofi), a99d8002.. (zanele),
--            ddb30cf0.. (chidi), c4ed5af7.. (wanjiru)
-- ============================================================

-- ------------------------------------------------------------
-- PART 1: WIDEN transactions_status_check TO THE ENTITY ENUM
-- ------------------------------------------------------------
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_status_check;
ALTER TABLE transactions ADD CONSTRAINT transactions_status_check
    CHECK (status IN (
        -- legacy V1 values (kept for backward compatibility)
        'PENDING', 'SUCCESS', 'FAILED', 'REVERSED',
        -- Datatypes.TransactionStatus values written by TransactionModel
        'INITIATED', 'STK_PUSH_TRIGGERED', 'PENDING_USER_PIN', 'EXPIRED'
    ));

-- ------------------------------------------------------------
-- PART 2: SEEDS (dependency order: transactions first, then everything
--         that FK-references it)
-- ------------------------------------------------------------

-- ============================================================
-- 01) TRANSACTIONS (5) â€” fixed UUIDs so dependent tables can reference them
-- ============================================================
INSERT INTO transactions (transaction_id, entry_id, internal_reference_id, external_reference_id,
                          amount, source_currency_code, destination_currency_code,
                          status, transaction_type, gateway,
                          sender_id, sender_name, sender_email, sender_phone_number,
                          receiver_id, receiver_name, receiver_email, receiver_phone_number,
                          destination_identifier, purpose, failure_reason, metadata,
                          created_at, updated_at)
SELECT * FROM (VALUES
    ('a0000000-0000-4000-8000-000000000001'::uuid, 'TXN-0001', 'SEED-TXN-0001', 'PSP-SEED-1001',
     150.00, 'GHS', 'GHS', 'SUCCESS', 'MOMO_TRANSFER', 'PAYSTACK',
     '11111111-1111-1111-1111-111111111111'::uuid, 'Ama Mensah', 'ama.mensah@example.com', '+233241000001',
     '22222222-2222-2222-2222-222222222222'::uuid, 'Kofi Owusu', 'kofi.owusu@example.com', '+233241000002',
     '0241234567', 'Lunch split', NULL, NULL::jsonb, now(), now()),
    ('a0000000-0000-4000-8000-000000000002'::uuid, 'TXN-0002', 'SEED-TXN-0002', 'PSP-SEED-1002',
     275.50, 'GHS', 'GHS', 'SUCCESS', 'BANK_TRANSFER', 'FLUTTERWAV',
     '22222222-2222-2222-2222-222222222222'::uuid, 'Kofi Owusu', 'kofi.owusu@example.com', '+233241000002',
     '33333333-3333-3333-3333-333333333333'::uuid, 'Zanele Dlamini', 'zanele.dlamini@example.com', '+27721000003',
     'GCB-0987654321', 'Rent contribution', NULL, NULL::jsonb, now(), now()),
    ('a0000000-0000-4000-8000-000000000003'::uuid, 'TXN-0003', 'SEED-TXN-0003', NULL,
     80.00, 'GHS', 'GHS', 'FAILED', 'CARD_PAYMENT', 'PAYSTACK',
     '33333333-3333-3333-3333-333333333333'::uuid, 'Zanele Dlamini', 'zanele.dlamini@example.com', '+27721000003',
     '44444444-4444-4444-4444-444444444444'::uuid, 'Chidi Okeke', 'chidi.okeke@example.com', '+234803000004',
     '4444888899990000', 'Online purchase', 'Card declined by issuer', NULL::jsonb, now(), now()),
    ('a0000000-0000-4000-8000-000000000004'::uuid, 'TXN-0004', 'SEED-TXN-0004', NULL,
     500.00, 'GHS', 'GHS', 'INITIATED', 'WALLET_TOPUP', 'PAYSTACK',
     '44444444-4444-4444-4444-444444444444'::uuid, 'Chidi Okeke', 'chidi.okeke@example.com', '+234803000004',
     '55555555-5555-5555-5555-555555555555'::uuid, 'Wanjiru Kamau', 'wanjiru.kamau@example.com', '+254722000005',
     'M-PESA-554433', 'Wallet top-up', NULL, NULL::jsonb, now(), now()),
    ('a0000000-0000-4000-8000-000000000005'::uuid, 'TXN-0005', 'SEED-TXN-0005', 'PSP-SEED-1005',
     42.75, 'GHS', 'GHS', 'EXPIRED', 'MOMO_TRANSFER', 'ONAFRI',
     '55555555-5555-5555-5555-555555555555'::uuid, 'Wanjiru Kamau', 'wanjiru.kamau@example.com', '+254722000005',
     '11111111-1111-1111-1111-111111111111'::uuid, 'Ama Mensah', 'ama.mensah@example.com', '+233241000001',
     '0249876543', 'Airtime purchase', 'STK push expired', NULL::jsonb, now(), now())
) AS v(transaction_id, entry_id, internal_reference_id, external_reference_id,
       amount, source_currency_code, destination_currency_code, status, transaction_type, gateway,
       sender_id, sender_name, sender_email, sender_phone_number,
       receiver_id, receiver_name, receiver_email, receiver_phone_number,
       destination_identifier, purpose, failure_reason, metadata, created_at, updated_at)
WHERE NOT EXISTS (SELECT 1 FROM transactions);

-- ============================================================
-- 02) CARDS (5) â€” card catalog rows user_cards links to
-- ============================================================
INSERT INTO cards (card_id, name, brand, card_type, description, active, created_at, updated_at)
SELECT * FROM (VALUES
    ('c0000000-0000-4000-8000-000000000001'::uuid, 'Virtual Visa', 'VISA', 'VIRTUAL', 'Default virtual card', TRUE, now(), now()),
    ('c0000000-0000-4000-8000-000000000002'::uuid, 'Virtual Mastercard', 'MASTERCARD', 'VIRTUAL', 'Online payments card', TRUE, now(), now()),
    ('c0000000-0000-4000-8000-000000000003'::uuid, 'Physical Visa', 'VISA', 'PHYSICAL', 'NFC tap-to-pay card', TRUE, now(), now()),
    ('c0000000-0000-4000-8000-000000000004'::uuid, 'Virtual Verve', 'VERVE', 'VIRTUAL', 'Local scheme virtual card', TRUE, now(), now()),
    ('c0000000-0000-4000-8000-000000000005'::uuid, 'Physical Mastercard', 'MASTERCARD', 'PHYSICAL', 'Premium metal card', TRUE, now(), now())
) AS v(card_id, name, brand, card_type, description, active, created_at, updated_at)
WHERE NOT EXISTS (SELECT 1 FROM cards);

-- ============================================================
-- 03) USER_CARDS (5) â€” one linked card per user
-- ============================================================
INSERT INTO user_cards (id, user_id, card_id, wallet_id, last4, balance, expiry_month, expiry_year,
                        nfc_enabled, qr_enabled, status, currency_code, provider_id, issued_at, updated_at)
SELECT * FROM (VALUES
    ('d0000000-0000-4000-8000-000000000001'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, 'c0000000-0000-4000-8000-000000000001'::uuid, '838cd4ea-2253-426f-9f9d-a9c991e44ae9'::uuid, '4242', 1250.00, 12, 2028, TRUE, TRUE, 'ACTIVE', 'GHS', NULL::uuid, now(), now()),
    ('d0000000-0000-4000-8000-000000000002'::uuid, '22222222-2222-2222-2222-222222222222'::uuid, 'c0000000-0000-4000-8000-000000000002'::uuid, 'f11af259-c3a0-4723-a86f-33b96da6a2ab'::uuid, '5556', 860.75, 6, 2027, TRUE, FALSE, 'ACTIVE', 'GHS', NULL::uuid, now(), now()),
    ('d0000000-0000-4000-8000-000000000003'::uuid, '33333333-3333-3333-3333-333333333333'::uuid, 'c0000000-0000-4000-8000-000000000003'::uuid, 'a99d8002-3c9c-4558-9b08-d3898e4c9c87'::uuid, '7788', 2400.00, 3, 2029, TRUE, TRUE, 'ACTIVE', 'ZAR', NULL::uuid, now(), now()),
    ('d0000000-0000-4000-8000-000000000004'::uuid, '44444444-4444-4444-4444-444444444444'::uuid, 'c0000000-0000-4000-8000-000000000004'::uuid, 'ddb30cf0-d9e4-43b8-82d3-565b25aebe75'::uuid, '9012', 310.20, 9, 2026, FALSE, TRUE, 'ACTIVE', 'NGN', NULL::uuid, now(), now()),
    ('d0000000-0000-4000-8000-000000000005'::uuid, '55555555-5555-5555-5555-555555555555'::uuid, 'c0000000-0000-4000-8000-000000000005'::uuid, 'c4ed5af7-07c0-4dc1-93dc-4c3b3e3585ac'::uuid, '3456', 5000.00, 1, 2030, TRUE, TRUE, 'ACTIVE', 'KES', NULL::uuid, now(), now())
) AS v(id, user_id, card_id, wallet_id, last4, balance, expiry_month, expiry_year,
       nfc_enabled, qr_enabled, status, currency_code, provider_id, issued_at, updated_at)
WHERE NOT EXISTS (SELECT 1 FROM user_cards);

-- ============================================================
-- 04) BILL_PAYMENTS (5) â€” references seeded transactions + bill_providers
-- ============================================================
INSERT INTO bill_payments (payment_id, user_id, provider_id, transaction_id, customer_reference,
                           amount, currency_code, status, created_at)
SELECT * FROM (VALUES
    ('e0000000-0000-4000-8000-000000000001'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, '67e33c60-7b54-4e89-ae86-5de48ff0f041'::uuid, 'a0000000-0000-4000-8000-000000000001'::uuid, 'ECG-4420118', 120.00, 'GHS', 'SUCCESS', now()),
    ('e0000000-0000-4000-8000-000000000002'::uuid, '22222222-2222-2222-2222-222222222222'::uuid, 'cf1c1913-8cd2-4a7f-8d07-e537792337a7'::uuid, 'a0000000-0000-4000-8000-000000000002'::uuid, 'GWCL-8830127', 85.50, 'GHS', 'SUCCESS', now()),
    ('e0000000-0000-4000-8000-000000000003'::uuid, '33333333-3333-3333-3333-333333333333'::uuid, '5e19d338-ea23-4285-993c-04966cee82a9'::uuid, 'a0000000-0000-4000-8000-000000000003'::uuid, 'DSTV-77120034', 199.00, 'GHS', 'FAILED', now()),
    ('e0000000-0000-4000-8000-000000000004'::uuid, '44444444-4444-4444-4444-444444444444'::uuid, 'f15260d4-e627-42f2-aa8e-8c57c88d5663'::uuid, 'a0000000-0000-4000-8000-000000000004'::uuid, 'EKEDC-5590231', 240.75, 'GHS', 'PENDING', now()),
    ('e0000000-0000-4000-8000-000000000005'::uuid, '55555555-5555-5555-5555-555555555555'::uuid, 'd52f8a1d-510d-449c-ba71-858c3bb0ecd3'::uuid, 'a0000000-0000-4000-8000-000000000005'::uuid, 'GOtv-20199345', 450.00, 'GHS', 'PENDING', now())
) AS v(payment_id, user_id, provider_id, transaction_id, customer_reference, amount, currency_code, status, created_at)
WHERE NOT EXISTS (SELECT 1 FROM bill_payments);

-- ============================================================
-- 05) LEDGER_ENTRIES (5) â€” double-entry legs for the seeded transactions
-- ============================================================
INSERT INTO ledger_entries (ledger_id, transaction_id, entry_id, account_id, type, amount,
                            running_balance, currency_code, narration, created_at)
SELECT * FROM (VALUES
    ('f0000000-0000-4000-8000-000000000001'::uuid, 'a0000000-0000-4000-8000-000000000001'::uuid, 'TXN-0001-DEBIT',  '838cd4ea-2253-426f-9f9d-a9c991e44ae9'::uuid, 'DEBIT',  150.00, 850.00,  'GHS', 'Transfer to Kofi - Outbound', now()),
    ('f0000000-0000-4000-8000-000000000002'::uuid, 'a0000000-0000-4000-8000-000000000001'::uuid, 'TXN-0001-CREDIT', 'f11af259-c3a0-4723-a86f-33b96da6a2ab'::uuid, 'CREDIT', 150.00, 1150.00, 'GHS', 'Transfer from Ama - Inbound', now()),
    ('f0000000-0000-4000-8000-000000000003'::uuid, 'a0000000-0000-4000-8000-000000000002'::uuid, 'TXN-0002-DEBIT',  'f11af259-c3a0-4723-a86f-33b96da6a2ab'::uuid, 'DEBIT',  275.50, 874.50,  'GHS', 'Rent contribution to Zanele', now()),
    ('f0000000-0000-4000-8000-000000000004'::uuid, 'a0000000-0000-4000-8000-000000000002'::uuid, 'TXN-0002-CREDIT', 'a99d8002-3c9c-4558-9b08-d3898e4c9c87'::uuid, 'CREDIT', 275.50, 2675.50, 'GHS', 'Rent contribution from Kofi', now()),
    ('f0000000-0000-4000-8000-000000000005'::uuid, 'a0000000-0000-4000-8000-000000000004'::uuid, 'TXN-0004-DEBIT',  'ddb30cf0-d9e4-43b8-82d3-565b25aebe75'::uuid, 'DEBIT',  500.00, 1810.20, 'GHS', 'Wallet top-up via Paystack', now())
) AS v(ledger_id, transaction_id, entry_id, account_id, type, amount, running_balance, currency_code, narration, created_at)
WHERE NOT EXISTS (SELECT 1 FROM ledger_entries);

-- ============================================================
-- 06) CRYPTO_WALLETS (5) â€” one per user
-- ============================================================
INSERT INTO crypto_wallets (wallet_id, user_id, status, created_at, updated_at)
SELECT gen_random_uuid(), u.user_id, 'ACTIVE', now(), now()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM crypto_wallets);

-- ============================================================
-- 07) MERCHANT_PROFILES (5) â€” category codes come from V2/V23 seeds
-- ============================================================
INSERT INTO merchant_profiles (user_id, business_name, business_registration_number,
                               tax_identification_number, business_category_code,
                               business_country_code, business_address, created_at, updated_at)
SELECT u.user_id, 'Merchant ' || row_number() OVER (), 'REG-' || (100000 + row_number() OVER ())::text,
       'TIN-' || (200000 + row_number() OVER ())::text,
       (ARRAY['UTILITY','AIRTIME','TV_SUBSCRIPTION','INTERNET','OTHERS'])[1 + (row_number() OVER () - 1) % 5],
       LEFT(u.country_code, 2), '12 Independence Ave', now(), now()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM merchant_profiles);

-- ============================================================
-- 08) MOMO_GATEWAY_MAPPINGS (5) â€” one mapping per momo provider
-- ============================================================
INSERT INTO momo_gateway_mappings (id, provider_id, gateway, gateway_code, country_code, created_at, updated_at)
SELECT gen_random_uuid(), mp.provider_id, 'PAYSTACK', mp.global_code, mp.country_code, now(), now()
FROM momo_providers mp
WHERE NOT EXISTS (SELECT 1 FROM momo_gateway_mappings);

-- ============================================================
-- 09) REMITTANCES (5) â€” cross-border corridors between seeded users
-- ============================================================
INSERT INTO remittances (remittance_id, sender_id, receiver_id, transaction_id, amount,
                         source_currency_code, destination_currency_code, exchange_rate, fee,
                         status, channel, recipient_name, recipient_phone_number,
                         recipient_country_code, reference, created_at, updated_at)
SELECT * FROM (VALUES
    ('aa000000-0000-4000-8000-000000000001'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, '33333333-3333-3333-3333-333333333333'::uuid, 'a0000000-0000-4000-8000-000000000001'::uuid, 100.00, 'GHS', 'ZAR', 1.1900000000, 5.00, 'SUCCESS', 'BANK', 'Zanele Dlamini', '+27721000003', 'ZA', 'RMT-SEED-0001', now(), now()),
    ('aa000000-0000-4000-8000-000000000002'::uuid, '22222222-2222-2222-2222-222222222222'::uuid, '44444444-4444-4444-4444-444444444444'::uuid, 'a0000000-0000-4000-8000-000000000002'::uuid, 250.00, 'GHS', 'NGN', 102.0000000000, 8.00, 'SUCCESS', 'MOBILE_MONEY', 'Chidi Okeke', '+234803000004', 'NG', 'RMT-SEED-0002', now(), now()),
    ('aa000000-0000-4000-8000-000000000003'::uuid, '33333333-3333-3333-3333-333333333333'::uuid, '55555555-5555-5555-5555-555555555555'::uuid, 'a0000000-0000-4000-8000-000000000003'::uuid, 60.00, 'ZAR', 'KES', 8.3000000000, 3.50, 'FAILED', 'BANK', 'Wanjiru Kamau', '+254722000005', 'KE', 'RMT-SEED-0003', now(), now()),
    ('aa000000-0000-4000-8000-000000000004'::uuid, '44444444-4444-4444-4444-444444444444'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, 'a0000000-0000-4000-8000-000000000004'::uuid, 50000.00, 'NGN', 'GHS', 0.0150000000, 12.00, 'PENDING', 'MOBILE_MONEY', 'Ama Mensah', '+233241000001', 'GH', 'RMT-SEED-0004', now(), now()),
    ('aa000000-0000-4000-8000-000000000005'::uuid, '55555555-5555-5555-5555-555555555555'::uuid, '22222222-2222-2222-2222-222222222222'::uuid, 'a0000000-0000-4000-8000-000000000005'::uuid, 1500.00, 'KES', 'GHS', 0.0500000000, 6.00, 'PENDING', 'BANK', 'Kofi Owusu', '+233241000002', 'GH', 'RMT-SEED-0005', now(), now())
) AS v(remittance_id, sender_id, receiver_id, transaction_id, amount, source_currency_code,
       destination_currency_code, exchange_rate, fee, status, channel, recipient_name,
       recipient_phone_number, recipient_country_code, reference, created_at, updated_at)
WHERE NOT EXISTS (SELECT 1 FROM remittances);

-- ============================================================
-- 10) FRAUD_ALERTS (5) â€” one per user + one extra
-- ============================================================
INSERT INTO fraud_alerts (alert_id, user_id, alert_type, message, severity, is_resolved,
                          related_transaction_id, created_at)
SELECT * FROM (VALUES
    ('ab000000-0000-4000-8000-000000000001'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, 'UNUSUAL_LOGIN', 'Login from a new device in Lagos.', 'MEDIUM', FALSE, NULL, now()),
    ('ab000000-0000-4000-8000-000000000002'::uuid, '22222222-2222-2222-2222-222222222222'::uuid, 'RAPID_TRANSFERS', 'Five transfers within 3 minutes.', 'HIGH', FALSE, 'a0000000-0000-4000-8000-000000000002'::uuid, now()),
    ('ab000000-0000-4000-8000-000000000003'::uuid, '33333333-3333-3333-3333-333333333333'::uuid, 'FAILED_PIN_ATTEMPTS', 'Three consecutive wrong PIN attempts.', 'CRITICAL', FALSE, 'a0000000-0000-4000-8000-000000000003'::uuid, now()),
    ('ab000000-0000-4000-8000-000000000004'::uuid, '44444444-4444-4444-4444-444444444444'::uuid, 'NEW_BENEFICIARY', 'First payment to a new beneficiary.', 'LOW', TRUE, NULL, now()),
    ('ab000000-0000-4000-8000-000000000005'::uuid, '55555555-5555-5555-5555-555555555555'::uuid, 'GEO_VELOCITY', 'Impossible travel: Accra then Nairobi in 20 min.', 'HIGH', FALSE, 'a0000000-0000-4000-8000-000000000005'::uuid, now())
) AS v(alert_id, user_id, alert_type, message, severity, is_resolved, related_transaction_id, created_at)
WHERE NOT EXISTS (SELECT 1 FROM fraud_alerts);

-- ============================================================
-- 11) SAVINGS_ACCOUNTS (5) â€” one goal account per user
-- ============================================================
INSERT INTO savings_accounts (savings_id, user_id, wallet_id, savings_name, currency_code,
                              balance, description, target_date, target_amount, status, created_at, updated_at)
SELECT gen_random_uuid(), u.user_id, w.wallet_id,
       'Goal ' || row_number() OVER (), 'GHS',
       100.00 * row_number() OVER (), 'Seeded savings goal',
       (CURRENT_DATE + 90)::date, 1000.00 * row_number() OVER (), 'ACTIVE', now(), now()
FROM users u
JOIN wallets w ON w.wallet_id = (SELECT wallet_id FROM wallets w2 WHERE w2.user_id = u.user_id LIMIT 1)
WHERE NOT EXISTS (SELECT 1 FROM savings_accounts);

-- ============================================================
-- 12) LOANS (5) â€” fixed UUIDs so loan_repayments can FK them
-- ============================================================
INSERT INTO loans (loan_id, user_id, currency_code, principal_amount, interest_rate, term_months,
                   outstanding_balance, status, disbursement_transaction_id, applied_at,
                   approved_at, due_date, created_at, updated_at)
SELECT * FROM (VALUES
    ('b0000000-0000-4000-8000-000000000001'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, 'GHS', 1000.00, 0.12, 6, 600.00, 'ACTIVE', 'a0000000-0000-4000-8000-000000000001'::uuid, now(), now(), (CURRENT_DATE + 120)::date, now(), now()),
    ('b0000000-0000-4000-8000-000000000002'::uuid, '22222222-2222-2222-2222-222222222222'::uuid, 'GHS', 2500.00, 0.15, 12, 2500.00, 'APPROVED', NULL, now(), now(), NULL, now(), now()),
    ('b0000000-0000-4000-8000-000000000003'::uuid, '33333333-3333-3333-3333-333333333333'::uuid, 'ZAR', 5000.00, 0.10, 24, 3200.00, 'ACTIVE', 'a0000000-0000-4000-8000-000000000002'::uuid, now(), now(), (CURRENT_DATE + 300)::date, now(), now()),
    ('b0000000-0000-4000-8000-000000000004'::uuid, '44444444-4444-4444-4444-444444444444'::uuid, 'NGN', 150000.00, 0.18, 9, 150000.00, 'PENDING', NULL, now(), NULL, NULL, now(), now()),
    ('b0000000-0000-4000-8000-000000000005'::uuid, '55555555-5555-5555-5555-555555555555'::uuid, 'KES', 8000.00, 0.14, 12, 0.00, 'CLOSED', 'a0000000-0000-4000-8000-000000000005'::uuid, now(), now(), (CURRENT_DATE - 30)::date, now(), now())
) AS v(loan_id, user_id, currency_code, principal_amount, interest_rate, term_months,
       outstanding_balance, status, disbursement_transaction_id, applied_at, approved_at, due_date, created_at, updated_at)
WHERE NOT EXISTS (SELECT 1 FROM loans);

-- ============================================================
-- 13) LOAN_REPAYMENTS (5) â€” repayment legs against seeded loans
-- ============================================================
INSERT INTO loan_repayments (repayment_id, loan_id, transaction_id, amount, paid_at)
SELECT * FROM (VALUES
    ('b1000000-0000-4000-8000-000000000001'::uuid, 'b0000000-0000-4000-8000-000000000001'::uuid, 'a0000000-0000-4000-8000-000000000001'::uuid, 200.00, now()),
    ('b1000000-0000-4000-8000-000000000002'::uuid, 'b0000000-0000-4000-8000-000000000001'::uuid, 'a0000000-0000-4000-8000-000000000002'::uuid, 200.00, now()),
    ('b1000000-0000-4000-8000-000000000003'::uuid, 'b0000000-0000-4000-8000-000000000003'::uuid, 'a0000000-0000-4000-8000-000000000003'::uuid, 900.00, now()),
    ('b1000000-0000-4000-8000-000000000004'::uuid, 'b0000000-0000-4000-8000-000000000005'::uuid, 'a0000000-0000-4000-8000-000000000004'::uuid, 8000.00, now()),
    ('b1000000-0000-4000-8000-000000000005'::uuid, 'b0000000-0000-4000-8000-000000000005'::uuid, 'a0000000-0000-4000-8000-000000000005'::uuid, 500.00, now())
) AS v(repayment_id, loan_id, transaction_id, amount, paid_at)
WHERE NOT EXISTS (SELECT 1 FROM loan_repayments);

-- ============================================================
-- 14) CONTENT_COMPLETIONS (5) â€” one literacy article completed per user
-- ============================================================
INSERT INTO content_completions (completion_id, content_id, user_id, completed_at, points_earned)
SELECT gen_random_uuid(), flc.content_id, u.user_id, now(), flc.points_reward
FROM (SELECT user_id, row_number() OVER (ORDER BY user_id) AS rn FROM users) u
JOIN (SELECT content_id, points_reward, row_number() OVER (ORDER BY content_id) AS rn
      FROM financial_literacy_content) flc
  ON flc.rn = ((u.rn - 1) % 5) + 1
WHERE NOT EXISTS (SELECT 1 FROM content_completions);

-- ============================================================
-- 15) POINTS_LEDGER (5) â€” one points entry per user
-- ============================================================
INSERT INTO points_ledger (ledger_id, user_id, points, reason, reference_type, reference_id, created_at)
SELECT gen_random_uuid(), u.user_id, 50 * row_number() OVER (), 'CHALLENGE_COMPLETED',
       'CHALLENGE', NULL, now()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM points_ledger);

-- ============================================================
-- 16) INVESTMENTS (5) â€” fixed UUIDs so price snapshots can FK them
-- ============================================================
INSERT INTO investments (investment_id, user_id, name, investment_type, symbol, quantity,
                         buy_price, currency_code, status, created_at, updated_at)
SELECT * FROM (VALUES
    ('c1000000-0000-4000-8000-000000000001'::uuid, '11111111-1111-1111-1111-111111111111'::uuid, 'MTN Growth Fund', 'STOCK', 'MTN', 10.0, 4.50, 'USD', 'ACTIVE', now(), now()),
    ('c1000000-0000-4000-8000-000000000002'::uuid, '22222222-2222-2222-2222-222222222222'::uuid, 'Africa ETF', 'ETF', 'AFR', 25.0, 32.10, 'USD', 'ACTIVE', now(), now()),
    ('c1000000-0000-4000-8000-000000000003'::uuid, '33333333-3333-3333-3333-333333333333'::uuid, 'Gold Bullion', 'COMMODITY', 'XAU', 2.0, 2050.00, 'USD', 'ACTIVE', now(), now()),
    ('c1000000-0000-4000-8000-000000000004'::uuid, '44444444-4444-4444-4444-444444444444'::uuid, 'Bitcoin Vault', 'CRYPTO', 'BTC', 0.05, 61000.00, 'USD', 'ACTIVE', now(), now()),
    ('c1000000-0000-4000-8000-000000000005'::uuid, '55555555-5555-5555-5555-555555555555'::uuid, 'Treasury Bond', 'OTHER', 'TBOND', 5.0, 1000.00, 'USD', 'CLOSED', now(), now())
) AS v(investment_id, user_id, name, investment_type, symbol, quantity, buy_price, currency_code, status, created_at, updated_at)
WHERE NOT EXISTS (SELECT 1 FROM investments);

-- ============================================================
-- 17) INVESTMENT_PRICE_SNAPSHOTS (5) â€” one snapshot per investment
-- ============================================================
INSERT INTO investment_price_snapshots (snapshot_id, investment_id, price, recorded_at)
SELECT gen_random_uuid(), i.investment_id, i.buy_price * 1.05, now()
FROM investments i
WHERE NOT EXISTS (SELECT 1 FROM investment_price_snapshots);

-- ============================================================
-- 18) USER_BUDGETS (5) â€” one monthly budget per user
-- ============================================================
INSERT INTO user_budgets (user_id, monthly_limit, currency_code, created_at, updated_at)
SELECT u.user_id, 2000.00 * row_number() OVER (), 'GHS', now(), now()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM user_budgets);

-- ============================================================
-- 19) CONVERSIONS (5) â€” one conversion-history row per user
-- ============================================================
INSERT INTO conversions (conversion_id, user_id, from_currency_code, to_currency_code,
                         amount, converted_amount, rate, created_at)
SELECT gen_random_uuid(), u.user_id, 'GHS', 'USD',
       100.00 * row_number() OVER (), (100.00 * row_number() OVER ()) / 15.2, 0.0657894737, now()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM conversions);

-- ============================================================
-- 20) VOICE_COMMANDS (5) â€” one seeded ZVoice command per user
-- ============================================================
INSERT INTO voice_commands (command_id, user_id, command_type, language, transcript,
                            response_text, status, fraud_alert, fraud_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.user_id,
       (ARRAY['VOICE','CHAT'])[1 + (row_number() OVER () - 1) % 2], 'en',
       'Send 50 cedis to Kofi', 'Transfer prepared for confirmation.', 'PROCESSED', FALSE, NULL, now(), now()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM voice_commands);





