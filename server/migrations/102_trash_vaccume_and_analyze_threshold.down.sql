ALTER TABLE trash RESET (
    autovacuum_analyze_scale_factor,
    autovacuum_vacuum_scale_factor,
    autovacuum_analyze_threshold,
    autovacuum_vacuum_threshold
    );