package social

import (
	"database/sql"
	"testing"

	"github.com/ente/museum/internal/testutil"
	"github.com/stretchr/testify/require"
)

func TestGetDiffKeepsTimestampGroupsTogether(t *testing.T) {
	ctx := t.Context()
	db := testutil.RequireTestDB(t)
	collectionID := int64(9_000_001)
	commentsRepo := &CommentsRepository{DB: db}
	reactionsRepo := &ReactionsRepository{DB: db}

	tables := []struct {
		name string
		diff func(since int64, fileID *int64) ([]string, bool, error)
	}{
		{
			name: "comments",
			diff: func(since int64, fileID *int64) ([]string, bool, error) {
				comments, hasMore, err := commentsRepo.GetDiff(ctx, collectionID, since, 2, fileID)
				ids := make([]string, 0, len(comments))
				for _, comment := range comments {
					ids = append(ids, comment.ID)
				}
				return ids, hasMore, err
			},
		},
		{
			name: "reactions",
			diff: func(since int64, fileID *int64) ([]string, bool, error) {
				reactions, hasMore, err := reactionsRepo.GetDiff(ctx, collectionID, since, 2, fileID, nil)
				ids := make([]string, 0, len(reactions))
				for _, reaction := range reactions {
					ids = append(ids, reaction.ID)
				}
				return ids, hasMore, err
			},
		},
	}

	for _, table := range tables {
		t.Run(table.name, func(t *testing.T) {
			insertDiffTestRows(t, db, table.name, collectionID)

			ids, hasMore, err := table.diff(0, nil)
			require.NoError(t, err)
			require.ElementsMatch(t, []string{"a"}, ids)
			require.True(t, hasMore)

			ids, hasMore, err = table.diff(100, nil)
			require.NoError(t, err)
			require.ElementsMatch(t, []string{"b1", "b2", "b3", "other"}, ids)
			require.True(t, hasMore)

			fileID := int64(1)
			ids, hasMore, err = table.diff(100, &fileID)
			require.NoError(t, err)
			require.ElementsMatch(t, []string{"b1", "b2", "b3"}, ids)
			require.True(t, hasMore)

			ids, hasMore, err = table.diff(200, nil)
			require.NoError(t, err)
			require.ElementsMatch(t, []string{"c"}, ids)
			require.False(t, hasMore)
		})
	}
}

func insertDiffTestRows(t *testing.T, db *sql.DB, table string, collectionID int64) {
	t.Helper()
	deleteRows := func() {
		_, err := db.Exec(`DELETE FROM `+table+` WHERE collection_id = $1`, collectionID)
		require.NoError(t, err)
	}
	deleteRows()
	t.Cleanup(deleteRows)

	rows := []struct {
		id        string
		fileID    int64
		updatedAt int64
	}{
		{"a", 1, 100},
		{"b1", 1, 200},
		{"b2", 1, 200},
		{"b3", 1, 200},
		{"other", 2, 200},
		{"c", 1, 300},
	}
	for i, row := range rows {
		_, err := db.Exec(`INSERT INTO `+table+` (id, collection_id, file_id, user_id, cipher, nonce, created_at, updated_at)
			VALUES ($1, $2, $3, $4, 'cipher', 'nonce', $5, $5)`,
			row.id, collectionID, row.fileID, i+1, row.updatedAt)
		require.NoError(t, err)
	}
}
