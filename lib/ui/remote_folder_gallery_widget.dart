import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/folder_db.dart';
import 'package:photos/db/photo_db.dart';
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Folder>>(
      future: _getRemoteFolders(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isEmpty) {
            return Center(child: Text("Nothing to see here!"));
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
    for (final folder in folders) {
      folder.thumbnailPhoto =
          await PhotoDB.instance.getLatestPhotoInRemoteFolder(folder.id);
    }
    return folders;
  }

  Widget _buildFolder(BuildContext context, Folder folder) {
    return GestureDetector(
      child: Column(
        children: <Widget>[
          Container(
            child: ThumbnailWidget(folder.thumbnailPhoto),
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
}
