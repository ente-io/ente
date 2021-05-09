import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';

void showBackupFolderSelectionDialog(BuildContext context) {
  Future.delayed(
    Duration.zero,
    () => showDialog(
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: const BackupFolderSelectionWidget("start backup"),
            backgroundColor: Colors.black.withOpacity(0.8),
          ),
        );
      },
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
    ),
  );
}

class BackupFolderSelectionWidget extends StatefulWidget {
  final String buttonText;

  const BackupFolderSelectionWidget(this.buttonText, {Key key})
      : super(key: key);

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
      if (Platform.isAndroid) {
        _backedupFolders.add("Camera");
      } else {
        _backedupFolders.add("Recents");
      }
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
            "select photos to preserve",
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
                widget.buttonText,
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
                      Bus.instance.fire(BackupFoldersUpdatedEvent());
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
    return FutureBuilder<List<File>>(
      future: FilesDB.instance.getLatestLocalFiles(),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.hasData) {
          snapshot.data.sort((first, second) {
            return first.deviceFolder
                .toLowerCase()
                .compareTo(second.deviceFolder.toLowerCase());
          });
          final List<Widget> foldersWidget = [];
          for (final file in snapshot.data) {
            foldersWidget.add(Padding(
              padding: const EdgeInsets.all(4.0),
              child: CheckboxListTile(
                value: _backedupFolders.contains(file.deviceFolder),
                title: Row(
                  children: [
                    _getThumbnail(file),
                    Padding(padding: EdgeInsets.all(8)),
                    Flexible(
                      child: Text(
                        file.deviceFolder,
                        style: TextStyle(fontSize: 16, height: 1.5),
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ],
                ),
                onChanged: (value) async {
                  if (value) {
                    _backedupFolders.add(file.deviceFolder);
                  } else {
                    _backedupFolders.remove(file.deviceFolder);
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

  Widget _getThumbnail(File file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: Container(
        child: ThumbnailWidget(
          file,
          shouldShowSyncStatus: false,
          key: Key("backup_selection_widget" + file.tag()),
        ),
        height: 50,
        width: 50,
      ),
    );
  }
}
