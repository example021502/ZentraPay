-- In-app notifications for transaction outcomes (bank transfers, payments, etc).
-- Managed alongside the Hibernate-mapped NotificationModel entity.

CREATE TABLE IF NOT EXISTS notifications (
    notification_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL,
    title            VARCHAR(120) NOT NULL,
    message          VARCHAR(500) NOT NULL,
    type             VARCHAR(30) NOT NULL,
    reference_id     VARCHAR(100),
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
    ON notifications(user_id, created_at DESC);