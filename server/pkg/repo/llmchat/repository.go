package llmchat

import "database/sql"

// Repository defines the methods for inserting, updating and retrieving
// llmchat related keys and entities from the underlying repository
const zeroUUID = "00000000-0000-0000-0000-000000000000"

type Repository struct {
	DB *sql.DB
}
