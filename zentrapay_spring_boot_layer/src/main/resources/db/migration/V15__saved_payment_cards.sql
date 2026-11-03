-- V15: saved payment cards (card tokenization).
--
-- After a user pays a top-up with a card and ticks "Save this card", the gateway (Paystack / Flutterwave)
-- hands back a reusable token. We keep ONLY that token (encrypted by the app) plus the display details the
-- gateway shows on a receipt: last 4 digits, brand, expiry, issuing bank. The card number and CVV never
-- reach ZentraPay - they are typed into the gateway's own checkout.
--
-- Not to be confused with `user_cards` (ZentraPay's own virtual cards).
CREATE TABLE IF NOT EXISTS saved_cards (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL,
    gateway character varying(20) NOT NULL,
    token_encrypted text NOT NULL,
    -- the gateway's fingerprint of the card: the same card saved twice is stored once
    signature character varying(120) NOT NULL,
    last4 character varying(4) NOT NULL,
    brand character varying(30),
    card_type character varying(30),
    bank character varying(100),
    exp_month integer,
    exp_year integer,
    country_code character varying(3),
    is_default boolean DEFAULT false NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE' NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    last_used_at timestamp without time zone,
    CONSTRAINT saved_cards_gateway_check CHECK (gateway IN ('PAYSTACK', 'FLUTTERWAVE')),
    CONSTRAINT saved_cards_status_check CHECK (status IN ('ACTIVE', 'REMOVED')),
    CONSTRAINT saved_cards_unique_card UNIQUE (user_id, gateway, signature)
);

CREATE INDEX IF NOT EXISTS idx_saved_cards_user ON saved_cards USING btree (user_id, status);
