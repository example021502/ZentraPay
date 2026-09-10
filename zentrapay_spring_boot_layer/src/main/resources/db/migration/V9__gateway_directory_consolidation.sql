-- ============================================================
-- V9: GATEWAY DIRECTORY CONSOLIDATION
--
-- `gateway_countries` and `gateway_currencies` are now THE canonical
-- reference tables for countries/currencies ZentraPay supports. They
-- replace the static world-reference tables `countries` and `currencies`
-- (which listed every world country regardless of gateway support) and
-- the Hibernate-created `gateway_account_countries` /
-- `gateway_account_currencies` scratch tables (per-account wallet
-- helpers, never a directory).
--
-- Rows are populated automatically by the scheduled
-- GatewayDirectorySyncService from what the connected gateways
-- (Paystack / Flutterwave / Onafriq) actually report as supported,
-- so this file only seeds the baseline from the legacy tables when
-- they still exist. Every statement is idempotent.
-- ============================================================

CREATE TABLE IF NOT EXISTS gateway_countries (
    country_code    VARCHAR(3) PRIMARY KEY,             -- ISO 3166-1 alpha-2
    country_name    VARCHAR(80) NOT NULL,
    iso3_code       VARCHAR(3),
    dial_code       VARCHAR(6),
    region          VARCHAR(40),
    currency_code   VARCHAR(8) NOT NULL DEFAULT '',     -- default payout currency for this country
    gateways        TEXT NOT NULL DEFAULT '',           -- comma-separated gateways supporting it, e.g. 'paystack,flutterwave'
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_gateway_countries_active ON gateway_countries(active);

-- NORMALISE pre-existing Hibernate-created copies of these tables.
-- ddl-auto=update runs before Flyway ever did (Boot 4 needs the
-- spring-boot-flyway module for that), so some dev databases already hold
-- these tables WITHOUT the canonical column defaults â€” which breaks the
-- seeding below. Re-applying SET DEFAULT on a freshly created table is a
-- harmless no-op, so this always runs.
ALTER TABLE gateway_countries ALTER COLUMN currency_code SET DEFAULT '';
ALTER TABLE gateway_countries ALTER COLUMN gateways SET DEFAULT '';
ALTER TABLE gateway_countries ALTER COLUMN is_default SET DEFAULT FALSE;
ALTER TABLE gateway_countries ALTER COLUMN active SET DEFAULT TRUE;
ALTER TABLE gateway_countries ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE gateway_countries ALTER COLUMN updated_at SET DEFAULT now();

CREATE TABLE IF NOT EXISTS gateway_currencies (
    currency_code   VARCHAR(8) PRIMARY KEY,             -- ISO 4217
    currency_name   VARCHAR(60) NOT NULL,
    symbol          VARCHAR(8) NOT NULL DEFAULT '',
    is_crypto       BOOLEAN NOT NULL DEFAULT FALSE,
    decimal_places  SMALLINT NOT NULL DEFAULT 2,
    country_code    VARCHAR(3) NOT NULL DEFAULT '',     -- home country of the currency ('' = multi-country)
    gateways        TEXT NOT NULL DEFAULT '',
    is_default      BOOLEAN NOT NULL DEFAULT TRUE,
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_gateway_currencies_country ON gateway_currencies(country_code);

ALTER TABLE gateway_currencies ALTER COLUMN symbol SET DEFAULT '';
ALTER TABLE gateway_currencies ALTER COLUMN is_crypto SET DEFAULT FALSE;
ALTER TABLE gateway_currencies ALTER COLUMN decimal_places SET DEFAULT 2;
ALTER TABLE gateway_currencies ALTER COLUMN country_code SET DEFAULT '';
ALTER TABLE gateway_currencies ALTER COLUMN gateways SET DEFAULT '';
ALTER TABLE gateway_currencies ALTER COLUMN is_default SET DEFAULT TRUE;
ALTER TABLE gateway_currencies ALTER COLUMN active SET DEFAULT TRUE;
ALTER TABLE gateway_currencies ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE gateway_currencies ALTER COLUMN updated_at SET DEFAULT now();

-- ------------------------------------------------------------
-- SEED baseline rows from the legacy world-reference tables when
-- they are present (fresh environments skip this; the scheduler
-- populates everything from the gateways instead).
-- ------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('public.countries') IS NOT NULL THEN
        -- Legacy `countries` shapes vary: the original V1 table carried the
        -- full reference columns, but some hand-built/Hibernate dev databases
        -- only have (country_code, country_name[, region]). Try the richest
        -- mapping first and degrade gracefully on undefined columns â€” the
        -- scheduler refresh fills in whatever metadata is missing anyway.
        BEGIN
            INSERT INTO gateway_countries
                (country_code, country_name, iso3_code, dial_code, region, currency_code, active)
            SELECT c.country_code, c.country_name, c.iso3_code, c.dial_code, c.region,
                   c.default_currency_code, COALESCE(c.is_active, TRUE)
            FROM countries c
            ON CONFLICT (country_code) DO NOTHING;
        EXCEPTION WHEN undefined_column THEN
            BEGIN
                INSERT INTO gateway_countries
                    (country_code, country_name, region)
                SELECT c.country_code, c.country_name, c.region
                FROM countries c
                ON CONFLICT (country_code) DO NOTHING;
            EXCEPTION WHEN undefined_column THEN
                INSERT INTO gateway_countries
                    (country_code, country_name)
                SELECT c.country_code, c.country_name
                FROM countries c
                ON CONFLICT (country_code) DO NOTHING;
            END;
        END;
    END IF;

    IF to_regclass('public.currencies') IS NOT NULL THEN
        INSERT INTO gateway_currencies
            (currency_code, currency_name, symbol, is_crypto, decimal_places, active)
        SELECT cu.currency_code, cu.currency_name, cu.symbol, cu.is_crypto,
               cu.decimal_places, cu.is_active
        FROM currencies cu
        ON CONFLICT (currency_code) DO NOTHING;
    END IF;

    -- Merge any country/currency codes already discovered in the
    -- Hibernate-created gateway_account_* tables (metadata unknown ->
    -- filled in later by the scheduler refresh).
    IF to_regclass('public.gateway_account_countries') IS NOT NULL THEN
        INSERT INTO gateway_countries (country_code, country_name, active)
        SELECT DISTINCT gac.country_code, gac.country_code, gac.active
        FROM gateway_account_countries gac
        WHERE gac.country_code IS NOT NULL AND gac.country_code <> ''
        ON CONFLICT (country_code) DO NOTHING;
    END IF;

    IF to_regclass('public.gateway_account_currencies') IS NOT NULL THEN
        INSERT INTO gateway_currencies (currency_code, currency_name, active)
        SELECT DISTINCT gacu.currency_code, gacu.currency_code, gacu.active
        FROM gateway_account_currencies gacu
        WHERE gacu.currency_code IS NOT NULL AND gacu.currency_code <> ''
        ON CONFLICT (currency_code) DO NOTHING;
    END IF;
END $$;

-- ------------------------------------------------------------
-- RETIRE the legacy tables. Many V1/V4 tables carry FK constraints
-- pointing at them; drop every such constraint first (dynamic loop so
-- no referencing table is missed now or in future migrations), then
-- drop the tables themselves plus the old gateway_account_* scratch
-- tables.
-- ------------------------------------------------------------
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT con.conname AS conname,
               con.conrelid::regclass::text AS tbl
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.confrelid
        JOIN pg_namespace ns ON ns.oid = rel.relnamespace
        WHERE con.contype = 'f'
          AND ns.nspname = 'public'
          AND rel.relname IN ('countries', 'currencies')
    LOOP
        EXECUTE format('ALTER TABLE %s DROP CONSTRAINT IF EXISTS %I', r.tbl, r.conname);
    END LOOP;
END $$;

DROP TABLE IF EXISTS countries;
DROP TABLE IF EXISTS currencies;
DROP TABLE IF EXISTS gateway_account_countries;
DROP TABLE IF EXISTS gateway_account_currencies;