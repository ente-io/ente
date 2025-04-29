CREATE TABLE IF NOT EXISTS users (
	user_id SERIAL PRIMARY KEY,
	email TEXT UNIQUE NOT NULL,
	name TEXT,
	creation_time BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS files (
	file_id BIGSERIAL PRIMARY KEY,
	owner_id INTEGER NOT NULL,
	file_decryption_header TEXT NOT NULL,
	thumbnail_decryption_header TEXT NOT NULL,
	metadata_decryption_header TEXT NOT NULL,
	encrypted_metadata TEXT NOT NULL,
	updation_time BIGINT NOT NULL,
	CONSTRAINT fk_files_owner_id 
		FOREIGN KEY(owner_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS file_object_keys (
	file_id BIGINT PRIMARY KEY,
	object_key TEXT UNIQUE NOT NULL,
	size INTEGER NOT NULL,
	CONSTRAINT fk_file_object_keys_file_id 
		FOREIGN KEY(file_id) 
			REFERENCES files(file_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS thumbnail_object_keys (
	file_id BIGINT PRIMARY KEY,
	object_key TEXT UNIQUE NOT NULL,
	size INTEGER NOT NULL,
	CONSTRAINT fk_thumbnail_object_keys_file_id 
		FOREIGN KEY(file_id) 
			REFERENCES files(file_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS temp_object_keys (
	object_key TEXT PRIMARY KEY NOT NULL,
	expiration_time BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS otts (
	user_id INTEGER NOT NULL,
	ott TEXT UNIQUE NOT NULL,
	creation_time BIGINT NOT NULL,
	expiration_time BIGINT NOT NULL,
	CONSTRAINT fk_otts_user_id 
		FOREIGN KEY(user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS tokens (
	user_id INTEGER NOT NULL,
	token TEXT UNIQUE NOT NULL,
	creation_time BIGINT NOT NULL,
	CONSTRAINT fk_tokens_user_id 
		FOREIGN KEY(user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS key_attributes (
	user_id INTEGER PRIMARY KEY,
	kek_salt TEXT NOT NULL,
	kek_hash_bytes BYTEA NOT NULL,
	encrypted_key TEXT NOT NULL,
	key_decryption_nonce TEXT NOT NULL,
	public_key TEXT NOT NULL,
	encrypted_secret_key TEXT NOT NULL,
	secret_key_decryption_nonce TEXT NOT NULL,
	CONSTRAINT fk_key_attributes_user_id 
		FOREIGN KEY(user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS collections (
	collection_id SERIAL PRIMARY KEY,
	owner_id INTEGER NOT NULL,
	encrypted_key TEXT NOT NULL,
	key_decryption_nonce TEXT NOT NULL,
	name TEXT NOT NULL,
	type TEXT NOT NULL,
	attributes JSONB NOT NULL,
	updation_time BIGINT NOT NULL,
	is_deleted BOOLEAN DEFAULT FALSE,
	CONSTRAINT fk_collections_owner_id 
		FOREIGN KEY(owner_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS collection_shares (
	collection_id INTEGER NOT NULL,
	from_user_id INTEGER NOT NULL,
	to_user_id INTEGER NOT NULL,
	encrypted_key TEXT NOT NULL,
	updation_time BIGINT NOT NULL,
	is_deleted BOOLEAN DEFAULT FALSE,
	UNIQUE(collection_id, from_user_id, to_user_id),
	CONSTRAINT fk_collection_shares_collection_id 
		FOREIGN KEY(collection_id) 
			REFERENCES collections(collection_id)
			ON DELETE CASCADE,
	CONSTRAINT fk_collection_shares_from_user_id 
		FOREIGN KEY(from_user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE,
	CONSTRAINT fk_collection_shares_to_user_id 
		FOREIGN KEY(to_user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS collection_files (
	file_id BIGINT NOT NULL,
	collection_id INTEGER NOT NULL,
	encrypted_key TEXT NOT NULL,
	key_decryption_nonce TEXT NOT NULL,
	is_deleted BOOLEAN DEFAULT FALSE,
	updation_time BIGINT NOT NULL,
	CONSTRAINT unique_collection_files_cid_fid UNIQUE(collection_id, file_id),
	CONSTRAINT fk_collection_files_collection_id 
		FOREIGN KEY(collection_id)
			REFERENCES collections(collection_id)
			ON DELETE CASCADE,
	CONSTRAINT fk_collection_files_file_id 
		FOREIGN KEY(file_id) 
			REFERENCES files(file_id)
			ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS users_email_index ON users(email);

CREATE INDEX IF NOT EXISTS files_owner_id_index ON files (owner_id);

CREATE INDEX IF NOT EXISTS files_updation_time_index ON files (updation_time);

CREATE INDEX IF NOT EXISTS otts_user_id_index ON otts (user_id);

CREATE INDEX IF NOT EXISTS tokens_user_id_index ON tokens (user_id);

CREATE INDEX IF NOT EXISTS collections_owner_id_index ON collections (owner_id);

CREATE INDEX IF NOT EXISTS collection_shares_to_user_id_index ON collection_shares (to_user_id);

CREATE INDEX IF NOT EXISTS collection_files_collection_id_index ON collection_files (collection_id);

CREATE UNIQUE INDEX IF NOT EXISTS collections_favorites_constraint_index ON collections (owner_id) WHERE (type = 'favorites');
