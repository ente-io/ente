CREATE TABLE IF NOT EXISTS collection_actions (
    id TEXT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    actor_user_id BIGINT NOT NULL,
    collection_id BIGINT NOT NULL,
    file_id BIGINT,
    data JSONB,
    action TEXT NOT NULL,
    is_pending BOOLEAN NOT NULL DEFAULT TRUE,
    created_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT collection_actions_file_required CHECK (
        (action IN ('REMOVE','DELETE_SUGGESTED') AND file_id IS NOT NULL)
        OR (action NOT IN ('REMOVE','DELETE_SUGGESTED'))
    )
);

CREATE INDEX IF NOT EXISTS collection_actions_user_id_idx ON collection_actions (user_id);
CREATE INDEX IF NOT EXISTS collection_actions_collection_id_idx ON collection_actions (collection_id);
