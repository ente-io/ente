package contact

import (
	"database/sql"

	"github.com/ente-io/museum/pkg/repo"
)

type Repository struct {
	DB                *sql.DB
	ObjectCleanupRepo *repo.ObjectCleanupRepository
}
