import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/favorite_photos_repository.dart';
import 'package:photos/models/album.dart';
import 'package:photos/models/filters/favorite_items_filter.dart';
import 'package:photos/models/filters/folder_name_filter.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/ui/album_page.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:path/path.dart' as path;

class AlbumListWidget extends StatefulWidget {
  final List<Photo> photos;

  const AlbumListWidget(this.photos, {Key key}) : super(key: key);

  @override
  _AlbumListWidgetState createState() => _AlbumListWidgetState();
}

class _AlbumListWidgetState extends State<AlbumListWidget> {
  @override
  Widget build(BuildContext context) {
    List<Album> albums = _getAlbums(widget.photos);

    return Container(
      margin: EdgeInsets.only(top: 24),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.only(bottom: 12),
        physics: ScrollPhysics(), // to disable GridView's scrolling
        itemBuilder: (context, index) {
          return _buildAlbum(context, albums[index]);
        },
        itemCount: albums.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      ),
    );
  }

  List<Album> _getAlbums(List<Photo> photos) {
    final albumMap = new LinkedHashMap<String, List<Photo>>();
    final favorites = Album("Favorites", List<Photo>(), FavoriteItemsFilter());
    for (Photo photo in photos) {
      final folder = path.basename(photo.pathName);
      if (!albumMap.containsKey(folder)) {
        albumMap[folder] = new List<Photo>();
      }
      albumMap[folder].add(photo);

      if (FavoritePhotosRepository.instance.isLiked(photo)) {
        favorites.photos.add(photo);
      }
    }
    List<Album> albums = new List<Album>();
    if (favorites.photos.isNotEmpty) {
      albums.add(favorites);
    }
    for (String albumName in albumMap.keys) {
      albums.add(
          Album(albumName, albumMap[albumName], FolderNameFilter(albumName)));
    }
    return albums;
  }

  Widget _buildAlbum(BuildContext context, Album album) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Container(
            child: ThumbnailWidget(album.photos[0]),
            height: 150,
            width: 150,
          ),
          Padding(padding: EdgeInsets.all(2)),
          Expanded(
            child: Text(
              album.name,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        final page = AlbumPage(album);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return page;
            },
          ),
        );
      },
    );
  }
}
