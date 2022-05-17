import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/models/trash_file.dart';
import 'package:photos/ui/create_collection_page.dart';
import 'package:photos/ui/file_info_dialog.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/share_util.dart';

class FadingBottomBar extends StatefulWidget {
  final File file;
  final Function(File) onEditRequested;
  final bool showOnlyInfoButton;

  FadingBottomBar(
    this.file,
    this.onEditRequested,
    this.showOnlyInfoButton, {
    Key key,
  }) : super(key: key);

  @override
  FadingBottomBarState createState() => FadingBottomBarState();
}

class FadingBottomBarState extends State<FadingBottomBar> {
  bool _shouldHide = false;
  final GlobalKey shareButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return _getBottomBar();
  }

  void hide() {
    setState(() {
      _shouldHide = true;
    });
  }

  void show() {
    setState(() {
      _shouldHide = false;
    });
  }

  void safeRefresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _getBottomBar() {
    List<Widget> children = [];
    children.add(
      Tooltip(
        message: "Info",
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: IconButton(
            icon: Icon(
                Platform.isAndroid ? Icons.info_outline : CupertinoIcons.info),
            onPressed: () {
              _displayInfo(widget.file);
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
          widget.file.fileType == FileType.livePhoto) {
        children.add(
          Tooltip(
            message: "Edit",
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: IconButton(
                icon: Icon(Icons.tune_outlined),
                onPressed: () {
                  widget.onEditRequested(widget.file);
                },
              ),
            ),
          ),
        );
      }
      if (widget.file.uploadedFileID != null &&
          widget.file.ownerID == Configuration.instance.getUserID()) {
        bool isArchived =
            widget.file.magicMetadata.visibility == kVisibilityArchive;
        children.add(
          Tooltip(
            message: isArchived ? "Unhide" : "Hide",
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: IconButton(
                icon: Icon(Platform.isAndroid
                    ? (isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined)
                    : (isArchived
                        ? CupertinoIcons.archivebox_fill
                        : CupertinoIcons.archivebox)),
                onPressed: () async {
                  await changeVisibility(
                    context,
                    [widget.file],
                    isArchived ? kVisibilityVisible : kVisibilityArchive,
                  );
                  safeRefresh();
                },
              ),
            ),
          ),
        );
      }
      children.add(
        Tooltip(
          message: "Share",
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: IconButton(
              key: shareButtonKey,
              icon: Icon(Platform.isAndroid
                  ? Icons.share_outlined
                  : CupertinoIcons.share),
              onPressed: () {
                share(context, [widget.file], shareButtonKey: shareButtonKey);
              },
            ),
          ),
        ),
      );
    }
    return AnimatedOpacity(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.12),
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              ],
              stops: const [0, 0.8, 1],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: children,
          ),
        ),
      ),
      opacity: _shouldHide ? 0 : 1,
      duration: Duration(milliseconds: 150),
    );
  }

  void _addTrashOptions(List<Widget> children) {
    children.add(
      Tooltip(
        message: "Restore",
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: IconButton(
            icon: Icon(Icons.restore_outlined),
            onPressed: () {
              final selectedFiles = SelectedFiles();
              selectedFiles.toggleSelection(widget.file);
              Navigator.push(
                  context,
                  PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: CreateCollectionPage(
                        selectedFiles,
                        null,
                        actionType: CollectionActionType.restoreFiles,
                      )));
            },
          ),
        ),
      ),
    );

    children.add(
      Tooltip(
        message: "Delete",
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: IconButton(
            icon: Icon(Icons.delete_forever_outlined),
            onPressed: () async {
              final trashedFile = <TrashFile>[];
              trashedFile.add(widget.file);
              if (await deleteFromTrash(context, trashedFile) == true) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _displayInfo(File file) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return FileInfoWidget(file);
      },
    );
  }
}
