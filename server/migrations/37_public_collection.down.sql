DROP TABLE IF EXISTS public_abuse_report;
DROP INDEX IF EXISTS public_abuse_share_id_idx;

DROP TABLE IF EXISTS public_collection_access_history;
DROP INDEX IF EXISTS public_access_share_id_idx;


DROP TABLE IF EXISTS public_collection_tokens;
DROP INDEX IF EXISTS public_access_tokens_unique_idx;
DROP INDEX IF EXISTS public_active_collection_unique_idx;

DROP TRIGGER IF EXISTS update_public_collection_tokens_updated_at on public_collection_tokens;
DROP TRIGGER IF EXISTS trigger_collection_updation_time_on_collection_tokens_updated on public_collection_tokens;
