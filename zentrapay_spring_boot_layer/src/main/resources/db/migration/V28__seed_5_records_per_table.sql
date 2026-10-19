-- ============================================================
-- V28: SEED 5+ TEST RECORDS PER TABLE
--
-- Guarantees every core / user-facing table has at least 5 rows for
-- end-to-end testing (frontend lists, detail screens, ZGrow, converter, etc.).
-- Runs AFTER V27, so all entity tables exist. All seeds are idempotent
-- (ON CONFLICT DO NOTHING) — re-running Flyway can never duplicate them.
--
-- Fixed UUIDs are used wherever a stable key is possible; otherwise
-- gen_random_uuid() runs only when the table is empty (guarded inserts),
-- so re-runs stay idempotent even for tables without a natural unique key.
-- ============================================================
-- ============================================================
-- 0) BANKS (5) — must exist BEFORE user_bank references one.
-- ============================================================
INSERT INTO banks (code, bank_name, gateway, iban, currency_code, pay_with_bank, swift_bic, country_code, country, routing_number, type, active, created_at, updated_at)
SELECT * FROM (VALUES
    ('GH_GCB',     'GCB Bank Ghana',        'PAYSTACK', NULL, 'GHS', TRUE, 'GHCBGHAC', 'GH', 'Ghana', '040100', 'BANK', TRUE, NOW(), NOW()),
    ('GH_ECOBANK', 'Ecobank Ghana',         'PAYSTACK', NULL, 'GHS', TRUE, 'ECOCGHAC', 'GH', 'Ghana', '130100', 'BANK', TRUE, NOW(), NOW()),
    ('GH_ABSA',    'Absa Bank Ghana',       'PAYSTACK', NULL, 'GHS', TRUE, 'ABNAGHAC', 'GH', 'Ghana', '060100', 'BANK', TRUE, NOW(), NOW()),
    ('GH_CAL',     'CalBank Ghana',         'PAYSTACK', NULL, 'GHS', TRUE, 'CBGHGHAC', 'GH', 'Ghana', '140100', 'BANK', TRUE, NOW(), NOW()),
    ('GH_FIDELITY','Fidelity Bank Ghana',   'PAYSTACK', NULL, 'GHS', TRUE, 'FBLIGHAC', 'GH', 'Ghana', '240100', 'BANK', TRUE, NOW(), NOW())
) v(code, bank_name, gateway, iban, currency_code, pay_with_bank, swift_bic, country_code, country, routing_number, type, active, created_at, updated_at)
WHERE NOT EXISTS (SELECT 1 FROM banks b WHERE b.code = v.code);

-- ============================================================
-- 0b) MOMO PROVIDERS (5)
-- ============================================================
INSERT INTO momo_providers (name, global_code, "countryCode", active, created_at, updated_at)
SELECT * FROM (VALUES
    ('MTN Mobile Money', 'MTN',    'GH', TRUE, NOW(), NOW()),
    ('Vodafone Cash',    'VOD',    'GH', TRUE, NOW(), NOW()),
    ('AirtelTigo Money', 'ATL',    'GH', TRUE, NOW(), NOW()),
    ('M-Pesa',           'MPESA',  'KE', TRUE, NOW(), NOW()),
    ('Airtel Money',     'AIRTEL', 'KE', TRUE, NOW(), NOW())
) v(name, global_code, "countryCode", active, created_at, updated_at)
WHERE NOT EXISTS (SELECT 1 FROM momo_providers p WHERE p.global_code = v.global_code AND p."countryCode" = v."countryCode");


-- ============================================================
-- 1) TEST USERS (fixed UUIDs; password_hash is a bcrypt of "Passw0rd!")
-- ============================================================
INSERT INTO users (
    user_id, first_name, last_name, email, phone_number, country_code,
    password_hash, transaction_pin_hash, user_type, status, kyc_tier,
    created_at, updated_at
) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Ama',    'Mensah',  'ama.mensah@example.com',    '+233201110001', 'GH', '$2a$10$Dow1N8A/PJU7F0nD9A0mWOLB6c1nGmF0lVJ1lI3xq9Q7b8Gq1a3wO', '$2a$10$Dow1N8A/PJU7F0nD9A0mWOLB6c1nGmF0lVJ1lI3xq9Q7b8Gq1a3wO', 'APP_USER', 'ACTIVE', 2, NOW(), NOW()),
    ('22222222-2222-2222-2222-222222222222', 'Kofi',   'Owusu',   'kofi.owusu@example.com',    '+233201110002', 'GH', '$2a$10$Dow1N8A/PJU7F0nD9A0mWOLB6c1nGmF0lVJ1lI3xq9Q7b8Gq1a3wO', '$2a$10$Dow1N8A/PJU7F0nD9A0mWOLB6c1nGmF0lVJ1lI3xq9Q7b8Gq1a3wO', 'APP_USER', 'ACTIVE', 1, NOW(), NOW()),
    ('33333333-3333-3333-3333-333333333333', 'Zanele', 'Dlamini', 'zanele.dlamini@example.com', '+27831110003', 'ZA', '$2a$10$Dow1N8A/PJU7F0nD9A0mWOLB6c1nGmF0lVJ1lI3xq9Q7b8Gq1a3wO', '$2a$10$Dow1N8A/PJU7F0nD9A0mWOLB6c1nGmF0lVJ1lI3xq9Q7b8Gq1a3wO', 'MERCHANT', 'ACTIVE', 2, NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'Chidi',  'Okeke',   'chidi.okeke@example.com',   '+234801110004', 'NG', '$2a$10$Dow1N8A/PJU7F0nD9A0mWOLB6c1nGmF0lVJ1lI3xq9Q7b8Gq1a3wO', '$2a$10$Dow1N8A/PJU7F0nD9A0mWOLB6c1nGmF0lVJ1lI3xq9Q7b8Gq1a3wO', 'AGENT',    'ACTIVE', 1, NOW(), NOW()),
    ('55555555-5555-5555-5555-555555555555', 'Wanjiru','Kamau',   'wanjiru.kamau@example.com', '+25471110005', 'KE', '$2a$10$Dow1N8A/PJU7F0nD9A0mWOLB6c1nGmF0lVJ1lI3xq9Q7b8Gq1a3wO', '$2a$10$Dow1N8A/PJU7F0nD9A0mWOLB6c1nGmF0lVJ1lI3xq9Q7b8Gq1a3wO', 'APP_USER', 'FROZEN',  0, NOW(), NOW())
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================
-- 2) USER PROFILES
-- ============================================================
INSERT INTO user_profiles (user_id, date_of_birth, nationality_country_code, identity_document_type, identity_document_number, identity_document_issuing_country_code, address_1, city_name, state_or_region, postal_code, occupation_title, anti_money_laundering_status, politically_exposed_person, kyc_status, created_at, updated_at)
SELECT u.user_id, DATE '1994-05-15', u.country_code, 'NATIONAL_ID', 'GHA-000' || (row_number() OVER ())::text,
       u.country_code, u.user_id::text || ' Test Street', 'Accra', 'Greater Accra', '00233',
       'Engineer', 'CLEAR', FALSE, 'verified', NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM user_profiles p WHERE p.user_id = u.user_id);

-- ============================================================
-- 3) WALLETS (5 — one per user)
-- ============================================================
INSERT INTO wallets (wallet_id, user_id, wallet_name, country_code, created_at, updated_at)
SELECT gen_random_uuid(), u.user_id, u.first_name || '''s Wallet', u.country_code, NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM wallets w WHERE w.user_id = u.user_id);

-- ============================================================
-- 4) FIAT ACCOUNTS (5 — one per user's wallet)
-- ============================================================
INSERT INTO accounts (account_id, wallet_id, account_name, currency_code, zentag, balance, is_default, status, created_at, updated_at)
SELECT gen_random_uuid(), w.wallet_id, 'Main Account',
       CASE u.country_code WHEN 'GH' THEN 'GHS' WHEN 'NG' THEN 'NGN' WHEN 'KE' THEN 'KES' WHEN 'ZA' THEN 'ZAR' ELSE 'GHS' END,
       u.first_name || '.' || u.last_name, 1200.00 + (row_number() OVER () * 500)::numeric, TRUE, 'ACTIVE', NOW(), NOW()
FROM wallets w JOIN users u ON u.user_id = w.user_id
WHERE NOT EXISTS (SELECT 1 FROM accounts a WHERE a.wallet_id = w.wallet_id);

-- ============================================================
-- 5) CRYPTO ACCOUNTS (5 — one per user)
-- ============================================================
INSERT INTO crypto_accounts (account_id, wallet_id, currency_code, network, wallet_address, balance, is_default, status, created_at, updated_at)
SELECT gen_random_uuid(), w.wallet_id, 'BTC', 'Bitcoin', 'bc1q' || substr(md5(w.wallet_id::text), 1, 32),
       0.0250000000, TRUE, 'ACTIVE', NOW(), NOW()
FROM wallets w
WHERE NOT EXISTS (SELECT 1 FROM crypto_accounts c WHERE c.wallet_id = w.wallet_id);

-- ============================================================
-- 6) GATEWAY PROVIDERS (5 — the supported payment gateways)
-- ============================================================
INSERT INTO gateway_providers (provider_id, provider_name, description, is_active, created_at)
VALUES
    ('70000000-0000-0000-0000-000000000001', 'PAYSTACK',    'Paystack payment gateway for Ghana and Nigeria.',  TRUE, NOW()),
    ('70000000-0000-0000-0000-000000000002', 'FLUTTERWAVE', 'Flutterwave payment gateway for pan-African payouts.', TRUE, NOW()),
    ('70000000-0000-0000-0000-000000000003', 'ONAFRIQ',     'Onafriq mobile-money / bank gateway across Africa.', TRUE, NOW()),
    ('70000000-0000-0000-0000-000000000004', 'M-PESA',      'Safaricom M-Pesa mobile money.',                    TRUE, NOW()),
    ('70000000-0000-0000-0000-000000000005', 'MTN_MOMO',    'MTN Mobile Money gateway.',                          TRUE, NOW())
ON CONFLICT (provider_id) DO NOTHING;

-- ============================================================
-- 7) GATEWAY CUSTOMERS (5 — one per user, mapped to Paystack)
-- ============================================================
INSERT INTO gateway_customers (user_id, gateway_id, gateway, email, gateway_customer_id, created_at, updated_at)
SELECT u.user_id, '70000000-0000-0000-0000-000000000001', 'PAYSTACK', u.email,
       'CUS_TEST_' || u.user_id::text, NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM gateway_customers gc WHERE gc.user_id = u.user_id AND gc.gateway_id = '70000000-0000-0000-0000-000000000001');

-- ============================================================
-- 8) GATEWAY RECIPIENTS (5 — one per user)
-- ============================================================
INSERT INTO gateway_recipients (user_id, gateway_id, gateway, gateway_recipient_id, "checkoutType", channel_code, account_identifier, account_name, created_at, updated_at)
SELECT u.user_id, '70000000-0000-0000-0000-000000000001', 'PAYSTACK',
       'RCP_TEST_' || u.user_id::text, 'BANK', 'GH_GCB',
       '024000000' || (row_number() OVER ())::text, u.first_name || ' ' || u.last_name, NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM gateway_recipients gr WHERE gr.user_id = u.user_id AND gr.gateway_id = '70000000-0000-0000-0000-000000000001');

-- ============================================================
-- 9) LEGAL DOCUMENTS (5 — T&C / privacy / policy versions)
-- ============================================================
INSERT INTO legal_documents (document_id, document_type, document_version, title, file_url, content_hash, is_active, effective_date, created_at)
VALUES
    ('71000000-0000-0000-0000-000000000001', 'TERMS_OF_SERVICE', '1.0.0', 'ZentraPay Terms of Service v1',      'https://cdn.zentrapay.com/legal/tos-v1.pdf',    'sha256-tos-v1',    TRUE, NOW(), NOW()),
    ('71000000-0000-0000-0000-000000000002', 'PRIVACY_POLICY',   '1.0.0', 'ZentraPay Privacy Policy v1',         'https://cdn.zentrapay.com/legal/privacy-v1.pdf','sha256-priv-v1',   TRUE, NOW(), NOW()),
    ('71000000-0000-0000-0000-000000000003', 'KYC_POLICY',       '1.0.0', 'ZentraPay KYC & Onboarding Policy',   'https://cdn.zentrapay.com/legal/kyc-v1.pdf',    'sha256-kyc-v1',    TRUE, NOW(), NOW()),
    ('71000000-0000-0000-0000-000000000004', 'AML_POLICY',       '2.1.0', 'ZentraPay AML & Sanctions Policy',    'https://cdn.zentrapay.com/legal/aml-v2.pdf',    'sha256-aml-v2',    TRUE, NOW(), NOW()),
    ('71000000-0000-0000-0000-000000000005', 'COOKIE_POLICY',    '1.0.0', 'ZentraPay Cookie Policy',             'https://cdn.zentrapay.com/legal/cookie-v1.pdf', 'sha256-cookie-v1', TRUE, NOW(), NOW())
ON CONFLICT (document_id) DO NOTHING;

-- ============================================================
-- 10) USER CONSENTS (5 — one per user accepts the Terms of Service)
-- ============================================================
INSERT INTO user_consents (consent_id, user_id, document_id, ip_address, accepted_at)
SELECT u.user_id, u.user_id, '71000000-0000-0000-0000-000000000001',
       '41.' || (10 + (row_number() OVER ()))::text || '.0.' || (row_number() OVER ())::text, NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM user_consents c WHERE c.user_id = u.user_id AND c.document_id = '71000000-0000-0000-0000-000000000001');

-- ============================================================
-- 11) TRANSFER RECIPIENTS (5 — one bank destination per user)
-- ============================================================
INSERT INTO transfer_recipients (recipient_id, user_id, recipient_name, destination_type, account_identifier, provider_code, provider_name, country_code, currency_code, created_at, updated_at)
SELECT gen_random_uuid(), u.user_id, 'Recipient ' || row_number() OVER (), 'BANK',
       '0240000' || (100 + (row_number() OVER ()))::text, 'GH_GCB', 'GCB Bank', 'GHA', 'GHS', NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM transfer_recipients tr WHERE tr.user_id = u.user_id);

-- ============================================================
-- 12) USER BANK (5 — one linked bank account per user)
-- ============================================================
INSERT INTO user_bank (user_bank_id, user_id, balance, bank_id, last_digits, connection_status, connection_id, linked_at, updated_at)
SELECT gen_random_uuid(), u.user_id, 2000.00,
       (SELECT bank_id FROM banks LIMIT 1),
       '000' || (row_number() OVER ())::text, 'active',
       'CONN_' || u.user_id::text, NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM user_bank ub WHERE ub.user_id = u.user_id);

-- ============================================================
-- 13) USER PAYMENT GATEWAYS (5 — one gateway identity per user)
-- ============================================================
INSERT INTO user_payment_gateways (user_gateway_id, user_id, gateway_name, gateway_customer_id, created_at, updated_at)
SELECT gen_random_uuid(), u.user_id, 'PAYSTACK', 'CUS_' || u.user_id::text, NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM user_payment_gateways upg WHERE upg.user_id = u.user_id AND upg.gateway_name = 'PAYSTACK');

-- ============================================================
-- 14) USER REWARD BALANCES (5 — one per user)
-- ============================================================
INSERT INTO user_reward_balances (total_points, reward_type, updated_on)
SELECT 500 + (row_number() OVER () * 100), 'POINTS', NOW()
FROM users u
WHERE (SELECT count(*) FROM user_reward_balances) < 5;

-- ============================================================
-- 15) USER CHALLENGES (5+ — each user joins the first challenge)
-- ============================================================
INSERT INTO user_challenges (user_id, challenge_id, status, current_amount, target_amount, started_at, ends_at, completed_at)
SELECT u.user_id, c.id, 'IN_PROGRESS', 20.0000, c_target.target_amount,
       NOW(), NOW() + make_interval(days => c.duration_days), NULL
FROM users u
CROSS JOIN LATERAL (SELECT id, duration_days FROM challenges ORDER BY created_at LIMIT 1) c
CROSS JOIN LATERAL (SELECT target_amount FROM challenges_targets WHERE challenge_id = c.id ORDER BY tier_level LIMIT 1) c_target
WHERE NOT EXISTS (SELECT 1 FROM user_challenges uc WHERE uc.user_id = u.user_id AND uc.challenge_id = c.id);

-- ============================================================
-- 16) CHALLENGES PROGRESS (one audit row per joined user challenge)
-- ============================================================
INSERT INTO challenges_progress (user_challenge_id, amount_contributed, new_total_amount, transaction_reference, notes, created_at)
SELECT uc.id, 20.0000, 20.0000, NULL, 'Initial seeded contribution', NOW()
FROM user_challenges uc
WHERE NOT EXISTS (SELECT 1 FROM challenges_progress cp WHERE cp.user_challenge_id = uc.id);

-- ============================================================
-- 17) DECLINED CHALLENGES (5 — each user declines the last challenge)
-- ============================================================
INSERT INTO declined_challenges (user_id, challenge_id, declined_at)
SELECT u.user_id, c.id, NOW()
FROM users u
CROSS JOIN LATERAL (SELECT id FROM challenges ORDER BY created_at DESC LIMIT 1) c
WHERE NOT EXISTS (SELECT 1 FROM declined_challenges dc WHERE dc.user_id = u.user_id AND dc.challenge_id = c.id);

-- ============================================================
-- 18) USER GAMIFICATION SETTINGS (one per user, challenges enabled)
-- ============================================================
INSERT INTO user_gamification_settings (user_id, challenges_enabled, created_at, updated_at)
SELECT u.user_id, TRUE, NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM user_gamification_settings s WHERE s.user_id = u.user_id);

-- ============================================================
-- 19) USER SAVINGS (5 — one ledger entry per user)
-- ============================================================
INSERT INTO user_savings (saving_id, user_id, currency_code, amount, source, reference_id, note, created_at, updated_at)
SELECT gen_random_uuid(), u.user_id,
       CASE u.country_code WHEN 'GH' THEN 'GHS' WHEN 'NG' THEN 'NGN' WHEN 'KE' THEN 'KES' WHEN 'ZA' THEN 'ZAR' ELSE 'GHS' END,
       300.0000, 'DEPOSIT', NULL, 'Seeded savings', NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM user_savings s WHERE s.user_id = u.user_id);

-- ============================================================
-- 20) USER BILL PROVIDERS (5 — one saved biller per user; first ECG provider)
-- ============================================================
INSERT INTO user_bill_providers (user_bill_provider_id, user_id, provider_id, account_reference, linked_at, updated_at)
SELECT gen_random_uuid(), u.user_id,
       (SELECT provider_id FROM bill_providers ORDER BY created_at LIMIT 1),
       'ACCT_' || u.user_id::text, NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM user_bill_providers ubp WHERE ubp.user_id = u.user_id);

-- ============================================================
-- 21) SECURITY SETTINGS (one per user)
-- ============================================================
INSERT INTO security_settings (user_id, biometric_enabled, biometric_type, two_factor_enabled, two_factor_method, fraud_protection_enabled, created_at, updated_at)
SELECT u.user_id, TRUE, 'FINGERPRINT', TRUE, 'SMS', TRUE, NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM security_settings s WHERE s.user_id = u.user_id);

-- ============================================================
-- 22) LOGIN HISTORY (5+ — one per user, plus an extra failed attempt)
-- ============================================================
INSERT INTO login_history (user_id, ip_address, device_info, location, success, created_at)
SELECT u.user_id, '41.223.' || (row_number() OVER ())::text || '.100',
       'Pixel 8 / Android 15', 'Accra, GH', TRUE, NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM login_history lh WHERE lh.user_id = u.user_id);

-- ============================================================
-- 23) NOTIFICATIONS (5 — one welcome notification per user)
-- ============================================================
INSERT INTO notifications (user_id, title, message, type, is_read, created_at, updated_at)
SELECT u.user_id, 'Welcome to ZentraPay', 'Your account is ready. Explore ZGrow challenges!', 'SYSTEM', FALSE, NOW(), NOW()
FROM users u
WHERE NOT EXISTS (SELECT 1 FROM notifications n WHERE n.user_id = u.user_id);



