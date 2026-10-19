-- ============================================================
-- V23: BILL PROVIDERS — STATUS CLEANUP / CATEGORY LINK / MULTI-GATEWAY
--
-- 1. `active` (BOOLEAN) is the single source of truth for whether a
--    provider is live — drop the legacy `status` VARCHAR column V1
--    created; the two columns described the same thing.
-- 2. The same biller can be offered by more than one gateway provider,
--    so `biller_code` can no longer be UNIQUE — the API dedupes the
--    directory down to one row per provider before sending it out.
-- 3. The dev database was built by hand and lost the original V1
--    foreign key from bill_providers.category_code to the standalone
--    provider_categories lookup. Keeping categories in their own
--    normalized table is the standard layout — re-link it.
-- ============================================================

-- 1. status -> active ------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'bill_providers' AND column_name = 'status') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                       WHERE table_name = 'bill_providers' AND column_name = 'active') THEN
            ALTER TABLE bill_providers ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE;
        END IF;
        -- Preserve intent: only rows previously flagged 'ACTIVE' stay active.
        UPDATE bill_providers
           SET active = (LOWER(COALESCE(status, 'ACTIVE')) = 'active')
         WHERE active IS DISTINCT FROM (LOWER(COALESCE(status, 'ACTIVE')) = 'active');
        ALTER TABLE bill_providers DROP COLUMN status;
    END IF;
END $$;

-- 2. multi-gateway rows: drop the UNIQUE on biller_code -------------------
-- V1 declared it inline UNIQUE (PostgreSQL names that bill_providers_biller_code_key).
ALTER TABLE bill_providers DROP CONSTRAINT IF EXISTS bill_providers_biller_code_key;
DROP INDEX IF EXISTS idx_bill_providers_biller_code;

-- 3. category directory link ----------------------------------------------
-- 'OTHERS' is the catch-all bucket in Datatypes.ProviderCategory — make sure
-- it exists so no provider can orphan itself out of the FK.
INSERT INTO provider_categories (category_code, category_name) VALUES
    ('OTHERS', 'Other Services')
ON CONFLICT (category_code) DO NOTHING;

-- Remove any orphan category codes first so the FK can always be enforced.
DELETE FROM bill_providers bp
 WHERE NOT EXISTS (SELECT 1 FROM provider_categories pc
                    WHERE pc.category_code = bp.category_code);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                    WHERE conname = 'fk_bill_providers_category_code'
                      AND conrelid = 'bill_providers'::regclass) THEN
        ALTER TABLE bill_providers
            ADD CONSTRAINT fk_bill_providers_category_code
            FOREIGN KEY (category_code) REFERENCES provider_categories(category_code);
    END IF;
END $$;