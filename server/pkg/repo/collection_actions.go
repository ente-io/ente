package repo

import (
    "context"
    "database/sql"
    "encoding/json"

    "github.com/ente-io/museum/ente"
    "github.com/ente-io/museum/ente/base"
    "github.com/ente-io/stacktrace"
)

type CollectionActionsRepository struct {
    DB *sql.DB
}

func (r *CollectionActionsRepository) Create(ctx context.Context, userID int64, actorUserID int64, collectionID int64, fileID *int64, data map[string]interface{}, action string, isPending bool, now int64) (string, error) {
    id := base.MustNewID("cact")
    var payload []byte
    var err error
    if data != nil {
        payload, err = json.Marshal(data)
        if err != nil {
            return "", stacktrace.Propagate(err, "failed to marshal collection action data")
        }
    }
    _, err = r.DB.ExecContext(ctx, `INSERT INTO collection_actions(id, user_id, actor_user_id, collection_id, file_id, data, action, is_pending, created_at, updated_at)
            VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $9)`, id, userID, actorUserID, collectionID, fileID, payload, action, isPending, now)
    return id, stacktrace.Propagate(err, "")
}

func (r *CollectionActionsRepository) ListForUser(ctx context.Context, userID int64, since int64, limit int) ([]ente.CollectionAction, error) {
    rows, err := r.DB.QueryContext(ctx, `SELECT id, user_id, actor_user_id, collection_id, file_id, data, action, is_pending, created_at, updated_at
            FROM collection_actions WHERE user_id = $1 AND created_at > $2 ORDER BY created_at LIMIT $3`, userID, since, limit)
    if err != nil {
        return nil, stacktrace.Propagate(err, "")
    }
    defer rows.Close()
    result := make([]ente.CollectionAction, 0)
    for rows.Next() {
        var (
            ca   ente.CollectionAction
            data []byte
            fileID sql.NullInt64
        )
        if err := rows.Scan(&ca.ID, &ca.UserID, &ca.ActorUserID, &ca.CollectionID, &fileID, &data, &ca.Action, &ca.IsPending, &ca.CreatedAt, &ca.UpdatedAt); err != nil {
            return result, stacktrace.Propagate(err, "")
        }
        if fileID.Valid {
            v := fileID.Int64
            ca.FileID = &v
        }
        if data != nil && len(data) > 0 {
            var m map[string]interface{}
            if err := json.Unmarshal(data, &m); err != nil {
                return result, stacktrace.Propagate(err, "failed to unmarshal data")
            }
            ca.Data = m
        }
        result = append(result, ca)
    }
    return result, nil
}
