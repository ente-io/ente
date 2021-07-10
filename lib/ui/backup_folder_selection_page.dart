import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/models/file.dart';
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
  bool _shouldSelectAll = true;

  @override
  void initState() {
    _backedupFolders = Configuration.instance.getPathsToBackUp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_backedupFolders.isNotEmpty) {
      _shouldSelectAll = false;
    }
    return Scaffold(
      appBar: AppBar(title: Text("select folders to backup")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 32),
            child: Text(
              "the selected folders will be end-to-end encrypted and backed up",
              style: TextStyle(
                color: Colors.white.withOpacity(0.36),
                fontSize: 14,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
          ),
          Expanded(child: _getFolderList()),
          Padding(
            padding: EdgeInsets.all(20),
          ),
          Hero(
            tag: "select_folders",
            child: Container(
              padding: EdgeInsets.only(left: 60, right: 60, bottom: 32),
              child: button(
                "start backup",
                fontSize: 18,
                onPressed: _backedupFolders.length == 0
                    ? null
                    : () async {
                        await Configuration.instance
                            .setPathsToBackUp(_backedupFolders);
                        Bus.instance.fire(BackupFoldersUpdatedEvent());
                        Navigator.of(context).pop();
                      },
                padding: EdgeInsets.fromLTRB(60, 20, 60, 20),
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
            final isSelected = _shouldSelectAll ||
                _backedupFolders.contains(file.deviceFolder);
            foldersWidget.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 1, right: 4),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                    color: isSelected
                        ? Color.fromRGBO(16, 32, 32, 1)
                        : Color.fromRGBO(8, 18, 18, 0.4),
                  ),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: InkWell(
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
                          value: isSelected,
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
                    onTap: () {
                      final value =
                          !_backedupFolders.contains(file.deviceFolder);
                      if (value) {
                        _backedupFolders.add(file.deviceFolder);
                      } else {
                        _backedupFolders.remove(file.deviceFolder);
                      }
                      setState(() {});
                    },
                  ),
                ),
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
                padding: EdgeInsets.only(right: 4),
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
