CREATE UNIQUE INDEX IF NOT EXISTS remote_store_custom_domain_unique_idx
    ON remote_store (key_value)
    WHERE key_name = 'customDomain';
