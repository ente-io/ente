// @dart=2.9

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:page_transition/page_transition.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/models/trash_file.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/create_collection_page.dart';
import 'package:photos/ui/viewer/file/file_info_widget.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/share_util.dart';

class FadingBottomBar extends StatefulWidget {
  final File file;
  final Function(File) onEditRequested;
  final bool showOnlyInfoButton;

  const FadingBottomBar(
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
    final List<Widget> children = [];
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
              await _displayInfo(widget.file);
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
    bool isUploadedByUser = widget.file.uploadedFileID != null &&
        widget.file.ownerID == Configuration.instance.getUserID();
    bool isFileHidden = false;
    if (isUploadedByUser) {
      isFileHidden = CollectionsService.instance
              .getCollectionByID(widget.file.collectionID)
              ?.isHidden() ??
          false;
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
      if (isUploadedByUser && !isFileHidden) {
        final bool isArchived =
            widget.file.magicMetadata.visibility == visibilityArchive;
        children.add(
          Tooltip(
            message: isArchived ? "Unarchive" : "Archive",
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: IconButton(
                icon: Icon(
                  isArchived ? Icons.unarchive : Icons.archive_outlined,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await changeVisibility(
                    context,
                    [widget.file],
                    isArchived ? visibilityVisible : visibilityArchive,
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
    return IgnorePointer(
      ignoring: _shouldHide,
      child: AnimatedOpacity(
        opacity: _shouldHide ? 0 : 1,
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
                  widget.file.caption.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            28,
                            16,
                            12,
                          ),
                          child: Text(
                            widget.file.caption,
                            style: getEnteTextTheme(context)
                                .small
                                .copyWith(color: textBaseDark),
                            textAlign: TextAlign.center,
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
  }

  void _addTrashOptions(List<Widget> children) {
    children.add(
      Tooltip(
        message: "Restore",
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
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.bottomToTop,
                  child: CreateCollectionPage(
                    selectedFiles,
                    null,
                    actionType: CollectionActionType.restoreFiles,
                  ),
                ),
              );
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
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.white,
            ),
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
    final colorScheme = getEnteColorScheme(context);
    return showBarModalBottomSheet(
      topControl: const SizedBox.shrink(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      backgroundColor: colorScheme.backgroundBase,
      barrierColor: backdropFaintDark,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: FileInfoWidget(file),
        );
      },
    );
  }
}
