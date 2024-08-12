package filedata

import (
	"fmt"
	"github.com/ente-io/museum/ente"
)

// BasePrefix returns the base prefix for all objects related to a file. To check if the file data is deleted,
// ensure that there's no file in the S3 bucket with this prefix.
func BasePrefix(fileID int64, ownerID int64) string {
	return fmt.Sprintf("%d/file-data/%d/", ownerID, fileID)
}

func AllObjects(fileID int64, ownerID int64, oType ente.ObjectType) []string {
	switch oType {
	case ente.PreviewVideo:
		return []string{previewVideoPath(fileID, ownerID), previewVideoPlaylist(fileID, ownerID)}
	case ente.MlData:
		return []string{derivedMetaPath(fileID, ownerID)}
	case ente.PreviewImage:
		return []string{previewImagePath(fileID, ownerID)}
	default:
		// throw panic saying current object type is not supported
		panic(fmt.Sprintf("object type %s is not supported", oType))
	}
}

func PreviewUrl(fileID int64, ownerID int64, oType ente.ObjectType) string {
	switch oType {
	case ente.PreviewVideo:
		return previewVideoPath(fileID, ownerID)
	case ente.PreviewImage:
		return previewImagePath(fileID, ownerID)
	default:
		panic(fmt.Sprintf("object type %s is not supported", oType))
	}
}

func previewVideoPath(fileID int64, ownerID int64) string {
	return fmt.Sprintf("%s%s", BasePrefix(fileID, ownerID), string(ente.PreviewVideo))
}

func previewVideoPlaylist(fileID int64, ownerID int64) string {
	return fmt.Sprintf("%s%s", previewVideoPath(fileID, ownerID), "_playlist.m3u8")
}

func previewImagePath(fileID int64, ownerID int64) string {
	return fmt.Sprintf("%s%s", BasePrefix(fileID, ownerID), string(ente.PreviewImage))
}

func derivedMetaPath(fileID int64, ownerID int64) string {
	return fmt.Sprintf("%s%s", BasePrefix(fileID, ownerID), string(ente.MlData))
}
