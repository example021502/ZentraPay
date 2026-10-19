-- ============================================================
-- V25: ZGROW TEST CHALLENGE SEEDS
--
-- A handful of extra challenge catalog records (with their target
-- tiers) so join / decline / progress flows can be exercised end to
-- end. All seeds use fixed UUIDs — any statement is safe to run even
-- if an earlier attempt already inserted the row (ON CONFLICT DO
-- NOTHING), and re-running Flyway can never duplicate them.
-- New categories stay inside Datatypes.ChallengeCategory so the
-- ?category= filter keeps working.
-- ============================================================

-- Challenge 6: 21-Day No-Spend Sprint
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, active, created_at, updated_at)
VALUES
    (
        '66666666-6666-6666-6666-666666666666',
        '21-Day No-Spend Sprint',
        'Skip non-essential spending for 21 days and stash GHS 150 toward your emergency fund. Earn 400 points on completion.',
        'SPENDING_LIMIT',
        'SAVINGS_GOAL',
        21,
        true,
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO NOTHING;

-- Challenge 7: Weekend Hustle Booster
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, active, created_at, updated_at)
VALUES
    (
        '77777777-7777-7777-7777-777777777777',
        'Weekend Hustle Booster',
        'Top up any savings wallet with GHS 50 every weekend for 4 weekends in a row. Unlock the Hustler Badge.',
        'STREAK',
        'RECURRING_DAILY',
        28,
        true,
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO NOTHING;

-- Challenge 8: Round-Up Reserve Builder
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, active, created_at, updated_at)
VALUES
    (
        '88888888-8888-8888-8888-888888888888',
        'Round-Up Reserve Builder',
        'Round every wallet spend up to the nearest GHS 5 for 30 days and bank the difference. Target: GHS 200 for a cashback pass.',
        'SAVINGS',
        'SAVINGS_GOAL',
        30,
        true,
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO NOTHING;

-- Challenge 9: Micro-Investor Starter
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, active, created_at, updated_at)
VALUES
    (
        '99999999-9999-9999-9999-999999999999',
        'Micro-Investor Starter',
        'Put GHS 30 into any investment pool within 10 days. First-timers earn 250 points plus the Starter Badge.',
        'INVESTMENT',
        'FIXED_AMOUNT',
        10,
        true,
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO NOTHING;

-- Challenge 10: 7-Day Coffee Skip
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, active, created_at, updated_at)
VALUES
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '7-Day Coffee Skip',
        'Skip the daily coffee run for 7 days and save GHS 70. A quick win worth 150 points.',
        'SPENDING_LIMIT',
        'FIXED_AMOUNT',
        7,
        true,
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO NOTHING;

-- Challenge 11: Payday 10% Rule
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, active, created_at, updated_at)
VALUES
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'Payday 10% Rule',
        'Move 10% of your next two paychecks (GHS 300 total) into savings before you spend a cedi. Unlocks a silver gift box.',
        'SAVINGS',
        'SAVINGS_GOAL',
        60,
        true,
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO NOTHING;

-- Target tiers for challenges 6-11 (insert only if parent challenge does not exist)
INSERT INTO challenges_targets (id, challenge_id, target_amount, reward_type, reward_value, tier_level, created_at)
SELECT gen_random_uuid(), v.challenge_id, v.target_amount, v.reward_type, v.reward_value, v.tier_level, NOW()
FROM (VALUES
    ('66666666-6666-6666-6666-666666666666'::uuid, 150.0000::numeric(19,4), 'POINTS'::varchar, '400'::varchar, 1),
    ('77777777-7777-7777-7777-777777777777'::uuid, 200.0000::numeric(19,4), 'BADGE'::varchar, 'HUSTLER_BADGE'::varchar, 1),
    ('88888888-8888-8888-8888-888888888888'::uuid, 200.0000::numeric(19,4), 'CASHBACK'::varchar, '1_PERCENT_CASHBACK_PASS'::varchar, 1),
    ('99999999-9999-9999-9999-999999999999'::uuid, 30.0000::numeric(19,4), 'POINTS'::varchar, '250'::varchar, 1),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, 70.0000::numeric(19,4), 'POINTS'::varchar, '150'::varchar, 1),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid, 300.0000::numeric(19,4), 'GIFT_BOX'::varchar, 'SILVER_BOX_LVL2'::varchar, 1)
) AS v(challenge_id, target_amount, reward_type, reward_value, tier_level)
WHERE NOT EXISTS (
    SELECT 1 FROM challenges_targets t
     WHERE t.challenge_id = v.challenge_id AND t.tier_level = v.tier_level
    AND t.challenge_id IN (
        '66666666-6666-6666-6666-666666666666',
        '77777777-7777-7777-7777-777777777777',
        '88888888-8888-8888-8888-888888888888',
        '99999999-9999-9999-9999-999999999999',
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
    )
);
