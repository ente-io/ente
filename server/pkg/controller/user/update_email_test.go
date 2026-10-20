package user

import (
	"net/http/httptest"
	"testing"

	"github.com/ente/museum/ente"
	"github.com/ente/museum/internal/testutil"
	"github.com/ente/museum/pkg/controller"
	"github.com/ente/museum/pkg/repo"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/require"
)

func TestUpdateEmailRefreshesSharedCollections(t *testing.T) {
	testutil.WithServerRoot(t)
	db := testutil.RequireTestDB(t)
	testutil.ResetTables(t, db)
	t.Cleanup(func() { testutil.ResetTables(t, db) })

	ownerID := testutil.InsertUser(t, db, testutil.UserFixture{UserID: 1, Email: "owner@example.com", CreationTime: 1})
	shareeID := testutil.InsertUser(t, db, testutil.UserFixture{UserID: 2, Email: "sharee@example.com", CreationTime: 1})
	collectionRepo := &repo.CollectionRepository{DB: db}
	sharedWithSharee := createUpdateEmailTestCollection(t, collectionRepo, ownerID, &shareeID)
	sharedBySharee := createUpdateEmailTestCollection(t, collectionRepo, shareeID, &ownerID)
	notShared := createUpdateEmailTestCollection(t, collectionRepo, shareeID, nil)

	c := &UserController{
		UserRepo:               &repo.UserRepository{DB: db, SecretEncryptionKey: testutil.SecretEncryptionKey(), HashingKey: testutil.HashingKey()},
		CollectionRepo:         collectionRepo,
		BillingController:      &controller.BillingController{BillingRepo: &repo.BillingRepository{DB: db}},
		MailingListsController: &controller.MailingListsController{},
		SecretEncryptionKey:    testutil.SecretEncryptionKey(),
		HashingKey:             testutil.HashingKey(),
	}
	ctx, _ := gin.CreateTestContext(httptest.NewRecorder())
	require.NoError(t, c.UpdateEmail(ctx, shareeID, "new-sharee@example.com"))

	for collectionID, wantRefreshed := range map[int64]bool{sharedWithSharee: true, sharedBySharee: true, notShared: false} {
		var updationTime int64
		require.NoError(t, db.QueryRow(`SELECT updation_time FROM collections WHERE collection_id = $1`, collectionID).Scan(&updationTime))
		require.Equal(t, wantRefreshed, updationTime > 1, "collection %d", collectionID)
	}
}

func createUpdateEmailTestCollection(t *testing.T, collectionRepo *repo.CollectionRepository, ownerID int64, shareWith *int64) int64 {
	t.Helper()
	collection, err := collectionRepo.Create(ente.Collection{
		Owner:              ente.CollectionUser{ID: ownerID},
		EncryptedKey:       "encrypted-key",
		KeyDecryptionNonce: "key-nonce",
		Name:               "Test collection",
		Type:               "album",
		UpdationTime:       1,
		App:                string(ente.Photos),
	})
	require.NoError(t, err)
	if shareWith != nil {
		require.NoError(t, collectionRepo.Share(collection.ID, ownerID, *shareWith, "share-key", ente.VIEWER, 1))
	}
	return collection.ID
}
