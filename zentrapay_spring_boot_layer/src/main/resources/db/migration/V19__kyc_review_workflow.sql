-- KYC review workflow: a verification officer (user_type KYC_OFFICER / ADMIN)
-- checks the submitted documents and is the only one who can raise a user to
-- tier 2. kyc_status moves pending -> submitted -> verified | rejected.
ALTER TABLE user_profiles
    ADD COLUMN IF NOT EXISTS kyc_submitted_at timestamp with time zone,
    ADD COLUMN IF NOT EXISTS kyc_reviewed_at timestamp with time zone,
    ADD COLUMN IF NOT EXISTS kyc_reviewed_by uuid,
    ADD COLUMN IF NOT EXISTS kyc_review_note character varying(500);

CREATE INDEX IF NOT EXISTS idx_user_profiles_kyc_status ON user_profiles (kyc_status);
