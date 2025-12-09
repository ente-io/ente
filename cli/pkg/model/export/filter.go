package export

type Filters struct {
	// When true, none of the shared albums are exported
	ExcludeShared bool
	// When true, none of the shared files are exported
	ExcludeSharedFiles bool
	// When true, hidden albums are not exported
	ExcludeHidden bool
	// when album name is provided, only files in those albums are exported
	Albums []string
	// when email is provided, only files shared with that email are exported
	Emails []string
	// for the listed album names, files in these albums are excluded
	ExcludeAlbums []string
}
