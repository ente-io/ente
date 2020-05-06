import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/db/db_helper.dart';
import 'package:photos/favorite_photos_repository.dart';
import 'package:photos/models/album.dart';
import 'package:photos/models/filters/favorite_items_filter.dart';
import 'package:photos/models/filters/folder_name_filter.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/ui/album_page.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:path/path.dart' as p;

class AlbumListWidget extends StatefulWidget {
  final List<Photo> photos;

  const AlbumListWidget(this.photos, {Key key}) : super(key: key);

  @override
  _AlbumListWidgetState createState() => _AlbumListWidgetState();
}

class _AlbumListWidgetState extends State<AlbumListWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getAlbums(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _getAlbumListWidget(snapshot.data);
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return loadWidget;
        }
      },
    );
  }

  Widget _getAlbumListWidget(List<Album> albums) {
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

  Future<List<Album>> _getAlbums() async {
    final paths = await DatabaseHelper.instance.getDistinctPaths();
    final albums = List<Album>();
    for (final path in paths) {
      final photo = await DatabaseHelper.instance.getLatestPhotoInPath(path);
      final albumName = p.basename(path);
      albums.add(Album(albumName, photo, FolderNameFilter(albumName)));
    }
    albums.sort((firstAlbum, secondAlbum) {
      return secondAlbum.thumbnailPhoto.createTimestamp
          .compareTo(firstAlbum.thumbnailPhoto.createTimestamp);
    });
    if (FavoritePhotosRepository.instance.hasFavorites()) {
      final photo = await DatabaseHelper.instance
          .getLatestPhotoAmongGeneratedIds(
              FavoritePhotosRepository.instance.getLiked().toList());
      albums.insert(0, Album("Favorites", photo, FavoriteItemsFilter()));
    }
    return albums;
  }

  Widget _buildAlbum(BuildContext context, Album album) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Container(
            child: ThumbnailWidget(album.thumbnailPhoto),
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
