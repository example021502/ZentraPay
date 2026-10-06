
-- FIRST DROPPING THE TABLES IF THEY EXISTS
    DROP TABLE IF EXISTS challenges;
    DROP TABLE IF EXISTS challenges_targets;
    DROP TABLE IF EXISTS user_challenges;
    DROP TABLE IF EXISTS challenges_progress;

-- 1. Master Table: Available Challenges
CREATE TABLE challenges (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            title VARCHAR(150) NOT NULL,
                            description TEXT,
                            category VARCHAR(50) NOT NULL, -- e.g., 'SAVINGS', 'STREAK', 'INVESTMENT'
                            challenge_type VARCHAR(50) NOT NULL, -- e.g., 'FIXED_AMOUNT', 'RECURRING_DAILY', 'SAVINGS_GOAL'

    -- Frequency & Duration
                            duration_days INT NOT NULL, -- Total length of the challenge (e.g., 30 days)

    -- Status & Availability
                            is_active BOOLEAN NOT NULL DEFAULT TRUE,
                            start_date TIMESTAMP, -- Optional: For time-bounded event challenges
                            end_date TIMESTAMP,   -- Optional: Expiration date for accepting

                            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
                            updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 2. Target & Rewards Definition (Supports Multi-tier or Single Target)
CREATE TABLE challenges_targets (
                                   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                   challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,

                                   target_amount DECIMAL(19, 4) NOT NULL, -- Target saving/spending metric
                                   reward_type VARCHAR(50) NOT NULL,      -- 'POINTS', 'GIFT_BOX', 'CASHBACK', 'BADGE'
                                   reward_value VARCHAR(100) NOT NULL,    -- '500' (for points), 'GOLD_BOX_LVL1' (for gift box)

                                   tier_level INT NOT NULL DEFAULT 1,     -- 1 for single target; 1, 2, 3 for tiered rewards

                                   created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 3. User Acceptance & Overall State
CREATE TABLE user_challenges (
                                 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                 user_id UUID NOT NULL,                 -- Links to your central User table
                                 challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,

                                 status VARCHAR(30) NOT NULL DEFAULT 'IN_PROGRESS', -- 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'ABANDONED'

                                 current_amount DECIMAL(19, 4) NOT NULL DEFAULT 0.0000, -- Cumulative progress (e.g., total saved so far)
                                 target_amount DECIMAL(19, 4) NOT NULL,                 -- Snapshot of target at time of joining

                                 started_at TIMESTAMP NOT NULL DEFAULT NOW(),
                                 ends_at TIMESTAMP NOT NULL,                            -- Calculated based on started_at + duration_days
                                 completed_at TIMESTAMP,

                                 CONSTRAINT unique_user_active_challenge UNIQUE (user_id, challenge_id)
);

-- 4. Activity Audit & Progress History Ledger
CREATE TABLE challenges_progress (
                                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                    user_challenge_id UUID NOT NULL REFERENCES user_challenges(id) ON DELETE CASCADE,

                                    amount_contributed DECIMAL(19, 4) NOT NULL, -- Funds added in this specific action
                                    new_total_amount DECIMAL(19, 4) NOT NULL,   -- Updated running total

                                    transaction_reference UUID,                  -- Optional: Reference to app wallet transaction ID
                                    notes VARCHAR(255),

                                    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for Fast Querying
CREATE INDEX idx_user_challenges_user_status ON user_challenges(user_id, status);
CREATE INDEX idx_challenge_targets_challenge ON challenges_targets(challenge_id);

-- SEED RECORDS BELOW
-- Seed 5 Test Challenges for ZGrow Gamification Testing

-- Challenge 1: 30-Day Emergency Fund Saver
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, is_active, created_at, updated_at)
VALUES (
           '11111111-1111-1111-1111-111111111111',
           '30-Day Emergency Cushion',
           'Save $100 over the next 30 days to build your initial safety net and earn bonus reward points.',
           'SAVINGS',
           'SAVINGS_GOAL',
           30,
           true,
           NOW(),
           NOW()
       );

INSERT INTO challenges_targets (id, challenge_id, target_amount, reward_type, reward_value, tier_level, created_at)
VALUES (
           gen_random_uuid(),
           '11111111-1111-1111-1111-111111111111',
           100.0000,
           'POINTS',
           '500',
           1,
           NOW()
       );

-- Challenge 2: 7-Day Micro Savings Sprint
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, is_active, created_at, updated_at)
VALUES (
           '22222222-2222-2222-2222-222222222222',
           '7-Day Quick Saver Sprint',
           'Kickstart your savings habit by putting away $20 in just one week to unlock a Mystery Bronze Gift Box.',
           'SAVINGS',
           'FIXED_AMOUNT',
           7,
           true,
           NOW(),
           NOW()
       );

INSERT INTO challenges_targets (id, challenge_id, target_amount, reward_type, reward_value, tier_level, created_at)
VALUES (
           gen_random_uuid(),
           '22222222-2222-2222-2222-222222222222',
           20.0000,
           'GIFT_BOX',
           'BRONZE_BOX_LVL1',
           1,
           NOW()
       );

-- Challenge 3: 14-Day Consecutive Deposit Streak
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, is_active, created_at, updated_at)
VALUES (
           '33333333-3333-3333-3333-333333333333',
           '14-Day Consistency Master',
           'Deposit funds toward your goals across 14 consecutive days to achieve a total of $70 and earn 1% cashback on your next wallet transaction.',
           'STREAK',
           'RECURRING_DAILY',
           14,
           true,
           NOW(),
           NOW()
       );

INSERT INTO challenges_targets (id, challenge_id, target_amount, reward_type, reward_value, tier_level, created_at)
VALUES (
           gen_random_uuid(),
           '33333333-3333-3333-3333-333333333333',
           70.0000,
           'CASHBACK',
           '1_PERCENT_CASHBACK_PASS',
           1,
           NOW()
       );

-- Challenge 4: Multi-Tiered Wealth Builder (Tiered Rewards)
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, is_active, created_at, updated_at)
VALUES (
           '44444444-4444-4444-4444-444444444444',
           '60-Day Wealth Accumulator',
           'Challenge yourself to save up to $500 over 60 days. Unlocks higher reward tiers as you reach milestones!',
           'SAVINGS',
           'SAVINGS_GOAL',
           60,
           true,
           NOW(),
           NOW()
       );

-- Tier 1 Target ($100)
INSERT INTO challenges_targets (id, challenge_id, target_amount, reward_type, reward_value, tier_level, created_at)
VALUES (
           gen_random_uuid(),
           '44444444-4444-4444-4444-444444444444',
           100.0000,
           'POINTS',
           '250',
           1,
           NOW()
       );

-- Tier 2 Target ($500)
INSERT INTO challenges_targets (id, challenge_id, target_amount, reward_type, reward_value, tier_level, created_at)
VALUES (
           gen_random_uuid(),
           '44444444-4444-4444-4444-444444444444',
           500.0000,
           'GIFT_BOX',
           'GOLD_BOX_LVL3',
           2,
           NOW()
       );

-- Challenge 5: First Investment Explorer
INSERT INTO challenges (id, title, description, category, challenge_type, duration_days, is_active, created_at, updated_at)
VALUES (
           '55555555-5555-5555-5555-555555555555',
           'Investment Pioneer',
           'Allocate $50 into any ZGrow investment pool within 15 days to earn the Early Investor Badge and 1,000 Points.',
           'INVESTMENT',
           'FIXED_AMOUNT',
           15,
           true,
           NOW(),
           NOW()
       );

INSERT INTO challenges_targets (id, challenge_id, target_amount, reward_type, reward_value, tier_level, created_at)
VALUES (
           gen_random_uuid(),
           '55555555-5555-5555-5555-555555555555',
           50.0000,
           'BADGE',
           'EARLY_INVESTOR_BADGE',
           1,
           NOW()
       );