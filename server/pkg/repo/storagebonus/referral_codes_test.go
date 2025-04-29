package storagebonus

// Unittest cases for storagebonus code repository

import (
	"context"
	"database/sql"
	"errors"
	"testing"

	entity "github.com/ente-io/museum/ente/storagebonus"
	_ "github.com/golang-migrate/migrate/v4/source/file"

	"github.com/stretchr/testify/assert"
)

// TestGetReferralCode tests the GetCode method
func TestGetReferralCode(t *testing.T) {
	ctx := context.Background()
	repo := NewRepository(db)
	// Test for a user that doesn't have a storagebonus code
	userID := int64(1)
	code, err := repo.GetCode(ctx, userID)
	assert.Nil(t, code)
	assert.Equal(t, sql.ErrNoRows, errors.Unwrap(err))

	// Insert a storagebonus code
	newCode := "AABBCC"
	err = repo.InsertCode(ctx, userID, newCode)
	assert.Nil(t, err)

	// Test for when storagebonus code already exists
	err = repo.InsertCode(ctx, userID, newCode)
	assert.Error(t, err)
	err = errors.Unwrap(err)
	// verify that error is of type pq.Error
	assert.Equal(t, entity.CodeAlreadyExistsErr, err)

	// Test for a user that has a storagebonus code
	code, err = repo.GetCode(ctx, userID)
	assert.Nil(t, err)
	assert.Equal(t, code, code)
}

// TestInsertReferralCode tests the InsertCode method
func TestInsertReferralCode(t *testing.T) {
	repo := NewRepository(db)
	// Insert a referral code
	userID := int64(2)
	code := "AAEEDD"
	err := repo.InsertCode(context.Background(), userID, code)
	assert.Nil(t, err)

	codeNew, err := repo.GetCode(context.Background(), userID)
	assert.Nil(t, err)
	assert.Equal(t, code, *codeNew)
}

// TestAddNewReferralCode tests the AddNewCode method
func TestAddNewReferralCode(t *testing.T) {
	repo := NewRepository(db)
	userID := int64(3)
	code := "B22222"
	err := repo.InsertCode(context.Background(), userID, code)
	assert.Nil(t, err)

	newCode := "C22222"
	err = repo.AddNewCode(context.Background(), userID, newCode, false)
	assert.Nil(t, err)

	referralCode, err := repo.GetCode(context.Background(), userID)
	assert.Nil(t, err)
	assert.Equal(t, newCode, *referralCode)

}
