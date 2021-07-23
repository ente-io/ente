import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';

class BackupFolderSelectionPage extends StatefulWidget {
  final bool shouldSelectAll;
  final String buttonText;

  const BackupFolderSelectionPage({
    @required this.buttonText,
    this.shouldSelectAll = false,
    Key key,
  }) : super(key: key);

  @override
  _BackupFolderSelectionPageState createState() =>
      _BackupFolderSelectionPageState();
}

class _BackupFolderSelectionPageState extends State<BackupFolderSelectionPage> {
  final Set<String> _allFolders = <String>{};
  Set<String> _selectedFolders = <String>{};
  List<File> _latestFiles;
  Map<String, int> _itemCount;

  @override
  void initState() {
    _selectedFolders = Configuration.instance.getPathsToBackUp();
    FilesDB.instance.getLatestLocalFiles().then((files) async {
      _itemCount = await FilesDB.instance.getFileCountInDeviceFolders();
      Logger("BackupFolderSelectionPage").info(_itemCount);
      setState(() {
        _latestFiles = files;
        _latestFiles.sort((first, second) {
          return first.deviceFolder
              .toLowerCase()
              .compareTo(second.deviceFolder.toLowerCase());
        });
        for (final file in _latestFiles) {
          _allFolders.add(file.deviceFolder);
        }
        if (widget.shouldSelectAll ||
            Configuration.instance.hasSelectedAllFoldersForBackup()) {
          _selectedFolders.addAll(_allFolders);
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
          ),
          _latestFiles == null
              ? Container()
              : GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 64, 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _selectedFolders.length == _allFolders.length
                            ? "unselect all"
                            : "select all",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    final hasSelectedAll =
                        _selectedFolders.length == _allFolders.length;
                    // Flip selection
                    if (hasSelectedAll) {
                      _selectedFolders.clear();
                    } else {
                      _selectedFolders.addAll(_allFolders);
                    }
                    _latestFiles.sort((first, second) {
                      return first.deviceFolder
                          .toLowerCase()
                          .compareTo(second.deviceFolder.toLowerCase());
                    });
                    setState(() {});
                  }),
          Expanded(child: _getFolders()),
          Padding(
            padding: EdgeInsets.all(20),
          ),
          Hero(
            tag: "select_folders",
            child: Container(
              padding: EdgeInsets.only(left: 60, right: 60, bottom: 32),
              child: button(
                widget.buttonText,
                fontSize: 18,
                onPressed: _selectedFolders.isEmpty
                    ? null
                    : () async {
                        await Configuration.instance
                            .setPathsToBackUp(_selectedFolders);
                        Configuration.instance.setSelectAllFoldersForBackup(
                            _selectedFolders.length == _allFolders.length);
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

  Widget _getFolders() {
    if (_latestFiles == null) {
      return loadWidget;
    }
    _sortFiles();
    final scrollController = ScrollController();
    return Container(
      padding: EdgeInsets.only(left: 40, right: 40),
      child: Scrollbar(
        controller: scrollController,
        isAlwaysShown: true,
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ImplicitlyAnimatedReorderableList<File>(
            controller: scrollController,
            items: _latestFiles,
            areItemsTheSame: (oldItem, newItem) =>
                oldItem.deviceFolder == newItem.deviceFolder,
            onReorderFinished: (item, from, to, newItems) {
              setState(() {
                _latestFiles
                  ..clear()
                  ..addAll(newItems);
              });
            },
            itemBuilder: (context, itemAnimation, file, index) {
              return Reorderable(
                key: ValueKey(file),
                builder: (context, dragAnimation, inDrag) {
                  final t = dragAnimation.value;
                  final elevation = lerpDouble(0, 8, t);
                  final color = Color.lerp(
                      Colors.white, Colors.white.withOpacity(0.8), t);
                  return SizeFadeTransition(
                    sizeFraction: 0.7,
                    curve: Curves.easeInOut,
                    animation: itemAnimation,
                    child: Material(
                      color: color,
                      elevation: elevation,
                      type: MaterialType.transparency,
                      child: _getFileItem(file),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _getFileItem(File file) {
    final isSelected = _selectedFolders.contains(file.deviceFolder);
    return Padding(
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
              Row(
                children: [
                  _getThumbnail(file),
                  Padding(padding: EdgeInsets.all(10)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: 140),
                        child: Text(
                          file.deviceFolder,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      Padding(padding: EdgeInsets.all(2)),
                      Text(
                        _itemCount[file.deviceFolder].toString() +
                            " item" +
                            (_itemCount[file.deviceFolder] == 1 ? "" : "s"),
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white.withOpacity(0.65)
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  if (value) {
                    _selectedFolders.add(file.deviceFolder);
                  } else {
                    _selectedFolders.remove(file.deviceFolder);
                  }
                  setState(() {});
                },
              ),
            ],
          ),
          onTap: () {
            final value = !_selectedFolders.contains(file.deviceFolder);
            if (value) {
              _selectedFolders.add(file.deviceFolder);
            } else {
              _selectedFolders.remove(file.deviceFolder);
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  void _sortFiles() {
    _latestFiles.sort((first, second) {
      if (_selectedFolders.contains(first.deviceFolder) &&
          _selectedFolders.contains(second.deviceFolder)) {
        return first.deviceFolder
            .toLowerCase()
            .compareTo(second.deviceFolder.toLowerCase());
      } else if (_selectedFolders.contains(first.deviceFolder)) {
        return -1;
      } else if (_selectedFolders.contains(second.deviceFolder)) {
        return 1;
      }
      return first.deviceFolder
          .toLowerCase()
          .compareTo(second.deviceFolder.toLowerCase());
    });
  }

  Widget _getThumbnail(File file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: SizedBox(
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
