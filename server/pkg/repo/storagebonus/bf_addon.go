package storagebonus

import (
	"context"
	"fmt"
	"github.com/ente-io/museum/ente/storagebonus"
)

func (r *Repository) InsertAddOnBonus(ctx context.Context, bonusType storagebonus.BonusType, userID int64, validTill int64, storage int64) error {
	if err := _validate(bonusType); err != nil {
		return err
	}
	bonusID := fmt.Sprintf("%s-%d", bonusType, userID)
	_, err := r.DB.ExecContext(ctx, "INSERT INTO storage_bonus (bonus_id, user_id, storage, type, valid_till) VALUES ($1, $2, $3, $4, $5)", bonusID, userID, storage, storagebonus.AddOnBf2023, validTill)
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
	return res.RowsAffected()
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
	if bonusType == storagebonus.AddOnBf2023 || bonusType == storagebonus.AddOnSupport {
		return nil
	}
	return fmt.Errorf("invalid bonus type: %s", bonusType)
}
