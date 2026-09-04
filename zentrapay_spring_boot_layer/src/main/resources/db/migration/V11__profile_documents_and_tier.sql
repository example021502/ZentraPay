-- ============================================================
-- V11: Document-upload columns for Tier-2 KYC + reconcile
-- user_profiles with the entity's actual column names.
--
-- V1__init_schema.sql created user_profiles with an older column
-- naming scheme (id_document_type, address_line1, city, region_state,
-- occupation, aml_status, is_pep) that no longer matches
-- UserProfileModel's real @Column names (identity_document_type,
-- address_1, city_name, state_or_region, occupation_title,
-- anti_money_laundering_status, politically_exposed_person). Nothing
-- since V1 fixed that drift — Hibernate's ddl-auto=update has been
-- silently adding the new columns alongside the orphaned old ones.
-- This migration renames the survivors and adds the three new
-- document-path columns, all guarded so it is safe to run against
-- either a fresh V1 database or one already patched by ddl-auto.
-- ============================================================

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'id_document_type')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'identity_document_type') THEN
    ALTER TABLE user_profiles RENAME COLUMN id_document_type TO identity_document_type;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'id_document_number')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'identity_document_number') THEN
    ALTER TABLE user_profiles RENAME COLUMN id_document_number TO identity_document_number;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'id_document_country_code')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'identity_document_issuing_country_code') THEN
    ALTER TABLE user_profiles RENAME COLUMN id_document_country_code TO identity_document_issuing_country_code;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'address_line1')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'address_1') THEN
    ALTER TABLE user_profiles RENAME COLUMN address_line1 TO address_1;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'address_line2')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'address_2') THEN
    ALTER TABLE user_profiles RENAME COLUMN address_line2 TO address_2;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'city')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'city_name') THEN
    ALTER TABLE user_profiles RENAME COLUMN city TO city_name;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'region_state')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'state_or_region') THEN
    ALTER TABLE user_profiles RENAME COLUMN region_state TO state_or_region;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'occupation')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'occupation_title') THEN
    ALTER TABLE user_profiles RENAME COLUMN occupation TO occupation_title;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'aml_status')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'anti_money_laundering_status') THEN
    ALTER TABLE user_profiles RENAME COLUMN aml_status TO anti_money_laundering_status;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'is_pep')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'politically_exposed_person') THEN
    ALTER TABLE user_profiles RENAME COLUMN is_pep TO politically_exposed_person;
  END IF;

  -- nationality_country_code / identity_document_expiration_date / kyc_status
  -- were never in V1 at all — add if this is a fresh-enough DB that
  -- ddl-auto hasn't already created them.
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'nationality_country_code') THEN
    ALTER TABLE user_profiles ADD COLUMN nationality_country_code VARCHAR(3);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'identity_document_expiration_date') THEN
    ALTER TABLE user_profiles ADD COLUMN identity_document_expiration_date DATE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'kyc_status') THEN
    ALTER TABLE user_profiles ADD COLUMN kyc_status VARCHAR(20) NOT NULL DEFAULT 'pending';
  END IF;
END $$;

-- New Tier-2 document-upload columns (see DocumentsService / DocumentUploadController).
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS id_document_front_path VARCHAR(255);
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS id_document_back_path VARCHAR(255);
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS selfie_path VARCHAR(255);
