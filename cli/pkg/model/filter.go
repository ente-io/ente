package model

import (
	"log"
	"strings"
)

type Filter struct {
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

func (f Filter) SkipAccount(email string) bool {
	if len(f.Emails) == 0 {
		return false
	}
	for _, e := range f.Emails {
		if strings.ToLower(e) == strings.ToLower(strings.TrimSpace(email)) {
			return false
		}
	}
	return true
}

func (f Filter) SkipAlbum(album RemoteAlbum, shouldLog bool) bool {
	if f.excludeByName(album) {
		if shouldLog {
			log.Printf("Skipping album %s as it's not part of album to export", album.AlbumName)
		}
		return true
	}
	if f.ExcludeShared && album.IsShared {
		if shouldLog {
			log.Printf("Skipping album %s as it's shared", album.AlbumName)
		}
		return true
	}
	if f.ExcludeHidden && album.IsHidden() {
		if shouldLog {
			log.Printf("Skipping album %s as it's hidden", album.AlbumName)
		}
		return true
	}
	return false
}

// excludeByName returns true if Albums list is not empty and album name is not in the list,
// or if album name is in the ExcludeAlbums list
func (f Filter) excludeByName(album RemoteAlbum) bool {
	// Check if album is in the ExcludeAlbums list
	for _, a := range f.ExcludeAlbums {
		if strings.ToLower(a) == strings.ToLower(strings.TrimSpace(album.AlbumName)) {
			return true
		}
	}

	// Check if Albums filter is set and album is not in the list
	if len(f.Albums) > 0 {
		for _, a := range f.Albums {
			if strings.ToLower(a) == strings.ToLower(strings.TrimSpace(album.AlbumName)) {
				return false
			}
		}
		return true
	}
	return false
}
