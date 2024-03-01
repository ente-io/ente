package ente

// Trash indicates a trashed file in the system.
type Trash struct {
	File       File  `json:"file"`
	IsDeleted  bool  `json:"isDeleted"`
	IsRestored bool  `json:"isRestored"`
	DeleteBy   int64 `json:"deleteBy"`
	CreatedAt  int64 `json:"createdAt"`
	UpdatedAt  int64 `json:"updatedAt"`
}

// DeleteTrashFilesRequest represents a request to delete a trashed files
type DeleteTrashFilesRequest struct {
	FileIDs []int64 `json:"fileIDs" binding:"required"`
	// OwnerID will be set based on the authenticated user
	OwnerID int64
}

// EmptyTrashRequest represents a request to empty items from user's trash
type EmptyTrashRequest struct {
	// LastUpdatedAt timestamp will be used to delete trashed files with updatedAt timestamp <= LastUpdatedAt
	// User's trash will be cleaned up in an async manner. The timestamp is used to ensure that newly trashed files
	// are not deleted due to delay in the async operation.
	LastUpdatedAt int64 `json:"lastUpdatedAt" binding:"required"`
}

// TrashCollectionV3Request represents the request for trashing/deleting a collection.
// In V3, while trashing/deleting any album, the user can decide to either keep or delete the all files which are
// present in to the trash. When user wants to keep the files, the clients are expected to move all the files from
// the underlying collection to any other collection owned by the user, inlcuding uncategorized.
// Note: Collection Delete Versions for DELETE /collections/V../ endpoint
// V1: All files which exclusively belong to the collections are deleted immediately.
// V2: All files which exclusively belong to the collections are moved to the trash.
// V3: All files which are still present in the collection (irrespective if they blong to another collection) will be moved to trash.
// V3 is introduced to avoid doing this booking on server, where we only delete a file when it's beling removed from the last collection it longs to.
// In theory above logic to delete when it's being removed from last collection sounds good. But,
// in practice it complicates the code (thus reducing its robustness) because of race conditions, and it's
// also hard to communicate it to the user. So, to simplify things, in V3, the files will be only deleted when user tell us to delete them.
type TrashCollectionV3Request struct {
	CollectionID int64 `json:"collectionID" form:"collectionID" binding:"required"`
	// When KeepFiles is false, then all the files which are present in the collection will be moved to trash.
	// When KeepFiles is true, but the underlying collection still contains file, then the API call will fail.
	// This is to ensure that before deleting the collection, the client has moved all relevant files to any other
	// collection owned by the user, including Uncategorized.
	KeepFiles *bool `json:"keepFiles" form:"keepFiles" binding:"required"`
}
