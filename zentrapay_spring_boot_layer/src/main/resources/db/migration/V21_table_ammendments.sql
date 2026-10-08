-- Always put comments on all responses.
-- 1. Drop the existing outdated check constraint
ALTER TABLE users
DROP CONSTRAINT users_user_type_check;

-- 2. Add the updated check constraint containing all supported user types
ALTER TABLE users
    ADD CONSTRAINT users_user_type_check
        CHECK (user_type IN (
                             'APP_USER',
                             'MERCHANT',
                             'AGENT',
                             'OTHERS',
            ));