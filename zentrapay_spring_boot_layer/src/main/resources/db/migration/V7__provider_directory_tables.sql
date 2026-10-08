-- ============================================================
-- Provider directory tables: banks, mobile-money providers and
-- their gateway mappings, plus alignment of `bill_providers` with
-- the canonical BillProviderModel entity so the scheduled
-- ProviderSyncService can persist Flutterwave/Paystack/Onafriq data.
--
-- These tables were previously only created implicitly by Hibernate's
-- ddl-auto=update (so they were never version-controlled) and the
-- `bill_providers` entity columns had drifted from the V1 schema.
-- Every statement is idempotent (IF NOT EXISTS / guarded DO block) so
-- this migration can apply to the existing dev database as well as a
-- fresh environment.
-- ============================================================

-- BANKS (BanksModel)
-- `status VARCHAR` was replaced by the `active BOOLEAN` flag, and
-- `maxWeeklyValue` normalised to snake_case `max_weekly_value` to match every
-- other limit column. `type` carries the gateway's own classification and
-- `routing_number` is unique so the same domestic bank can't be linked twice.
CREATE TABLE IF NOT EXISTS banks (
    bank_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                VARCHAR(120) NOT NULL,
    bank_name           VARCHAR(180) NOT NULL,
    gateway             VARCHAR(30) NOT NULL,
    iban                VARCHAR(120),
    currency_code       VARCHAR(3) NOT NULL,
    pay_with_bank       BOOLEAN,
    swift_bic           VARCHAR(40),
    country_code        VARCHAR(3),
    country             VARCHAR(120),
    routing_number      VARCHAR(60),
    type                VARCHAR(60),
    active              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    max_daily_value     VARCHAR(60),
    max_monthly_value   VARCHAR(60),
    min_txn_limit       VARCHAR(60),
    max_txn_limit       VARCHAR(60),
    max_weekly_value    VARCHAR(60)
);
CREATE INDEX IF NOT EXISTS idx_banks_code_gateway_country ON banks(code, gateway, country_code);
CREATE UNIQUE INDEX IF NOT EXISTS idx_banks_routing_number ON banks(routing_number) WHERE routing_number IS NOT NULL;

-- If a Hibernate-created `banks` table pre-exists without routing_number, add it.
ALTER TABLE banks ADD COLUMN IF NOT EXISTS routing_number VARCHAR(60);
ALTER TABLE banks ADD COLUMN IF NOT EXISTS type VARCHAR(60);
ALTER TABLE banks ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT TRUE;

-- MOBILE MONEY PROVIDERS (MobileMoneyProvidersModel)
CREATE TABLE IF NOT EXISTS momo_providers (
    provider_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(180) NOT NULL,
    global_code     VARCHAR(30) NOT NULL,
    countryCode     VARCHAR(3) NOT NULL,
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_momo_providers_global_code ON momo_providers(global_code);

-- MOBILE MONEY GATEWAY MAPPINGS (MobileMoneyGatewayMappingsModel)
CREATE TABLE IF NOT EXISTS momo_gateway_mappings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id     UUID NOT NULL REFERENCES momo_providers(provider_id) ON DELETE CASCADE,
    gateway         VARCHAR(30) NOT NULL,
    gateway_code    VARCHAR(60) NOT NULL,
    country_code    VARCHAR(3) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_momo_gateway_mappings_provider ON momo_gateway_mappings(provider_id, gateway);

-- ALIGN `bill_providers` WITH BillProviderModel.
ALTER TABLE bill_providers ADD COLUMN IF NOT EXISTS channel_code VARCHAR(60);
ALTER TABLE bill_providers ADD COLUMN IF NOT EXISTS is_crossborder_allowed BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE bill_providers ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT TRUE;

-- Convert fetch_requirement (VARCHAR in V1, seeded with plain strings like
-- 'METER_NUMBER') to JSONB so it matches the entity's
-- List<Map<String,Object>> @JdbcTypeCode(SqlTypes.JSON) mapping. Only runs
-- when the column is still a plain string type; existing values are wrapped
-- into JSON arrays so reads and writes both work.
DO $$
DECLARE
    col_data_type TEXT;
BEGIN
    SELECT data_type INTO col_data_type
    FROM information_schema.columns
    WHERE table_name = 'bill_providers' AND column_name = 'fetch_requirement';

    IF col_data_type IS NOT NULL AND col_data_type NOT IN ('json', 'jsonb') THEN
        UPDATE bill_providers
        SET fetch_requirement = jsonb_build_array(fetch_requirement)
        WHERE fetch_requirement IS NOT NULL
          AND fetch_requirement NOT LIKE '[%';

        ALTER TABLE bill_providers
            ALTER COLUMN fetch_requirement TYPE jsonb
            USING fetch_requirement::jsonb;
    END IF;
END $$;