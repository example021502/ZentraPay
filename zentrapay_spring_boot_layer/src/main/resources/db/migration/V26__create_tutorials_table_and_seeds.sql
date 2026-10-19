-- ============================================================
-- V26: CREATE TUTORIALS LOOKUP TABLE + SEEDS
--
-- Why this exists (repair context): `TutorialsModel` maps
-- `@Table(name = "tutorials")`, but no V1–V25 migration EVER created
-- that table — so with Flyway owning the schema the only places the
-- table could come from were Hibernate auto-DDL (which you run in
-- `update`, so table creation was luck-dependent and never seeded)
-- or hand-created dev state. That is why GET /api/zgrow/tutorials
-- returns 500/empty on some machines and the Learn & Earn carousel
-- never appears: nothing guarantees the table OR the rows.
--
-- The shape below mirrors the entity field-for-field
-- (id, title, type, description, video_url, thumbnail_url,
-- duration_seconds, is_active, created_at, updated_at) and seeds the
-- same catalog the entity's DTO was written for, so the endpoint
-- works on a fresh database with zero hand-setup.
-- ============================================================

CREATE TABLE IF NOT EXISTS tutorials (
    id                INT NOT NULL,
    title             VARCHAR(255) NOT NULL,
    type              VARCHAR(50) NOT NULL,
    description       TEXT NOT NULL,
    video_url         VARCHAR(500) NOT NULL,
    thumbnail_url     VARCHAR(500) NOT NULL,
    duration_seconds  INT NOT NULL,
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_tutorials PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS idx_tutorials_type ON tutorials(type);
CREATE INDEX IF NOT EXISTS idx_tutorials_active ON tutorials(is_active);

COMMENT ON TABLE tutorials IS
    'Learn & Earn catalog behind GET /api/zgrow/tutorials (created in V26 because no earlier migration ever defined it).';

-- Seed catalog (fixed ids, insert-only-when-missing so repair runs
-- can never duplicate rows).
INSERT INTO tutorials (id, title, type, description, video_url, thumbnail_url, duration_seconds, is_active, created_at, updated_at)
VALUES
    (1, 'Budgeting Basics: The 50/30/20 Rule', 'BUDGETING',
     'Split every paycheck into needs, wants and savings with the classic 50/30/20 rule — with a GHS example budget you can copy.',
     'https://videos.zentrapay.app/tutorials/budgeting-50-30-20.mp4',
     'https://images.zentrapay.app/tutorials/budgeting-50-30-20.png',
     240, true, NOW(), NOW()),
    (2, 'Start Your Emergency Fund', 'SAVING',
     'Why three months of expenses matters, and how GHS 10 a day gets you to your first GHS 1,000 cushion.',
     'https://videos.zentrapay.app/tutorials/emergency-fund.mp4',
     'https://images.zentrapay.app/tutorials/emergency-fund.png',
     180, true, NOW(), NOW()),
    (3, 'Investing 101: Risk vs Return', 'INVESTING',
     'Stocks, bonds, treasury bills and money-market funds explained in plain language — plus how risk grows with return.',
     'https://videos.zentrapay.app/tutorials/investing-101.mp4',
     'https://images.zentrapay.app/tutorials/investing-101.png',
     300, true, NOW(), NOW()),
    (4, 'Kill Bad Debt First', 'DEBT_MANAGEMENT',
     'The avalanche vs snowball payoff methods, and a worked example clearing a GHS 2,000 balance.',
     'https://videos.zentrapay.app/tutorials/debt-payoff.mp4',
     'https://images.zentrapay.app/tutorials/debt-payoff.png',
     210, true, NOW(), NOW()),
    (5, 'Plan Your Money Year', 'FINANCIAL_PLANNING',
     'Set one-year money goals, automate transfers on payday, and review quarterly — a complete annual planning walkthrough.',
     'https://videos.zentrapay.app/tutorials/money-plan-year.mp4',
     'https://images.zentrapay.app/tutorials/money-plan-year.png',
     260, true, NOW(), NOW()),
    (6, 'Grow With ZentaPay: App Tour', 'GENERAL',
     'A two-minute tour of wallets, transfers, challenges and rewards inside the ZentaPay app.',
     'https://videos.zentrapay.app/tutorials/app-tour.mp4',
     'https://images.zentrapay.app/tutorials/app-tour.png',
     120, true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;
