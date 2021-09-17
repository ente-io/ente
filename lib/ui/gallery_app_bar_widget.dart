import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:page_transition/page_transition.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file_magic_metadata.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/create_collection_page.dart';
import 'package:photos/ui/share_collection_widget.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_magic_sync.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

enum GalleryAppBarType {
  homepage,
  archivedPage,
  local_folder,
  // indicator for gallery view of collections shared with the user
  shared_collection,
  owned_collection,
  search_results
}

class GalleryAppBarWidget extends StatefulWidget {
  final GalleryAppBarType type;
  final String title;
  final SelectedFiles selectedFiles;
  final String path;
  final Collection collection;

  GalleryAppBarWidget(
    this.type,
    this.title,
    this.selectedFiles, {
    this.path,
    this.collection,
  });

  @override
  _GalleryAppBarWidgetState createState() => _GalleryAppBarWidgetState();
}

class _GalleryAppBarWidgetState extends State<GalleryAppBarWidget> {
  final _logger = Logger("GalleryAppBar");
  StreamSubscription _userAuthEventSubscription;
  Function() _selectedFilesListener;

  @override
  void initState() {
    _selectedFilesListener = () {
      setState(() {});
    };
    widget.selectedFiles.addListener(_selectedFilesListener);
    _userAuthEventSubscription =
        Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _userAuthEventSubscription.cancel();
    widget.selectedFiles.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedFiles.files.isEmpty) {
      return AppBar(
        backgroundColor: widget.type == GalleryAppBarType.homepage
            ? Color(0x00000000)
            : null,
        elevation: 0,
        title: widget.type == GalleryAppBarType.homepage
            ? Container()
            : Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.80),
                ),
              ),
        actions: _getDefaultActions(context),
      );
    }

    return AppBar(
      leading: IconButton(
        icon: Icon(Platform.isAndroid ? Icons.clear : CupertinoIcons.clear),
        onPressed: () {
          _clearSelectedFiles();
        },
      ),
      title: Text(widget.selectedFiles.files.length.toString()),
      actions: _getActions(context),
    );
  }

  List<Widget> _getDefaultActions(BuildContext context) {
    List<Widget> actions = <Widget>[];
    if (Configuration.instance.hasConfiguredAccount() &&
        (widget.type == GalleryAppBarType.local_folder ||
            widget.type == GalleryAppBarType.owned_collection)) {
      actions.add(IconButton(
        icon: Icon(Icons.person_add),
        onPressed: () {
          _showShareCollectionDialog();
        },
      ));
    }
    return actions;
  }

  Future<void> _showShareCollectionDialog() async {
    var collection = widget.collection;
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    if (collection == null) {
      if (widget.type == GalleryAppBarType.local_folder) {
        collection =
            CollectionsService.instance.getCollectionForPath(widget.path);
        if (collection == null) {
          try {
            collection = await CollectionsService.instance
                .getOrCreateForPath(widget.path);
          } catch (e, s) {
            _logger.severe(e, s);
            await dialog.hide();
            showGenericErrorDialog(context);
          }
        }
      } else {
        throw Exception(
            "Cannot create a collection of type" + widget.type.toString());
      }
    } else {
      final sharees =
          await CollectionsService.instance.getSharees(collection.id);
      collection = collection.copyWith(sharees: sharees);
    }
    await dialog.hide();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SharingDialog(collection);
      },
    );
  }

  Future<void> _createAlbum() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.bottomToTop,
            child: CreateCollectionPage(
              widget.selectedFiles,
              null,
            )));
  }

  Future<void> _moveFiles() async {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.bottomToTop,
            child: CreateCollectionPage(
              widget.selectedFiles,
              null,
              actionType: CollectionActionType.moveFiles,
            )));
  }

  List<Widget> _getActions(BuildContext context) {
    List<Widget> actions = <Widget>[];
    // skip add button for incoming collection till this feature is implemented
    if (Configuration.instance.hasConfiguredAccount() &&
        widget.type != GalleryAppBarType.shared_collection) {
      actions.add(IconButton(
        icon:
            Icon(Platform.isAndroid ? Icons.add_outlined : CupertinoIcons.add),
        onPressed: () {
          _createAlbum();
        },
      ));
    }
    if (Configuration.instance.hasConfiguredAccount() &&
        widget.type == GalleryAppBarType.owned_collection) {
      actions.add(IconButton(
        icon: Icon(Platform.isAndroid
            ? Icons.arrow_right_alt_rounded
            : CupertinoIcons.arrow_right),
        onPressed: () {
          _moveFiles();
        },
      ));
    }
    actions.add(IconButton(
      icon: Icon(
          Platform.isAndroid ? Icons.share_outlined : CupertinoIcons.share),
      onPressed: () {
        _shareSelected(context);
      },
    ));
    if (widget.type == GalleryAppBarType.homepage ||
        widget.type == GalleryAppBarType.archivedPage ||
        widget.type == GalleryAppBarType.local_folder) {
      actions.add(IconButton(
        icon: Icon(
            Platform.isAndroid ? Icons.delete_outline : CupertinoIcons.delete),
        onPressed: () {
          _showDeleteSheet(context);
        },
      ));
    } else if (widget.type == GalleryAppBarType.owned_collection) {
      if (widget.collection.type == CollectionType.folder) {
        actions.add(IconButton(
          icon: Icon(Platform.isAndroid
              ? Icons.delete_outline
              : CupertinoIcons.delete),
          onPressed: () {
            _showDeleteSheet(context);
          },
        ));
      } else {
        actions.add(IconButton(
          icon: Icon(Icons.remove_circle_outline_rounded),
          onPressed: () {
            _showRemoveFromCollectionSheet(context);
          },
        ));
      }
    }

    if (widget.type == GalleryAppBarType.homepage ||
        widget.type == GalleryAppBarType.archivedPage) {
      bool showArchive = widget.type == GalleryAppBarType.homepage;
      actions.add(PopupMenuButton(
        itemBuilder: (context) {
          final List<PopupMenuItem> items = [];
          items.add(
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(Platform.isAndroid
                      ? Icons.archive_outlined
                      : CupertinoIcons.archivebox),
                  Padding(
                    padding: EdgeInsets.all(8),
                  ),
                  Text(showArchive ? "archive" : "unarchive"),
                ],
              ),
            ),
          );
          return items;
        },
        onSelected: (value) async {
          if (value == 1) {
            await _handleVisibilityChangeRequest(context, showArchive ? kVisibilityArchive : kVisibilityVisible);
          }
        },
      ));
    }
    return actions;
  }

  Future<void> _handleVisibilityChangeRequest(BuildContext context,
      int newVisibility) async {
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    try {
      await changeVisibility(
          widget.selectedFiles.files.toList(), newVisibility);
      showToast(
          newVisibility == kVisibilityArchive
              ? "successfully archived"
              : "successfully unarchived",
          toastLength: Toast.LENGTH_SHORT);

      await dialog.hide();
    } catch (e, s) {
      _logger.severe("failed to update file visibility", e, s);
      await dialog.hide();
      await showGenericErrorDialog(context);
    } finally {
      _clearSelectedFiles();
    }
  }

  void _shareSelected(BuildContext context) {
    share(context, widget.selectedFiles.files.toList());
  }

  void _showRemoveFromCollectionSheet(BuildContext context) {
    final count = widget.selectedFiles.files.length;
    final action = CupertinoActionSheet(
      title: Text("remove " +
          count.toString() +
          " file" +
          (count == 1 ? "" : "s") +
          " from " +
          widget.collection.name +
          "?"),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("remove"),
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            final dialog = createProgressDialog(context, "removing files...");
            await dialog.show();
            try {
              await CollectionsService.instance.removeFromCollection(
                  widget.collection.id, widget.selectedFiles.files.toList());
              await dialog.hide();
              widget.selectedFiles.clearAll();
            } catch (e, s) {
              _logger.severe(e, s);
              await dialog.hide();
              showGenericErrorDialog(context);
            }
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("cancel"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (_) => action);
  }

  void _showDeleteSheet(BuildContext context) {
    final count = widget.selectedFiles.files.length;
    bool containsUploadedFile = false, containsLocalFile = false;
    for (final file in widget.selectedFiles.files) {
      if (file.uploadedFileID != null) {
        containsUploadedFile = true;
      }
      if (file.localID != null) {
        containsLocalFile = true;
      }
    }
    final actions = <Widget>[];
    if (containsUploadedFile && containsLocalFile) {
      actions.add(CupertinoActionSheetAction(
        child: Text("this device"),
        isDestructiveAction: true,
        onPressed: () async {
          Navigator.of(context, rootNavigator: true).pop();
          await deleteFilesOnDeviceOnly(
              context, widget.selectedFiles.files.toList());
          _clearSelectedFiles();
          showToast("files deleted from device");
        },
      ));
      actions.add(CupertinoActionSheetAction(
        child: Text("everywhere"),
        isDestructiveAction: true,
        onPressed: () async {
          Navigator.of(context, rootNavigator: true).pop();
          await deleteFilesFromEverywhere(
              context, widget.selectedFiles.files.toList());
          _clearSelectedFiles();
        },
      ));
    } else {
      actions.add(CupertinoActionSheetAction(
        child: Text("delete forever"),
        isDestructiveAction: true,
        onPressed: () async {
          Navigator.of(context, rootNavigator: true).pop();
          await deleteFilesFromEverywhere(
              context, widget.selectedFiles.files.toList());
          _clearSelectedFiles();
        },
      ));
    }
    final action = CupertinoActionSheet(
      title: Text("delete " +
          count.toString() +
          " file" +
          (count == 1 ? "" : "s") +
          (containsUploadedFile && containsLocalFile ? " from" : "?")),
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        child: Text("cancel"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (_) => action);
  }

  void _clearSelectedFiles() {
    widget.selectedFiles.clearAll();
  }
}
