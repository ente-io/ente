import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';

class BackupFolderSelectionWidget extends StatefulWidget {
  const BackupFolderSelectionWidget({Key key}) : super(key: key);

  @override
  _BackupFolderSelectionWidgetState createState() =>
      _BackupFolderSelectionWidgetState();
}

class _BackupFolderSelectionWidgetState
    extends State<BackupFolderSelectionWidget> {
  Set<String> _backedupFolders = Set<String>();

  @override
  void initState() {
    _backedupFolders = Configuration.instance.getPathsToBackUp();
    if (_backedupFolders.length == 0) {
      _backedupFolders.add("Camera");
      _backedupFolders.add("Recents");
      _backedupFolders.add("DCIM");
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(4),
          ),
          Text(
            "select folders to backup",
            style: TextStyle(fontSize: 20),
          ),
          Padding(
            padding: EdgeInsets.all(12),
          ),
          _getFolderList(),
          Padding(
            padding: EdgeInsets.all(8),
          ),
          Container(
            width: double.infinity,
            height: 64,
            child: RaisedButton(
              child: Text(
                "start backup",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              onPressed: _backedupFolders.length == 0
                  ? null
                  : () {
                      Configuration.instance.setPathsToBackUp(_backedupFolders);
                      Navigator.pop(context);
                    },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getFolderList() {
    return FutureBuilder<List<String>>(
      future: FilesDB.instance.getLocalPaths(),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.hasData) {
          snapshot.data.sort((first, second) {
            return first.toLowerCase().compareTo(second.toLowerCase());
          });
          final List<Widget> foldersWidget = [];
          for (final folder in snapshot.data) {
            foldersWidget.add(Padding(
              padding: const EdgeInsets.all(4.0),
              child: CheckboxListTile(
                value: _backedupFolders.contains(folder),
                title: Row(
                  children: [
                    _getThumbnail(folder),
                    Padding(padding: EdgeInsets.all(8)),
                    Flexible(
                      child: Text(
                        folder,
                        style: TextStyle(fontSize: 16, height: 1.5),
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ],
                ),
                onChanged: (value) async {
                  if (value) {
                    _backedupFolders.add(folder);
                  } else {
                    _backedupFolders.remove(folder);
                  }
                  setState(() {});
                },
              ),
            ));
          }

          final scrollController = ScrollController();
          child = Scrollbar(
            isAlwaysShown: true,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: foldersWidget,
              ),
            ),
          );
        } else {
          child = loadWidget;
        }
        return Container(
          height: 400,
          width: 300,
          child: child,
        );
      },
    );
  }

  FutureBuilder<File> _getThumbnail(String folder) {
    return FutureBuilder(
      future: FilesDB.instance.getLastCreatedFileInPath(folder),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Container(
              child: ThumbnailWidget(
                snapshot.data,
                shouldShowSyncStatus: false,
              ),
              height: 50,
              width: 50,
            ),
          );
        } else {
          return Container(
            height: 50,
            width: 50,
            child: loadWidget,
          );
        }
      },
    );
  }
}
