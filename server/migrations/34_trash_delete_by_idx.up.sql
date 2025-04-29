CREATE INDEX trash_delete_by_idx ON trash (delete_by)
    WHERE (trash.is_deleted is FALSE AND trash.is_restored is FALSE);
