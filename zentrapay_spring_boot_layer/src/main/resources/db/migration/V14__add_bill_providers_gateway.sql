-- ============================================================
-- V14: bill_providers.gateway
--
-- BillProviderModel maps `gateway` as
--   @Column(name = "gateway", nullable = false) private String gateway;
-- but no migration ever created the column — V7 aligned
-- bill_providers on channel_code / is_crossborder_allowed / active
-- and missed it. It was only ever added by Hibernate ddl-auto=update,
-- which silently failed on this table with:
--   ERROR: column "gateway" of relation "bill_providers" contains
--   null values
-- because the column was added NOT NULL with no default against rows
-- that already existed.
--
-- Consequence: EVERY query touching BillProviderModel fails with
--   ERROR: column bpm1_0.gateway does not exist
-- which surfaces as
--   InvalidDataAccessResourceUsageException (a RuntimeException)
-- -> GlobalExceptionHandler.handleRuntimeException -> HTTP 400.
-- That is why GET /api/search/search-contacts/{query} returned 400 and
-- NO contacts at all: SearchContactsService queries bill providers
-- before assembling the response, so the whole call aborted.
--
-- Values written by the sync mappers are gateway slugs
-- (FlutterwaveBillProviderMapper -> "flutterwave", plus paystack /
-- onafriq elsewhere), matching the banks.gateway convention. The rows
-- already in the table are all legacy Flutterwave seed data from
-- V3__seed_providers.sql (ECG, GWCL, DSTV, ...), so they backfill to
-- "flutterwave".
--
-- Idempotent: safe on a database that already has the column.
-- ============================================================

ALTER TABLE bill_providers ADD COLUMN IF NOT EXISTS gateway VARCHAR(30);

-- Backfill before the NOT NULL is enforced, otherwise the SET NOT NULL
-- below fails on pre-existing rows.
UPDATE bill_providers SET gateway = 'flutterwave' WHERE gateway IS NULL;

ALTER TABLE bill_providers ALTER COLUMN gateway SET DEFAULT 'flutterwave';
ALTER TABLE bill_providers ALTER COLUMN gateway SET NOT NULL;