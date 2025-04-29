package ente

type CollectionParticipantRole string

const (
	VIEWER       CollectionParticipantRole = "VIEWER"
	OWNER        CollectionParticipantRole = "OWNER"
	COLLABORATOR CollectionParticipantRole = "COLLABORATOR"
	UNKNOWN      CollectionParticipantRole = "UNKNOWN"
)

func (c *CollectionParticipantRole) CanAdd() bool {
	if c == nil {
		return false
	}
	return *c == OWNER || *c == COLLABORATOR
}

// CanRemoveAny indicates if the role allows user to remove files added by others too
func (c *CollectionParticipantRole) CanRemoveAny() bool {
	if c == nil {
		return false
	}
	return *c == OWNER
}

func ConvertStringToCollectionParticipantRole(value string) CollectionParticipantRole {
	switch value {
	case "VIEWER":
		return VIEWER
	case "OWNER":
		return OWNER
	case "COLLABORATOR":
		return COLLABORATOR
	default:
		return UNKNOWN
	}
}
