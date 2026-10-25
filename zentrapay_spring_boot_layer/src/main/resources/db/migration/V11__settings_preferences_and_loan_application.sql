-- V11: per-user preferences on security_settings, and the extra information a loan
-- application collects (purpose, employment, income, next of kin, consents).

-- Preferences the Settings screen reads and writes
ALTER TABLE security_settings
    ADD COLUMN dark_mode boolean DEFAULT false NOT NULL,
    ADD COLUMN push_notifications_enabled boolean DEFAULT true NOT NULL,
    ADD COLUMN transaction_alerts_enabled boolean DEFAULT true NOT NULL;

-- Loan application details
ALTER TABLE loans
    ADD COLUMN purpose character varying(30),
    ADD COLUMN employment_status character varying(30),
    ADD COLUMN employer_name character varying(120),
    ADD COLUMN job_title character varying(80),
    ADD COLUMN monthly_income numeric(19,4),
    ADD COLUMN monthly_obligations numeric(19,4),
    ADD COLUMN next_of_kin_name character varying(120),
    ADD COLUMN next_of_kin_relationship character varying(40),
    ADD COLUMN next_of_kin_phone character varying(20),
    ADD COLUMN credit_check_consent boolean DEFAULT false NOT NULL,
    ADD COLUMN terms_accepted boolean DEFAULT false NOT NULL,
    ADD COLUMN risk_grade character varying(2),
    ADD COLUMN decision_note character varying(255);
