package model

type PhotosStore string

const (
	KVConfig     PhotosStore = "akvConfig"
	RemoteAlbums PhotosStore = "aremoteAlbums"
	RemoteFiles  PhotosStore = "aremoteFiles"
)

const (
	CollectionsSyncKey        = "lastCollectionSync"
	CollectionsFileSyncKeyFmt = "collectionFilesSync-%d"
)
