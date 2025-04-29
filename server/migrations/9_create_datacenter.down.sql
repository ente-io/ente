DROP TYPE s3region;

ALTER TABLE file_object_keys
    DROP COLUMN datacenters;

ALTER TABLE thumbnail_object_keys
    DROP COLUMN datacenters;

DROP TABLE task_lock;

DROP TABLE queue;
