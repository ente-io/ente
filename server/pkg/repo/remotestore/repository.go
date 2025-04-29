package remotestore

import (
	"context"
	"database/sql"

	"github.com/ente-io/stacktrace"
)

// Repository defines the methods for inserting, updating and retrieving
// remote store key and values
type Repository struct {
	DB *sql.DB
}

func (r *Repository) InsertOrUpdate(ctx context.Context, userID int64, key string, value string) error {
	_, err := r.DB.ExecContext(ctx, `INSERT INTO remote_store(user_id, key_name, key_value) VALUES ($1,$2,$3)
						 ON CONFLICT (user_id, key_name) DO UPDATE SET key_value = $3;
						 `,
		userID, //$1 user_id
		key,    // $2 key_name
		value,  // $3 key_value
	)
	return stacktrace.Propagate(err, "failed to insert/update")
}

// GetValue fetches and return the value for given user_id and key
func (r *Repository) GetValue(ctx context.Context, userID int64, key string) (string, error) {
	rows := r.DB.QueryRowContext(ctx, `SELECT key_value FROM remote_store
	   WHERE user_id = $1
	   and key_name = $2`,
		userID, // $1
		key,    // %2
	)
	var keyValue string
	err := rows.Scan(&keyValue)
	if err != nil {
		return keyValue, stacktrace.Propagate(err, "reading value failed")
	}
	return keyValue, nil
}

// GetAllValues fetches and return all the key value pairs for given user_id
func (r *Repository) GetAllValues(ctx context.Context, userID int64) (map[string]string, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT key_name, key_value FROM remote_store
	   WHERE user_id = $1`,
		userID, // $1
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "reading value failed")
	}
	defer rows.Close()
	values := make(map[string]string)
	for rows.Next() {
		var key, value string
		err := rows.Scan(&key, &value)
		if err != nil {
			return nil, stacktrace.Propagate(err, "reading value failed")
		}
		values[key] = value
	}
	return values, nil
}
