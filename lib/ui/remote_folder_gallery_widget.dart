import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/folder_db.dart';
import 'package:photos/db/file_db.dart';
import 'package:photos/events/remote_sync_event.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/remote_folder_page.dart';
import 'package:photos/ui/thumbnail_widget.dart';

class RemoteFolderGalleryWidget extends StatefulWidget {
  const RemoteFolderGalleryWidget({Key key}) : super(key: key);

  @override
  _RemoteFolderGalleryWidgetState createState() =>
      _RemoteFolderGalleryWidgetState();
}

class _RemoteFolderGalleryWidgetState extends State<RemoteFolderGalleryWidget> {
  Logger _logger = Logger("RemoteFolderGalleryWidget");
  StreamSubscription<RemoteSyncEvent> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<RemoteSyncEvent>().listen((event) {
      if (event.success) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Folder>>(
      future: _getRemoteFolders(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isEmpty) {
            return Center(child: Text("Nothing to see here! 👀"));
          } else {
            return _getRemoteFolderGalleryWidget(snapshot.data);
          }
        } else if (snapshot.hasError) {
          _logger.shout(snapshot.error);
          return Center(child: Text(snapshot.error.toString()));
        } else {
          return loadWidget;
        }
      },
    );
  }

  Widget _getRemoteFolderGalleryWidget(List<Folder> folders) {
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

  Future<List<Folder>> _getRemoteFolders() async {
    final folders = await FolderDB.instance.getFolders();
    final filteredFolders = List<Folder>();
    for (final folder in folders) {
      if (folder.owner == Configuration.instance.getUsername()) {
        continue;
      }
      try {
        folder.thumbnailPhoto =
            await FileDB.instance.getLatestFileInRemoteFolder(folder.id);
      } catch (e) {
        _logger.warning(e.toString());
      }
      filteredFolders.add(folder);
    }
    return filteredFolders;
  }

  Widget _buildFolder(BuildContext context, Folder folder) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Container(
            child: folder.thumbnailPhoto ==
                    null // When the user has shared a folder without photos
                ? Icon(Icons.error)
                : Hero(
                    tag: "remote_folder" + folder.thumbnailPhoto.tag(),
                    child: ThumbnailWidget(folder.thumbnailPhoto)),
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
        final page = RemoteFolderPage(folder);
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
