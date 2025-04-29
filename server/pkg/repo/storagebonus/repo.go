package storagebonus

import (
	"database/sql"
)

// Repository defines the methods for inserting, updating and retrieving
// authenticator related keys and entities from the underlying repository
type Repository struct {
	DB *sql.DB
}

// NewRepository returns a new instance of Repository
func NewRepository(db *sql.DB) *Repository {
	return &Repository{
		DB: db,
	}
}
