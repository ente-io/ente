package storagebonus

import (
	"context"
	"fmt"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/ente/storagebonus"
)

func (r *Repository) InsertAddOnBonus(ctx context.Context, bonusType storagebonus.BonusType, userID int64, validTill int64, storage int64) error {
	if err := _validate(bonusType); err != nil {
		return err
	}
	bonusID := fmt.Sprintf("%s-%d", bonusType, userID)
	_, err := r.DB.ExecContext(ctx, "INSERT INTO storage_bonus (bonus_id, user_id, storage, type, valid_till) VALUES ($1, $2, $3, $4, $5)", bonusID, userID, storage, bonusType, validTill)
	if err != nil {
		return err
	}
	return nil
}

func (r *Repository) RemoveAddOnBonus(ctx context.Context, bonusType storagebonus.BonusType, userID int64) (int64, error) {
	if err := _validate(bonusType); err != nil {
		return 0, err
	}
	bonusID := fmt.Sprintf("%s-%d", bonusType, userID)
	res, err := r.DB.ExecContext(ctx, "DELETE FROM storage_bonus WHERE bonus_id = $1", bonusID)
	if err != nil {
		return 0, err
	}
	// verify if the bonus was removed
	rowsAffected, err := res.RowsAffected()
	if err != nil {
		return 0, err
	}
	if rowsAffected == int64(0) {
		return 0, ente.NewBadRequestWithMessage(fmt.Sprintf("bonus not found for user %d with bonusID %s", userID, bonusID))
	}
	return rowsAffected, nil
}

func (r *Repository) UpdateAddOnBonus(ctx context.Context, bonusType storagebonus.BonusType, userID int64, validTill int64, storage int64) error {
	if err := _validate(bonusType); err != nil {
		return err
	}
	bonusID := fmt.Sprintf("%s-%d", bonusType, userID)
	_, err := r.DB.ExecContext(ctx, "UPDATE storage_bonus SET storage = $1, valid_till = $2 WHERE bonus_id = $3", storage, validTill, bonusID)
	if err != nil {
		return err
	}
	return nil
}

func _validate(bonusType storagebonus.BonusType) error {
	if bonusType == storagebonus.AddOnBf2023 || bonusType == storagebonus.AddOnBf2024 || bonusType == storagebonus.AddOnSupport {
		return nil
	}
	return fmt.Errorf("invalid bonus type: %s", bonusType)
}
