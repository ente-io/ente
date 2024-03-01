CREATE UNIQUE INDEX IF NOT EXISTS sub_original_txn_id_index 
ON subscriptions (original_transaction_id) 
WHERE original_transaction_id is not null and original_transaction_id != 'none';
