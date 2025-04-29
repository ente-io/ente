package details

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/ente/storagebonus"
)

type UserDetailsResponse struct {
	Email        string                     `json:"email,omitempty"`
	Usage        int64                      `json:"usage"`
	Subscription ente.Subscription          `json:"subscription"`
	FamilyData   *ente.FamilyMemberResponse `json:"familyData,omitempty"`
	FileCount    *int64                     `json:"fileCount,omitempty"`
	// Deprecated field. Client doesn't consume this field. We can completely remove it after Aug 2023
	SharedCollectionsCount *int64                           `json:"sharedCollectionsCount,omitempty"`
	StorageBonus           int64                            `json:"storageBonus"`
	ProfileData            *ente.ProfileData                `json:"profileData"`
	BonusData              *storagebonus.ActiveStorageBonus `json:"bonusData"`
}
