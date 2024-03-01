package authenticator

import (
	"database/sql"
)

// Repository defines the methods for inserting, updating and retrieving
// authenticator related keys and entities from the underlying repository
type Repository struct {
	DB *sql.DB
}
