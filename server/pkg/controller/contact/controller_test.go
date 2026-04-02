package contact

import (
	"database/sql"
	"errors"
	"net/http/httptest"
	"strings"
	"testing"

	contactmodel "github.com/ente-io/museum/ente/contact"
	"github.com/ente-io/museum/internal/testutil"
	basecontroller "github.com/ente-io/museum/pkg/controller"
	repo "github.com/ente-io/museum/pkg/repo"
	contactrepo "github.com/ente-io/museum/pkg/repo/contact"
	"github.com/ente-io/museum/pkg/utils/config"
	"github.com/ente-io/museum/pkg/utils/s3config"
	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
)

func setupContactControllerTest(t *testing.T) (*Controller, *sql.DB, *gin.Context, *s3config.S3Config) {
	t.Helper()

	testutil.WithServerRoot(t)
	viper.Reset()
	if err := config.ConfigureViper("local"); err != nil {
		t.Fatalf("failed to configure viper: %v", err)
	}
	t.Cleanup(viper.Reset)

	db := testutil.RequireTestDB(t)
	testutil.ResetTables(t, db)
	t.Cleanup(func() {
		testutil.ResetTables(t, db)
	})

	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	ctx, _ := gin.CreateTestContext(recorder)
	ctx.Request = httptest.NewRequest("GET", "/", nil)
	ctx.Request.Header.Set("X-Auth-User-ID", "1")

	s3Cfg := s3config.NewS3Config()
	objectCleanupRepo := &repo.ObjectCleanupRepository{DB: db}
	objectCleanupCtrl := &basecontroller.ObjectCleanupController{Repo: objectCleanupRepo}
	contactRepository := &contactrepo.Repository{
		DB:                db,
		ObjectCleanupRepo: objectCleanupRepo,
	}
	ctrl := New(contactRepository, objectCleanupCtrl, s3Cfg)
	return ctrl, db, ctx, s3Cfg
}

func createContactForTest(t *testing.T, ctrl *Controller, ctx *gin.Context, contactUserID int64, encryptedKey string, encryptedData string) *contactmodel.Entity {
	t.Helper()
	entity, err := ctrl.Create(ctx, contactmodel.CreateRequest{
		ContactUserID: contactUserID,
		EncryptedKey:  []byte(encryptedKey),
		EncryptedData: []byte(encryptedData),
	})
	if err != nil {
		t.Fatalf("Create() error = %v", err)
	}
	return entity
}

func mustInsertTestUser(t *testing.T, db *sql.DB, userID int64) {
	t.Helper()
	testutil.InsertUser(t, db, testutil.UserFixture{
		UserID:       userID,
		Email:        "contacts-owner@ente.io",
		CreationTime: 1,
	})
}

func TestContactCRUDAndDiff(t *testing.T) {
	ctrl, db, ctx, _ := setupContactControllerTest(t)
	mustInsertTestUser(t, db, 1)

	created := createContactForTest(t, ctrl, ctx, 11, "wrapped-key-1", "payload-1")
	if !strings.HasPrefix(created.ID, "ct_") {
		t.Fatalf("contact id = %q, want ct_ prefix", created.ID)
	}
	if created.ContactUserID != 11 {
		t.Fatalf("contactUserID = %d, want 11", created.ContactUserID)
	}
	if created.EncryptedKey == nil || string(*created.EncryptedKey) != "wrapped-key-1" {
		t.Fatalf("unexpected encrypted key: %v", created.EncryptedKey)
	}

	got, err := ctrl.Get(ctx, created.ID)
	if err != nil {
		t.Fatalf("Get() error = %v", err)
	}
	if got.ID != created.ID {
		t.Fatalf("Get().ID = %q, want %q", got.ID, created.ID)
	}

	updated, err := ctrl.Update(ctx, created.ID, contactmodel.UpdateRequest{
		ContactUserID: 12,
		EncryptedData: []byte("payload-2"),
	})
	if err != nil {
		t.Fatalf("Update() error = %v", err)
	}
	if updated.ContactUserID != 12 {
		t.Fatalf("updated contactUserID = %d, want 12", updated.ContactUserID)
	}
	if updated.EncryptedData == nil || string(*updated.EncryptedData) != "payload-2" {
		t.Fatalf("updated encrypted data = %v", updated.EncryptedData)
	}

	diff, err := ctrl.GetDiff(ctx, contactmodel.DiffRequest{
		SinceTime: ptrInt64(0),
		Limit:     10,
	})
	if err != nil {
		t.Fatalf("GetDiff() error = %v", err)
	}
	if len(diff) != 1 {
		t.Fatalf("diff length = %d, want 1", len(diff))
	}
	if diff[0].ID != created.ID || diff[0].ContactUserID != 12 {
		t.Fatalf("unexpected diff row: %+v", diff[0])
	}

	if err := ctrl.Delete(ctx, created.ID); err != nil {
		t.Fatalf("Delete() error = %v", err)
	}
	deleted, err := ctrl.Get(ctx, created.ID)
	if err != nil {
		t.Fatalf("Get() after delete error = %v", err)
	}
	if !deleted.IsDeleted {
		t.Fatalf("deleted contact should be tombstoned")
	}
	if deleted.EncryptedKey != nil || deleted.EncryptedData != nil || deleted.ProfilePictureAttachmentID != nil {
		t.Fatalf("deleted contact leaked encrypted fields or attachment ref: %+v", deleted)
	}
}

func TestCreateContactRejectsDuplicateContactUserID(t *testing.T) {
	ctrl, db, ctx, _ := setupContactControllerTest(t)
	mustInsertTestUser(t, db, 1)

	createContactForTest(t, ctrl, ctx, 21, "wrapped-key-1", "payload-1")
	_, err := ctrl.Create(ctx, contactmodel.CreateRequest{
		ContactUserID: 21,
		EncryptedKey:  []byte("wrapped-key-2"),
		EncryptedData: []byte("payload-2"),
	})
	if err == nil {
		t.Fatal("expected duplicate contactUserID create to fail")
	}
}

func TestContactEntityEncryptedKeyIsImmutable(t *testing.T) {
	ctrl, db, ctx, _ := setupContactControllerTest(t)
	mustInsertTestUser(t, db, 1)

	created := createContactForTest(t, ctrl, ctx, 31, "wrapped-key-1", "payload-1")
	if _, err := db.Exec(`UPDATE contact_entity SET encrypted_key = $1 WHERE id = $2`, []byte("wrapped-key-2"), created.ID); err == nil {
		t.Fatal("expected encrypted_key update to fail")
	}
}

func TestDeletedContactMustClearProfilePictureReference(t *testing.T) {
	ctrl, db, ctx, _ := setupContactControllerTest(t)
	mustInsertTestUser(t, db, 1)

	created := createContactForTest(t, ctrl, ctx, 35, "wrapped-key-1", "payload-1")
	if _, err := db.Exec(
		`UPDATE contact_entity
		    SET is_deleted = TRUE, encrypted_data = NULL, profile_picture_attachment_id = $1
		  WHERE id = $2`,
		"ua_fakeAttachment",
		created.ID,
	); err == nil {
		t.Fatal("expected deleted contact with profile picture ref to violate constraint")
	}
}

func TestUserAttachmentsRejectDuplicateBucketMembership(t *testing.T) {
	_, db, _, _ := setupContactControllerTest(t)
	mustInsertTestUser(t, db, 1)

	_, err := db.Exec(
		`INSERT INTO user_attachments(
		    attachment_id, user_id, attachment_type, size, latest_bucket, replicated_buckets
		) VALUES($1, $2, $3, $4, $5, ARRAY[$6]::s3region[])`,
		"ua_duplicateBuckets",
		1,
		"profile_picture",
		128,
		"b2-eu-cen",
		"b2-eu-cen",
	)
	if err == nil {
		t.Fatal("expected duplicate attachment bucket membership to fail")
	}
}

func TestProfilePictureLifecycle(t *testing.T) {
	ctrl, db, ctx, s3Cfg := setupContactControllerTest(t)
	mustInsertTestUser(t, db, 1)

	created := createContactForTest(t, ctrl, ctx, 41, "wrapped-key-1", "payload-1")

	upload1, err := ctrl.GetProfilePictureUploadURL(ctx, created.ID, contactmodel.ProfilePictureUploadURLRequest{
		ContentLength: 128,
		ContentMD5:    "ZmFrZS1tZDU=",
	})
	if err != nil {
		t.Fatalf("GetProfilePictureUploadURL() error = %v", err)
	}
	if !strings.HasPrefix(upload1.AttachmentID, "ua_") {
		t.Fatalf("attachment id = %q, want ua_ prefix", upload1.AttachmentID)
	}

	objectKey1 := contactmodel.AttachmentObjectKey(1, contactmodel.ProfilePicture, upload1.AttachmentID)
	var bucketID string
	if err := db.QueryRow(`SELECT bucket_id FROM temp_objects WHERE object_key = $1`, objectKey1).Scan(&bucketID); err != nil {
		t.Fatalf("temp_objects lookup failed: %v", err)
	}
	if bucketID != s3Cfg.GetAttachmentBucketID(string(contactmodel.ProfilePicture)) {
		t.Fatalf("bucket_id = %q, want %q", bucketID, s3Cfg.GetAttachmentBucketID(string(contactmodel.ProfilePicture)))
	}

	withPicture, err := ctrl.AttachProfilePicture(ctx, created.ID, contactmodel.CommitProfilePictureRequest{
		AttachmentID: upload1.AttachmentID,
		Size:         128,
	})
	if err != nil {
		t.Fatalf("AttachProfilePicture() error = %v", err)
	}
	if withPicture.ProfilePictureAttachmentID == nil || *withPicture.ProfilePictureAttachmentID != upload1.AttachmentID {
		t.Fatalf("unexpected profile picture ref after attach: %+v", withPicture)
	}
	if err := db.QueryRow(`SELECT bucket_id FROM temp_objects WHERE object_key = $1`, objectKey1).Scan(&bucketID); !errors.Is(err, sql.ErrNoRows) {
		t.Fatalf("temp_objects row should be removed after attach, got err=%v bucket=%q", err, bucketID)
	}

	signedURL, err := ctrl.GetProfilePictureURL(ctx, created.ID)
	if err != nil {
		t.Fatalf("GetProfilePictureURL() error = %v", err)
	}
	if signedURL.URL == "" {
		t.Fatal("expected signed profile picture url")
	}

	upload2, err := ctrl.GetProfilePictureUploadURL(ctx, created.ID, contactmodel.ProfilePictureUploadURLRequest{
		ContentLength: 256,
		ContentMD5:    "ZmFrZS1tZDUtMg==",
	})
	if err != nil {
		t.Fatalf("second GetProfilePictureUploadURL() error = %v", err)
	}
	replaced, err := ctrl.AttachProfilePicture(ctx, created.ID, contactmodel.CommitProfilePictureRequest{
		AttachmentID: upload2.AttachmentID,
		Size:         256,
	})
	if err != nil {
		t.Fatalf("second AttachProfilePicture() error = %v", err)
	}
	if replaced.ProfilePictureAttachmentID == nil || *replaced.ProfilePictureAttachmentID != upload2.AttachmentID {
		t.Fatalf("unexpected profile picture ref after replace: %+v", replaced)
	}

	oldAttachment, err := ctrl.Repo.GetAttachment(ctx, 1, upload1.AttachmentID)
	if err != nil {
		t.Fatalf("GetAttachment(old) error = %v", err)
	}
	if !oldAttachment.IsDeleted {
		t.Fatalf("old attachment should be marked deleted after replace")
	}

	cleared, err := ctrl.DeleteProfilePicture(ctx, created.ID)
	if err != nil {
		t.Fatalf("DeleteProfilePicture() error = %v", err)
	}
	if cleared.ProfilePictureAttachmentID != nil {
		t.Fatalf("profile picture should be cleared, got %+v", cleared.ProfilePictureAttachmentID)
	}
	newAttachment, err := ctrl.Repo.GetAttachment(ctx, 1, upload2.AttachmentID)
	if err != nil {
		t.Fatalf("GetAttachment(new) error = %v", err)
	}
	if !newAttachment.IsDeleted {
		t.Fatalf("current attachment should be marked deleted after picture removal")
	}
}

func TestDeleteContactMarksCurrentProfilePictureDeleted(t *testing.T) {
	ctrl, db, ctx, _ := setupContactControllerTest(t)
	mustInsertTestUser(t, db, 1)

	created := createContactForTest(t, ctrl, ctx, 51, "wrapped-key-1", "payload-1")
	upload, err := ctrl.GetProfilePictureUploadURL(ctx, created.ID, contactmodel.ProfilePictureUploadURLRequest{
		ContentLength: 128,
		ContentMD5:    "ZmFrZS1tZDU=",
	})
	if err != nil {
		t.Fatalf("GetProfilePictureUploadURL() error = %v", err)
	}
	withPicture, err := ctrl.AttachProfilePicture(ctx, created.ID, contactmodel.CommitProfilePictureRequest{
		AttachmentID: upload.AttachmentID,
		Size:         128,
	})
	if err != nil {
		t.Fatalf("AttachProfilePicture() error = %v", err)
	}
	if withPicture.ProfilePictureAttachmentID == nil {
		t.Fatal("expected profile picture ref before delete")
	}

	if err := ctrl.Delete(ctx, created.ID); err != nil {
		t.Fatalf("Delete() error = %v", err)
	}
	attachment, err := ctrl.Repo.GetAttachment(ctx, 1, upload.AttachmentID)
	if err != nil {
		t.Fatalf("GetAttachment() error = %v", err)
	}
	if !attachment.IsDeleted {
		t.Fatalf("attachment should be marked deleted when contact is deleted")
	}
	deleted, err := ctrl.Get(ctx, created.ID)
	if err != nil {
		t.Fatalf("Get() after delete error = %v", err)
	}
	if deleted.ProfilePictureAttachmentID != nil {
		t.Fatalf("deleted contact should not reference profile picture")
	}
}

func ptrInt64(v int64) *int64 {
	return &v
}
