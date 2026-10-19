-- ============================================================
-- V29: ALIGN country_code COLUMN TYPES WITH JPA ENTITIES
-- ============================================================
-- Hibernate ddl-auto=validate enforces NOT ONLY column presence but ALSO the
-- column TYPE. Several V1 tables declared country_code as CHAR(2)/bpchar (the
-- ISO 3166-1 alpha-2 design), but the canonical JPA entities map country_code
-- as a plain String with length 3 -> VARCHAR(3). On PostgreSQL this surfaces as:
--
--   "Schema validation: wrong column type encountered in column [country_code]
--    in table [<t>]; found [bpchar], but expecting [varchar(3)]"
--
-- This migration normalizes every affected country_code column to VARCHAR(3)
-- so the final schema passes validation. Each statement is guarded so it is a
-- no-op on a database where the column is already VARCHAR.

-- 1) countries.country_code (CHAR(2) PK -> VARCHAR(3))
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'countries'
          AND column_name = 'country_code'
          AND data_type = 'character'
    ) THEN
        EXECUTE 'ALTER TABLE countries ALTER COLUMN country_code TYPE VARCHAR(3)';
    END IF;
END $$;

-- 2) bill_providers.country_code
ALTER TABLE bill_providers
    ALTER COLUMN country_code TYPE VARCHAR(3);

-- 3) service_providers.country_code
ALTER TABLE service_providers
    ALTER COLUMN country_code TYPE VARCHAR(3);

-- 4) payment_channels.country_code
ALTER TABLE payment_channels
    ALTER COLUMN country_code TYPE VARCHAR(3);

-- ============================================================
-- 5) bill_providers.customer_params_schema: jsonb -> TEXT
--    BillProviderModel maps `customerParamsSchema` as a plain String (no
--    @JdbcTypeCode(JSON)), so Hibernate expects varchar/OTHER-free TEXT, but
--    V1 created the column as jsonb. Convert the JSON to its text form and
--    change the type so validation accepts it.
-- ============================================================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'bill_providers'
          AND column_name = 'customer_params_schema'
          AND data_type = 'jsonb'
    ) THEN
        EXECUTE 'ALTER TABLE bill_providers ALTER COLUMN customer_params_schema TYPE TEXT USING customer_params_schema::text';
    END IF;
END $$;
