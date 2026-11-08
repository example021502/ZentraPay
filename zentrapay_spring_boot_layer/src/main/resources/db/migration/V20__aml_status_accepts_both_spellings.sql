-- The AML status check differed between databases: V1 allows CLEAR / PENDING_REVIEW / FLAGGED,
-- while databases built earlier allow CLEAR / IN_REVIEW / FLAGGED (the spelling the code uses).
-- Accept both so a profile can be saved on either; nothing else changes.
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_aml_status_check;
ALTER TABLE user_profiles
    ADD CONSTRAINT user_profiles_aml_status_check
    CHECK (anti_money_laundering_status IN ('CLEAR', 'IN_REVIEW', 'PENDING_REVIEW', 'FLAGGED'));
