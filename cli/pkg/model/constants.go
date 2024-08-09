package model

type PhotosStore string

const (
	KVConfig           PhotosStore = "kvConfig"
	RemoteAlbums       PhotosStore = "remoteAlbums"
	RemoteFiles        PhotosStore = "remoteFiles"
	RemoteAlbumEntries PhotosStore = "remoteAlbumEntries"
)

const (
	CollectionsSyncKey        = "lastCollectionSync"
	CollectionsFileSyncKeyFmt = "collectionFilesSync-%d"
)

type ContextKey string

const (
	FilterKey ContextKey = "export_filter"
)
