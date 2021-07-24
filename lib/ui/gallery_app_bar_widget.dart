import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:page_transition/page_transition.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/create_collection_page.dart';
import 'package:photos/ui/share_collection_widget.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

enum GalleryAppBarType {
  homepage,
  local_folder,
  shared_collection,
  collection,
  search_results,
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
    List<Widget> actions = List<Widget>();
    if (Configuration.instance.hasConfiguredAccount() &&
        (widget.type == GalleryAppBarType.local_folder ||
            widget.type == GalleryAppBarType.collection)) {
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
    if (collection == null) {
      if (widget.type == GalleryAppBarType.local_folder) {
        collection =
            CollectionsService.instance.getCollectionForPath(widget.path);
        if (collection == null) {
          final dialog = createProgressDialog(context, "please wait...");
          await dialog.show();
          try {
            collection = await CollectionsService.instance
                .getOrCreateForPath(widget.path);
            await dialog.hide();
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
    }
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

  List<Widget> _getActions(BuildContext context) {
    List<Widget> actions = List<Widget>();
    if (Configuration.instance.hasConfiguredAccount()) {
      actions.add(IconButton(
        icon:
            Icon(Platform.isAndroid ? Icons.add_outlined : CupertinoIcons.add),
        onPressed: () {
          _createAlbum();
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
        widget.type == GalleryAppBarType.local_folder) {
      actions.add(IconButton(
        icon: Icon(
            Platform.isAndroid ? Icons.delete_outline : CupertinoIcons.delete),
        onPressed: () {
          _showDeleteSheet(context);
        },
      ));
    } else if (widget.type == GalleryAppBarType.collection ||
        (widget.type == GalleryAppBarType.shared_collection &&
            widget.collection.owner.id == Configuration.instance.getUserID())) {
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
    return actions;
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
    final actions = List<Widget>();
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
