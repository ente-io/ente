package model

type PhotosStore string

const (
	KVConfig     PhotosStore = "kvConfig"
	RemoteAlbums PhotosStore = "remoteAlbums"
	RemoteFiles  PhotosStore = "remoteFiles"
)

const (
	CollectionsSyncKey        = "lastCollectionSync"
	CollectionsFileSyncKeyFmt = "collectionFilesSync-%d"
)
