import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/trash_file.dart';
import 'package:photos/ui/file_info_dialog.dart';
import 'package:photos/utils/archive_util.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

import 'common/dialogs.dart';

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
        message: "info",
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
            message: "edit",
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
            message: isArchived ? "unarchive" : "archive",
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: IconButton(
                icon: Icon(
                  Platform.isAndroid
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
          message: "share",
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            child: IconButton(
              icon: Icon(Platform.isAndroid
                  ? Icons.share_outlined
                  : CupertinoIcons.share),
              onPressed: () {
                share(context, [widget.file]);
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
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.64),
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
        message: "restore",
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: IconButton(
            icon: Icon(Icons.restore_outlined),
            onPressed: () {
              showToast("coming soon");
            },
          ),
        ),
      ),
    );

    children.add(
      Tooltip(
        message: "delete",
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: IconButton(
            icon: Icon(Icons.delete_forever_outlined),
            onPressed: () async {
              final trashedFile = <TrashFile>[];
              trashedFile.add(widget.file);
              await deleteFromTrash(context, trashedFile);
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
