ALTER TABLE trash SET (
    autovacuum_analyze_scale_factor = 0.01,  -- Trigger ANALYZE after 1% of rows change
    autovacuum_vacuum_scale_factor = 0.02,   -- Trigger VACUUM after 2% of rows change
    autovacuum_analyze_threshold = 1000,
    autovacuum_vacuum_threshold = 1000
);
