-- ZGrow challenges: replace challenge_participants with the two tables the
-- feature actually needs — each user's own challenge participation is
-- private to them (no cross-user visibility), so this is a plain
-- user_id/challenge_id join table per relationship, not a shared roster:
--
--  * user_challenges     — challenges a user has joined/accepted, with
--                          their own progress on that challenge.
--  * declined_challenges — challenges a user was offered and declined.
--                          Declining removes the row from user_challenges
--                          (if present) and records it here instead; the
--                          challenge still appears back in that user's
--                          "other challenges" list so they can rejoin later.
--
-- challenge_participants covered the same (user_id, challenge_id) join as
-- user_challenges below but was never used for anything beyond a derived
-- participant count — dropping it avoids keeping two tables for one
-- relationship (see the "one physical table per real-world concept" note
-- at the top of V1__init_schema.sql).
DROP TABLE IF EXISTS challenge_participants;

CREATE TABLE user_challenges (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    challenge_id      UUID NOT NULL REFERENCES challenges(challenge_id) ON DELETE CASCADE,
    progress_percent  SMALLINT NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
    completed_at      TIMESTAMPTZ,
    points_earned     INTEGER NOT NULL DEFAULT 0,
    joined_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, challenge_id)
);
CREATE INDEX idx_user_challenges_user ON user_challenges(user_id);
CREATE INDEX idx_user_challenges_challenge ON user_challenges(challenge_id);

CREATE TABLE declined_challenges (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    challenge_id      UUID NOT NULL REFERENCES challenges(challenge_id) ON DELETE CASCADE,
    declined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, challenge_id)
);
CREATE INDEX idx_declined_challenges_user ON declined_challenges(user_id);
