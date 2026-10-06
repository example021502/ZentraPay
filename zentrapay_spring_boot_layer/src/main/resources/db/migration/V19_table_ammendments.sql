-- 1. Drop existing user_reward_balances table
DROP TABLE IF EXISTS user_reward_balances CASCADE;

-- 2. Drop and recreate clean rewards table
DROP TABLE IF EXISTS rewards CASCADE;

CREATE TABLE rewards (
                         reward_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                         reward_type VARCHAR(50) NOT NULL,
                         title VARCHAR(150) NOT NULL,
                         description TEXT NOT NULL,
                         worth DECIMAL(10, 2) NOT NULL,
                         currency_code VARCHAR(3) NOT NULL,
                         is_active BOOLEAN NOT NULL DEFAULT TRUE,
                         created_at TIMESTAMP NOT NULL DEFAULT NOW(),
                         updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 3. Seed 5 Test Rewards
INSERT INTO rewards (reward_type, title, description, worth, currency_code, is_active, created_at, updated_at)
VALUES
    (
        'POINTS',
        '500 ZPoints Milestone Bonus',
        'Earn 500 reward points credited directly to your ZGrow gamification balance upon completing savings challenges.',
        500.00,
        'PTS',
        true,
        NOW(),
        NOW()
    ),
    (
        'GIFT_BOX',
        'Bronze Mystery Box',
        'Unlock a mystery box containing random cashback vouchers and bonus points.',
        25.00,
        'USD',
        true,
        NOW(),
        NOW()
    ),
    (
        'CASHBACK',
        '1% Cashback Voucher',
        'Get 1% cashback on your next virtual card subscription or bill payment transaction.',
        10.00,
        'USD',
        true,
        NOW(),
        NOW()
    ),
    (
        'GIFT_BOX',
        'Gold VIP Saver Box',
        'High-tier mystery box awarded for completing 60-day wealth accumulation challenges.',
        100.00,
        'USD',
        true,
        NOW(),
        NOW()
    ),
    (
        'BADGE',
        'Early Investor Pioneer Badge',
        'Exclusive digital badge for early adopters investing in ZGrow pool options.',
        0.00,
        'USD',
        true,
        NOW(),
        NOW()
    );