package export

type AlbumMetadata struct {
	ID        int64  `json:"id"`
	OwnerID   int64  `json:"ownerID"`
	AlbumName string `json:"albumName"`
	IsDeleted bool   `json:"isDeleted"`
	// This is to handle the case where two accounts are exporting to the same directory
	// and a album is shared between them
	AccountOwnerIDs []int64 `json:"accountOwnerIDs"`

	// Folder name is the name of the disk folder that contains the album data
	// exclude this from json serialization
	FolderName string `json:"-"`
}

// AddAccountOwner adds the given account id to the list of account owners
// if it is not already present. Returns true if the account id was added
// and false otherwise
func (a *AlbumMetadata) AddAccountOwner(id int64) bool {
	for _, ownerID := range a.AccountOwnerIDs {
		if ownerID == id {
			return false
		}
	}
	a.AccountOwnerIDs = append(a.AccountOwnerIDs, id)
	return true
}
