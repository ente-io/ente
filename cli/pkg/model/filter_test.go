package model

import (
	"testing"
)

func TestFilter_excludeByName(t *testing.T) {
	tests := []struct {
		name   string
		filter Filter
		album  RemoteAlbum
		want   bool
	}{
		{
			name:   "no filters - should not exclude",
			filter: Filter{},
			album:  RemoteAlbum{AlbumName: "Vacation"},
			want:   false,
		},
		{
			name:   "album in Albums list - should not exclude",
			filter: Filter{Albums: []string{"Vacation", "Family"}},
			album:  RemoteAlbum{AlbumName: "Vacation"},
			want:   false,
		},
		{
			name:   "album not in Albums list - should exclude",
			filter: Filter{Albums: []string{"Vacation", "Family"}},
			album:  RemoteAlbum{AlbumName: "Work"},
			want:   true,
		},
		{
			name:   "album in Albums list case insensitive - should not exclude",
			filter: Filter{Albums: []string{"vacation"}},
			album:  RemoteAlbum{AlbumName: "Vacation"},
			want:   false,
		},
		{
			name:   "album with whitespace in Albums list - should not exclude",
			filter: Filter{Albums: []string{"Vacation"}},
			album:  RemoteAlbum{AlbumName: " Vacation "},
			want:   false,
		},
		{
			name:   "album in ExcludeAlbums list - should exclude",
			filter: Filter{ExcludeAlbums: []string{"Work", "Private"}},
			album:  RemoteAlbum{AlbumName: "Work"},
			want:   true,
		},
		{
			name:   "album not in ExcludeAlbums list - should not exclude",
			filter: Filter{ExcludeAlbums: []string{"Work", "Private"}},
			album:  RemoteAlbum{AlbumName: "Vacation"},
			want:   false,
		},
		{
			name:   "album in ExcludeAlbums case insensitive - should exclude",
			filter: Filter{ExcludeAlbums: []string{"work"}},
			album:  RemoteAlbum{AlbumName: "Work"},
			want:   true,
		},
		{
			name:   "album with whitespace in ExcludeAlbums - should exclude",
			filter: Filter{ExcludeAlbums: []string{"Work"}},
			album:  RemoteAlbum{AlbumName: " Work "},
			want:   true,
		},
		{
			name:   "album in both Albums and ExcludeAlbums - ExcludeAlbums takes precedence",
			filter: Filter{Albums: []string{"Vacation"}, ExcludeAlbums: []string{"Vacation"}},
			album:  RemoteAlbum{AlbumName: "Vacation"},
			want:   true,
		},
		{
			name:   "album in Albums but different one in ExcludeAlbums - should not exclude",
			filter: Filter{Albums: []string{"Vacation", "Family"}, ExcludeAlbums: []string{"Work"}},
			album:  RemoteAlbum{AlbumName: "Vacation"},
			want:   false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.filter.excludeByName(tt.album); got != tt.want {
				t.Errorf("Filter.excludeByName() = %v, want %v", got, tt.want)
			}
		})
	}
}
