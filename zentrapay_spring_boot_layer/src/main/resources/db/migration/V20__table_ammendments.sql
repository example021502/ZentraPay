-- CREATING A NEW ENUM TYPE FOR USER TYPE
-- Labels must exactly match Datatypes.UserType (APP_USER, MERCHANT, AGENT, OTHERS).
DROP TYPE IF EXISTS user_type CASCADE;
CREATE TYPE user_type AS ENUM ('APP_USER', 'MERCHANT', 'AGENT', 'OTHERS');

-- CREATING A NEW ENUM FOR USER STATUSES
-- Labels must exactly match Datatypes.UserStatus (ACTIVE, INACTIVE, FROZEN).
DROP TYPE IF EXISTS user_status CASCADE;
CREATE TYPE user_status AS ENUM ('ACTIVE', 'INACTIVE', 'FROZEN');

-- Normalise the legacy 'INDIVIDUAL' default (from V1) to 'APP_USER' before the
-- column becomes an enum, otherwise that legacy value is not a valid label.
UPDATE users SET user_type = 'APP_USER' WHERE user_type = 'INDIVIDUAL';

-- Drop the V1 CHECK constraints so the columns can be retyped to their enums.
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_user_type_check;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_status_check;

-- Convert the columns to their enum types (explicit cast via varchar).
ALTER TABLE users
    ALTER COLUMN user_type DROP DEFAULT,
    ALTER COLUMN user_type TYPE user_type USING (user_type::varchar)::user_type,
    ALTER COLUMN user_type SET DEFAULT 'APP_USER';

ALTER TABLE users
    ALTER COLUMN status DROP DEFAULT,
    ALTER COLUMN status TYPE user_status USING (status::varchar)::user_status,
    ALTER COLUMN status SET DEFAULT 'ACTIVE';

