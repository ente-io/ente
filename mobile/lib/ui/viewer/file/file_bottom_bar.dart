import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/file/trash_file.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import 'package:photos/ui/collections/collection_action_sheet.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/share_util.dart';

class FileBottomBar extends StatefulWidget {
  final EnteFile file;
  final Function(EnteFile) onEditRequested;
  final Function(EnteFile) onFileRemoved;
  final bool showOnlyInfoButton;
  final int? userID;
  final ValueNotifier<bool> enableFullScreenNotifier;

  const FileBottomBar(
    this.file,
    this.onEditRequested,
    this.showOnlyInfoButton, {
    required this.onFileRemoved,
    required this.enableFullScreenNotifier,
    this.userID,
    Key? key,
  }) : super(key: key);

  @override
  FileBottomBarState createState() => FileBottomBarState();
}

class FileBottomBarState extends State<FileBottomBar> {
  final GlobalKey shareButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return _getBottomBar();
  }

  void safeRefresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _getBottomBar() {
    Logger("FileBottomBar")
        .fine("building bottom bar ${widget.file.generatedID}");
    final List<Widget> children = [];
    final bool isOwnedByUser =
        widget.file.ownerID == null || widget.file.ownerID == widget.userID;
    children.add(
      Tooltip(
        message: "Info",
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: IconButton(
            icon: Icon(
              Platform.isAndroid ? Icons.info_outline : CupertinoIcons.info,
              color: Colors.white,
            ),
            onPressed: () async {
              await _displayDetails(widget.file);
              safeRefresh(); //to instantly show the new caption if keypad is closed after pressing 'done' - here the caption will be updated before the bottom sheet is closed
              await Future.delayed(
                const Duration(milliseconds: 500),
              ); //Waiting for some time till the caption gets updated in db if the user closes the bottom sheet without pressing 'done'
              safeRefresh();
            },
          ),
        ),
      ),
    );
    if (widget.file is TrashFile) {
      _addTrashOptions(children);
    }

    if (!widget.showOnlyInfoButton && widget.file is! TrashFile) {
      if (widget.file.fileType == FileType.image ||
          widget.file.fileType == FileType.livePhoto ||
          (widget.file.fileType == FileType.video)) {
        children.add(
          Tooltip(
            message: "Edit",
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: IconButton(
                icon: const Icon(
                  Icons.tune_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  widget.onEditRequested(widget.file);
                },
              ),
            ),
          ),
        );
      }
      if (isOwnedByUser) {
        children.add(
          Tooltip(
            message: S.of(context).delete,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: IconButton(
                icon: Icon(
                  Platform.isAndroid
                      ? Icons.delete_outline
                      : CupertinoIcons.delete,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await _showSingleFileDeleteSheet(widget.file);
                },
              ),
            ),
          ),
        );
      }
      children.add(
        Tooltip(
          message: S.of(context).share,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: IconButton(
              key: shareButtonKey,
              icon: Icon(
                Platform.isAndroid
                    ? Icons.share_outlined
                    : CupertinoIcons.share,
                color: Colors.white,
              ),
              onPressed: () {
                share(context, [widget.file], shareButtonKey: shareButtonKey);
              },
            ),
          ),
        ),
      );
    }
    final safeAreaBottomPadding = MediaQuery.of(context).padding.bottom * .5;
    return ValueListenableBuilder(
      valueListenable: widget.enableFullScreenNotifier,
      builder: (BuildContext context, bool isFullScreen, _) {
        return IgnorePointer(
          ignoring: isFullScreen,
          child: AnimatedOpacity(
            opacity: isFullScreen ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.72),
                    ],
                    stops: const [0, 0.8, 1],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: safeAreaBottomPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget.file.caption?.isNotEmpty ?? false
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                0,
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  await _displayDetails(widget.file);
                                  await Future.delayed(
                                    const Duration(milliseconds: 500),
                                  ); //Waiting for some time till the caption gets updated in db if the user closes the bottom sheet without pressing 'done'
                                  safeRefresh();
                                },
                                child: Text(
                                  widget.file.caption!,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: getEnteTextTheme(context)
                                      .mini
                                      .copyWith(color: textBaseDark),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: children,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSingleFileDeleteSheet(EnteFile file) async {
    await showSingleFileDeleteSheet(
      context,
      file,
      onFileRemoved: widget.onFileRemoved,
    );
  }

  void _addTrashOptions(List<Widget> children) {
    children.add(
      Tooltip(
        message: S.of(context).restore,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: IconButton(
            icon: const Icon(
              Icons.restore_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              final selectedFiles = SelectedFiles();
              selectedFiles.toggleSelection(widget.file);
              showCollectionActionSheet(
                context,
                selectedFiles: selectedFiles,
                actionType: CollectionActionType.restoreFiles,
              );
            },
          ),
        ),
      ),
    );

    children.add(
      Tooltip(
        message: S.of(context).delete,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.white,
            ),
            onPressed: () async {
              final trashedFile = <TrashFile>[];
              trashedFile.add(widget.file as TrashFile);
              if (await deleteFromTrash(context, trashedFile) == true) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _displayDetails(EnteFile file) async {
    await showDetailsSheet(context, file);
  }
}
