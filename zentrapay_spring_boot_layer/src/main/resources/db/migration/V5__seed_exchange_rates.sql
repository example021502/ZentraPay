-- Seed illustrative exchange rates for the Converter/Remittance modules
-- (API_CONTRACT.md §11/§12). Rates are pivoted through USD — the ConverterService
-- resolves any pair either directly, by inverting the opposite-direction row, or by
-- triangulating through USD, so only USD<->X pairs need to be seeded here to answer
-- every cross-currency pair among these seven currencies.
--
-- Values are illustrative/reasonable approximations (source='SEED'), not a live feed —
-- there is no forex provider integrated in this codebase yet.

INSERT INTO exchange_rates (base_currency_code, quote_currency_code, rate, source, effective_at) VALUES
('USD', 'GHS', 15.2000000000, 'SEED', now()),
('GHS', 'USD', 0.0657894737, 'SEED', now()),

('USD', 'NGN', 1550.0000000000, 'SEED', now()),
('NGN', 'USD', 0.0006451613, 'SEED', now()),

('USD', 'KES', 129.0000000000, 'SEED', now()),
('KES', 'USD', 0.0077519380, 'SEED', now()),

('USD', 'ZAR', 18.2000000000, 'SEED', now()),
('ZAR', 'USD', 0.0549450549, 'SEED', now()),

('USD', 'EUR', 0.9200000000, 'SEED', now()),
('EUR', 'USD', 1.0869565217, 'SEED', now()),

('USD', 'GBP', 0.7900000000, 'SEED', now()),
('GBP', 'USD', 1.2658227848, 'SEED', now());
