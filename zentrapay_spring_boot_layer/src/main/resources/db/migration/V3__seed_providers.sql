-- Starter bill/service provider catalog across ZentraPay's initial markets
-- (Ghana, Nigeria, Kenya, South Africa, Uganda) so the relevant screens are
-- populated out of the box. This is a seed, not an exhaustive directory —
-- more providers/countries are added the same way (a data INSERT, not a
-- schema change).

-- ============================================================
-- BILL PROVIDERS (utilities, TV, government)
-- ============================================================
INSERT INTO bill_providers (biller_code, biller_name, category_code, country_code, logo_url, fetch_requirement, status) VALUES
('GH_ECG', 'Electricity Company of Ghana (ECG)', 'UTILITY', 'GH', NULL, 'METER_NUMBER', 'ACTIVE'),
('GH_GWCL', 'Ghana Water Company Limited', 'UTILITY', 'GH', NULL, 'ACCOUNT_NUMBER', 'ACTIVE'),
('GH_DSTV', 'DStv Ghana', 'TV_SUBSCRIPTION', 'GH', NULL, 'SMARTCARD_NUMBER', 'ACTIVE'),
('NG_EKEDC', 'Eko Electricity Distribution Company', 'UTILITY', 'NG', NULL, 'METER_NUMBER', 'ACTIVE'),
('NG_DSTV', 'DStv Nigeria', 'TV_SUBSCRIPTION', 'NG', NULL, 'SMARTCARD_NUMBER', 'ACTIVE'),
('KE_KPLC', 'Kenya Power (KPLC)', 'UTILITY', 'KE', NULL, 'ACCOUNT_NUMBER', 'ACTIVE'),
('KE_DSTV', 'DStv Kenya', 'TV_SUBSCRIPTION', 'KE', NULL, 'SMARTCARD_NUMBER', 'ACTIVE'),
('ZA_ESKOM', 'Eskom', 'UTILITY', 'ZA', NULL, 'METER_NUMBER', 'ACTIVE'),
('ZA_DSTV', 'DStv South Africa', 'TV_SUBSCRIPTION', 'ZA', NULL, 'SMARTCARD_NUMBER', 'ACTIVE'),
('UG_UMEME', 'Umeme', 'UTILITY', 'UG', NULL, 'METER_NUMBER', 'ACTIVE');

-- ============================================================
-- SERVICE PROVIDERS (airtime/data/insurance value-added services)
-- ============================================================
INSERT INTO service_providers (provider_code, provider_name, category_code, aggregator_gateway, country_code, logo_url, is_active) VALUES
('GH_MTN', 'MTN Ghana', 'AIRTIME', 'PAYSTACK', 'GH', NULL, TRUE),
('GH_VODAFONE', 'Vodafone Ghana', 'AIRTIME', 'PAYSTACK', 'GH', NULL, TRUE),
('GH_AIRTELTIGO', 'AirtelTigo Ghana', 'AIRTIME', 'PAYSTACK', 'GH', NULL, TRUE),
('NG_MTN', 'MTN Nigeria', 'AIRTIME', 'FLUTTERWAVE', 'NG', NULL, TRUE),
('NG_AIRTEL', 'Airtel Nigeria', 'AIRTIME', 'FLUTTERWAVE', 'NG', NULL, TRUE),
('NG_GLO', 'Glo Nigeria', 'AIRTIME', 'FLUTTERWAVE', 'NG', NULL, TRUE),
('KE_SAFARICOM', 'Safaricom', 'AIRTIME', 'FLUTTERWAVE', 'KE', NULL, TRUE),
('ZA_VODACOM', 'Vodacom', 'AIRTIME', 'FLUTTERWAVE', 'ZA', NULL, TRUE),
('ZA_MTN', 'MTN South Africa', 'AIRTIME', 'FLUTTERWAVE', 'ZA', NULL, TRUE),
('UG_MTN', 'MTN Uganda', 'AIRTIME', 'FLUTTERWAVE', 'UG', NULL, TRUE);

-- ============================================================
-- PAYMENT CHANNELS (bank directory seed — a live sync job refreshes/extends
-- this from each gateway's bank-list API; see PaymentChannelSyncService)
-- ============================================================
INSERT INTO payment_channels (channel_code, channel_name, channel_type, country_code, gateway, is_active) VALUES
('GH_GCB', 'GCB Bank', 'BANK', 'GH', 'PAYSTACK', TRUE),
('GH_ECOBANK', 'Ecobank Ghana', 'BANK', 'GH', 'PAYSTACK', TRUE),
('GH_ABSA', 'Absa Bank Ghana', 'BANK', 'GH', 'PAYSTACK', TRUE),
('GH_MTN_MOMO', 'MTN Mobile Money', 'MOBILE_MONEY', 'GH', 'PAYSTACK', TRUE),
('GH_VODAFONE_CASH', 'Vodafone Cash', 'MOBILE_MONEY', 'GH', 'PAYSTACK', TRUE),
('NG_GTBANK', 'Guaranty Trust Bank', 'BANK', 'NG', 'FLUTTERWAVE', TRUE),
('NG_ZENITH', 'Zenith Bank', 'BANK', 'NG', 'FLUTTERWAVE', TRUE),
('KE_MPESA', 'M-Pesa', 'MOBILE_MONEY', 'KE', 'FLUTTERWAVE', TRUE),
('ZA_ABSA', 'Absa Bank South Africa', 'BANK', 'ZA', 'FLUTTERWAVE', TRUE);

-- ============================================================
-- SEED FINANCIAL LITERACY CONTENT (ZGrow "Learn & Earn")
-- ============================================================
INSERT INTO financial_literacy_content (title, category, content_url, duration_minutes, points_reward, is_active) VALUES
('Budgeting Basics: The 50/30/20 Rule', 'BUDGETING', NULL, 5, 20, TRUE),
('Why an Emergency Fund Matters', 'SAVINGS', NULL, 4, 15, TRUE),
('Understanding Mobile Money Fees', 'PAYMENTS', NULL, 3, 10, TRUE),
('Intro to Investing in Africa', 'INVESTING', NULL, 6, 25, TRUE),
('Avoiding Fraud & Scams', 'SECURITY', NULL, 4, 15, TRUE);
