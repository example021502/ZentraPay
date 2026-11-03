-- V16: one reference table for places and money.
--
-- The separate gateway_currencies table is retired. gateway_countries is now the only table: each country
-- carries its default_currency (the existing per-country currency column, renamed so its job is obvious),
-- and that single value is what restricts payments - a user registered in a country can pay in that
-- country's default currency, and a cross-border payment lands in the destination country's default currency.
--
-- The values already in the column become the default currencies; edit them directly in this table to change
-- what a country is allowed to use. The directory sync never overwrites a value that is already set.

ALTER TABLE gateway_countries RENAME COLUMN currency_code TO default_currency;

UPDATE gateway_countries SET default_currency = upper(trim(default_currency));

-- Currency symbols / names / decimals now come from the application, not from a table
DROP TABLE IF EXISTS gateway_currencies;

CREATE INDEX IF NOT EXISTS idx_gateway_countries_default_currency ON gateway_countries USING btree (default_currency);
