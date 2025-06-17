import "dart:async";
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/guest_view_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/file/trash_file.dart';
import 'package:photos/models/selected_files.dart';

import "package:photos/ui/actions/file/file_actions.dart";
import 'package:photos/ui/collections/collection_action_sheet.dart';
import 'package:photos/utils/delete_file_util.dart';
import "package:photos/utils/panorama_util.dart";
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
    super.key,
  });

  @override
  FileBottomBarState createState() => FileBottomBarState();
}

class FileBottomBarState extends State<FileBottomBar> {
  final GlobalKey shareButtonKey = GlobalKey();
  bool isGuestView = false;
  late final StreamSubscription<GuestViewEvent> _guestViewEventSubscription;
  int? lastFileGenID;

  @override
  void initState() {
    super.initState();
    _guestViewEventSubscription =
        Bus.instance.on<GuestViewEvent>().listen((event) {
      setState(() {
        isGuestView = event.isGuestView;
      });
    });
  }

  @override
  void dispose() {
    _guestViewEventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.file.canBePanorama()) {
      lastFileGenID = widget.file.generatedID;
      if (lastFileGenID != widget.file.generatedID) {
        guardedCheckPanorama(widget.file).ignore();
      }
    }

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
        message: S.of(context).info,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: IconButton(
            icon: Icon(
              Platform.isAndroid ? Icons.info_outline : CupertinoIcons.info,
              color: Colors.white,
            ),
            onPressed: () async {
              await _displayDetails(widget.file);
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
            message: S.of(context).edit,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
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
              padding: const EdgeInsets.only(top: 12),
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
            padding: const EdgeInsets.only(top: 12),
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
    return ValueListenableBuilder(
      valueListenable: widget.enableFullScreenNotifier,
      builder: (BuildContext context, bool isFullScreen, _) {
        return IgnorePointer(
          ignoring: isFullScreen || isGuestView,
          child: AnimatedOpacity(
            opacity: isFullScreen || isGuestView ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0, 0.8, 1],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: children,
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
          padding: const EdgeInsets.only(top: 12),
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
          padding: const EdgeInsets.only(top: 12),
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
