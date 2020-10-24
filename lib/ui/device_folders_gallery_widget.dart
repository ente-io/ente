import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/repositories/file_repository.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/ui/common_elements.dart';
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
    return FutureBuilder<List<DeviceFolder>>(
      future: _getDeviceFolders(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.length == 0) {
            return nothingToSeeHere;
          }
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
    final paths = await FilesDB.instance.getLocalPaths();
    final folders = List<DeviceFolder>();
    for (final path in paths) {
      final files = List<File>();
      for (File file in FileRepository.instance.files) {
        if (file.deviceFolder == path) {
          files.add(file);
        }
      }
      final folderName = p.basename(path);
      folders.add(DeviceFolder(folderName, path, () => files, files[0]));
    }
    folders.sort((first, second) {
      return second.thumbnail.creationTime
          .compareTo(first.thumbnail.creationTime);
    });
    final favorites = FavoritesService.instance.getFavoriteFiles().toList();
    favorites.sort((first, second) {
      return second.creationTime.compareTo(first.creationTime);
    });
    if (favorites.length > 0) {
      folders.insert(
          0,
          DeviceFolder("Favorites", "/Favorites", () {
            final favorites =
                FavoritesService.instance.getFavoriteFiles().toList();
            favorites.sort((first, second) {
              return second.creationTime.compareTo(first.creationTime);
            });
            return favorites;
          }, favorites[0]));
    }
    final videos = await FilesDB.instance.getAllVideos();
    if (videos.length > 0) {
      folders.insert(
          0, DeviceFolder("Videos", "/Videos", () => videos, videos[0]));
    }
    return folders;
  }

  Widget _buildFolder(BuildContext context, DeviceFolder folder) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Container(
            child: Hero(
                tag: "device_folder:" + folder.path + folder.thumbnail.tag(),
                child: ThumbnailWidget(folder.thumbnail)),
            height: 140,
            width: 140,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              folder.name,
              style: TextStyle(
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return DeviceFolderPage(folder);
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
