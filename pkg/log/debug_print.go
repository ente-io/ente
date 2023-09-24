package debuglog

import (
	"cli-go/pkg/model"
	"fmt"
)

// This file contains functions that are used to print debug information to the console.

func PrintAlbum(a *model.Album) {
	fmt.Printf("=======\n")
	fmt.Printf("ID: %d\n", a.ID)
	fmt.Printf("OwnerID: %d\n", a.OwnerID)
	if a.IsShared {
		fmt.Printf("Shared album")
	}
	fmt.Printf(" Name: %s\n", a.AlbumName)
	if a.PrivateMeta != nil {
		fmt.Printf("PrivateMeta: %s\n", *a.PrivateMeta)
	}
	if a.PublicMeta != nil {
		fmt.Printf("PublicMeta: %s\n", *a.PublicMeta)
	}
	if a.SharedMeta != nil {
		fmt.Printf("SharedMeta: %s\n", *a.SharedMeta)
	}
	fmt.Printf("LastUpdatedAt: %d", a.LastUpdatedAt)
	fmt.Printf("\n=======")
}
