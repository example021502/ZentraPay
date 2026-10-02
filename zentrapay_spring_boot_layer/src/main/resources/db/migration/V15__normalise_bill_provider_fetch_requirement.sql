-- ============================================================
-- V15: normalise legacy bill_providers.fetch_requirement
--
-- BillProviderModel maps this column as
--   @JdbcTypeCode(SqlTypes.JSON)
--   List<Map<String, Object>> fetchRequirement
-- and ProviderSyncService writes it in that shape
-- (FlutterwaveBillProviderMapper):
--   List.of(Map.of("field", "customer_account", "label", "Customer account number"))
--
-- But the 10 rows seeded by V3__seed_providers.sql (carried over from the
-- retired Node layer) hold a JSON array of bare STRINGS:
--   ["METER_NUMBER"] / ["ACCOUNT_NUMBER"] / ["SMARTCARD_NUMBER"]
-- Hibernate's JSON type maps straight onto Jackson, so reading one of those
-- rows throws:
--   Could not deserialize string to java type:
--   java.util.List<java.util.Map<java.lang.String, java.lang.Object>>
-- That is a RuntimeException, so GlobalExceptionHandler turned it into a 400
-- and GET /api/search/search-contacts/{query} returned nothing at all for any
-- query that matched a bill provider.
--
-- Fix the DATA, not the entity: the entity type is the one the sync job
-- writes, so widening it to List<String> would break every future synced
-- row. Rewrite the legacy arrays into the object shape, keeping the original
-- gateway field code in `field` so nothing is lost, and derive a readable
-- `label` from it.
--
-- Only touches arrays whose FIRST element is a string, so it is a no-op on
-- rows already written by the sync job.
-- ============================================================

UPDATE bill_providers
SET fetch_requirement = (
    SELECT jsonb_agg(
        jsonb_build_object(
            'field', elem.value,
            'label', initcap(replace(elem.value, '_', ' '))
        )
        ORDER BY elem.ord
    )
    FROM jsonb_array_elements_text(fetch_requirement) WITH ORDINALITY AS elem(value, ord)
)
WHERE jsonb_typeof(fetch_requirement) = 'array'
  AND jsonb_array_length(fetch_requirement) > 0
  AND jsonb_typeof(fetch_requirement -> 0) = 'string';

-- Anything that is not a valid array (null / scalar / object) cannot be read
-- into a List either; normalise those to an empty array.
UPDATE bill_providers
SET fetch_requirement = '[]'::jsonb
WHERE fetch_requirement IS NULL
   OR jsonb_typeof(fetch_requirement) <> 'array';
