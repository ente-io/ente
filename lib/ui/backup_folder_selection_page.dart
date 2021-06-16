import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/collections_gallery_widget.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';

class BackupFolderSelectionPage extends StatefulWidget {
  const BackupFolderSelectionPage({Key key}) : super(key: key);

  @override
  _BackupFolderSelectionPageState createState() =>
      _BackupFolderSelectionPageState();
}

class _BackupFolderSelectionPageState extends State<BackupFolderSelectionPage> {
  Set<String> _backedupFolders = Set<String>();

  @override
  void initState() {
    _backedupFolders = Configuration.instance.getPathsToBackUp();
    if (_backedupFolders.length == 0) {
      if (io.Platform.isAndroid) {
        _backedupFolders.add("Camera");
      } else {
        _backedupFolders.add("Recents");
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
          ),
          Center(
            child: Hero(
              tag: "select_folders",
              child: Material(
                type: MaterialType.transparency,
                child: SectionTitle(
                  "preserve memories",
                  alignment: Alignment.center,
                  opacity: 0.9,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
          ),
          Expanded(child: _getFolderList()),
          Padding(
            padding: EdgeInsets.all(12),
          ),
          Container(
            padding: EdgeInsets.only(left: 60, right: 60),
            width: double.infinity,
            height: 64,
            child: button(
              "preserve",
              fontSize: 18,
              onPressed: _backedupFolders.length == 0
                  ? null
                  : () async {
                      await Configuration.instance
                          .setPathsToBackUp(_backedupFolders);
                      Bus.instance.fire(BackupFoldersUpdatedEvent());
                      Navigator.of(context).pop();
                    },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "the files within the folders you select will be encrypted and backed up in the background",
              style: TextStyle(
                color: Colors.white.withOpacity(0.36),
                fontSize: 14,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 8, 40, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fast_forward,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  Padding(padding: EdgeInsets.all(2)),
                  Text(
                    "skip",
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          )
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
            foldersWidget.add(
              InkWell(
                child: Container(
                  color: _backedupFolders.contains(file.deviceFolder)
                      ? Color.fromRGBO(16, 32, 32, 1)
                      : Color.fromRGBO(8, 18, 18, 0.4),
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Expanded(
                          child: Row(
                            children: [
                              _getThumbnail(file),
                              Padding(padding: EdgeInsets.all(10)),
                              Expanded(
                                child: Text(
                                  file.deviceFolder,
                                  style: TextStyle(fontSize: 16, height: 1.5),
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Checkbox(
                        value: _backedupFolders.contains(file.deviceFolder),
                        onChanged: (value) {
                          if (value) {
                            _backedupFolders.add(file.deviceFolder);
                          } else {
                            _backedupFolders.remove(file.deviceFolder);
                          }
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  final value = !_backedupFolders.contains(file.deviceFolder);
                  if (value) {
                    _backedupFolders.add(file.deviceFolder);
                  } else {
                    _backedupFolders.remove(file.deviceFolder);
                  }
                  setState(() {});
                },
              ),
            );
          }

          final scrollController = ScrollController();
          child = Scrollbar(
            isAlwaysShown: true,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                color: Colors.white.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: foldersWidget,
                ),
              ),
            ),
          );
        } else {
          child = loadWidget;
        }
        return Container(
          padding: EdgeInsets.only(left: 40, right: 40),
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
        height: 60,
        width: 60,
      ),
    );
  }
}
