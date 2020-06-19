import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/photo_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/favorite_photos_repository.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/models/filters/favorite_items_filter.dart';
import 'package:photos/models/filters/folder_name_filter.dart';
import 'package:photos/ui/device_folder_page.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:path/path.dart' as p;

class DeviceFolderGalleryWidget extends StatefulWidget {
  const DeviceFolderGalleryWidget({Key key}) : super(key: key);

  @override
  _DeviceFolderGalleryWidgetState createState() =>
      _DeviceFolderGalleryWidgetState();
}

class _DeviceFolderGalleryWidgetState extends State<DeviceFolderGalleryWidget> {
  StreamSubscription<LocalPhotosUpdatedEvent> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getDeviceFolders(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _getDeviceFolderGalleryWidget(snapshot.data);
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return loadWidget;
        }
      },
    );
  }

  Widget _getDeviceFolderGalleryWidget(List<DeviceFolder> folders) {
    return Container(
      margin: EdgeInsets.only(top: 24),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.only(bottom: 12),
        physics: ScrollPhysics(), // to disable GridView's scrolling
        itemBuilder: (context, index) {
          return _buildFolder(context, folders[index]);
        },
        itemCount: folders.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      ),
    );
  }

  Future<List<DeviceFolder>> _getDeviceFolders() async {
    final paths = await FileDB.instance.getLocalPaths();
    final folders = List<DeviceFolder>();
    for (final path in paths) {
      final file = await FileDB.instance.getLatestFileInPath(path);
      final folderName = p.basename(path);
      folders
          .add(DeviceFolder(folderName, file, FolderNameFilter(folderName)));
    }
    folders.sort((first, second) {
      return second.thumbnail.createTimestamp
          .compareTo(first.thumbnail.createTimestamp);
    });
    if (FavoriteFilesRepository.instance.hasFavorites()) {
      final file = await FileDB.instance.getLatestFileAmongGeneratedIds(
          FavoriteFilesRepository.instance.getLiked().toList());
      folders.insert(
          0, DeviceFolder("Favorites", file, FavoriteItemsFilter()));
    }
    return folders;
  }

  Widget _buildFolder(BuildContext context, DeviceFolder folder) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Container(
            child: ThumbnailWidget(folder.thumbnail),
            height: 150,
            width: 150,
          ),
          Padding(padding: EdgeInsets.all(2)),
          Expanded(
            child: Text(
              folder.name,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        final page = DeviceFolderPage(folder);
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

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
