package social

import (
	"testing"

	socialentity "github.com/ente-io/museum/ente/social"
	"github.com/stretchr/testify/require"
)

func TestValidateReplyFileContext(t *testing.T) {
	fileID := int64(42)
	otherFileID := int64(7)
	parentWithFile := &socialentity.Comment{FileID: &fileID}
	parentWithoutFile := &socialentity.Comment{}

	tests := []struct {
		name    string
		parent  *socialentity.Comment
		request *int64
		wantErr bool
	}{
		{name: "no parent no file", parent: nil, request: nil, wantErr: false},
		{name: "no parent with file", parent: nil, request: &fileID, wantErr: false},
		{name: "parent without file and no request file", parent: parentWithoutFile, request: nil, wantErr: false},
		{name: "parent without file but request file", parent: parentWithoutFile, request: &fileID, wantErr: true},
		{name: "parent with file and matching request", parent: parentWithFile, request: &fileID, wantErr: false},
		{name: "parent with file missing request", parent: parentWithFile, request: nil, wantErr: true},
		{name: "parent with file mismatched request", parent: parentWithFile, request: &otherFileID, wantErr: true},
	}

	for _, tc := range tests {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			err := validateReplyFileContext(tc.parent, tc.request)
			if tc.wantErr {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

func TestValidateCommentReactionContext(t *testing.T) {
	fileID := int64(10)
	otherFileID := int64(11)
	commentWithFile := &socialentity.Comment{FileID: &fileID}
	commentWithoutFile := &socialentity.Comment{}

	tests := []struct {
		name    string
		comment *socialentity.Comment
		request *int64
		wantErr bool
	}{
		{name: "nil comment no file", comment: nil, request: nil, wantErr: false},
		{name: "nil comment with file", comment: nil, request: &fileID, wantErr: false},
		{name: "comment without file no request file", comment: commentWithoutFile, request: nil, wantErr: false},
		{name: "comment without file but request file", comment: commentWithoutFile, request: &fileID, wantErr: true},
		{name: "comment with file missing request", comment: commentWithFile, request: nil, wantErr: true},
		{name: "comment with file mismatch", comment: commentWithFile, request: &otherFileID, wantErr: true},
		{name: "comment with file match", comment: commentWithFile, request: &fileID, wantErr: false},
	}

	for _, tc := range tests {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			err := validateCommentReactionContext(tc.comment, tc.request)
			if tc.wantErr {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
			}
		})
	}
}
