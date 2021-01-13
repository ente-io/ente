import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:page_transition/page_transition.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/user_authenticated_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/create_collection_page.dart';
import 'package:photos/ui/share_collection_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

enum GalleryAppBarType {
  homepage,
  local_folder,
  shared_collection,
  collection,
  search_results,
}

class GalleryAppBarWidget extends StatefulWidget
    implements PreferredSizeWidget {
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

  @override
  Size get preferredSize => Size.fromHeight(60.0);
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
        Bus.instance.on<UserAuthenticatedEvent>().listen((event) {
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
        backgroundColor: Color(0x00000000),
        elevation: 0,
        title: widget.type == GalleryAppBarType.homepage
            ? Container()
            : Text(
                widget.title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.60),
                ),
              ),
        actions: _getDefaultActions(context),
      );
    }

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.close),
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
            )));
  }

  List<Widget> _getActions(BuildContext context) {
    List<Widget> actions = List<Widget>();
    actions.add(IconButton(
      icon: Icon(Icons.add),
      onPressed: () {
        _createAlbum();
      },
    ));
    actions.add(IconButton(
      icon: Icon(Icons.share),
      onPressed: () {
        _shareSelected(context);
      },
    ));
    if (widget.type == GalleryAppBarType.homepage ||
        widget.type == GalleryAppBarType.local_folder) {
      actions.add(IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          _showDeleteSheet(context);
        },
      ));
    } else if (widget.type == GalleryAppBarType.collection) {
      actions.add(PopupMenuButton(
        itemBuilder: (context) {
          return [
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.remove_circle),
                  Padding(
                    padding: EdgeInsets.all(8),
                  ),
                  Text("remove"),
                ],
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Row(
                children: [
                  Icon(Icons.delete),
                  Padding(
                    padding: EdgeInsets.all(8),
                  ),
                  Text("delete"),
                ],
              ),
            )
          ];
        },
        onSelected: (value) {
          if (value == 1) {
            _showRemoveFromCollectionSheet(context);
          } else if (value == 2) {
            _showDeleteSheet(context);
          }
        },
      ));
    }
    return actions;
  }

  void _shareSelected(BuildContext context) {
    share(context, widget.selectedFiles.files.toList());
  }

  void _showRemoveFromCollectionSheet(BuildContext context) {
    final count = widget.selectedFiles.files.length;
    final action = CupertinoActionSheet(
      title: Text("Remove " +
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
            final dialog = createProgressDialog(context, "removing files...");
            await dialog.show();
            try {
              CollectionsService.instance.removeFromCollection(
                  widget.collection.id, widget.selectedFiles.files.toList());
              await dialog.hide();
              widget.selectedFiles.clearAll();
              Navigator.of(context).pop();
            } catch (e, s) {
              _logger.severe(e, s);
              await dialog.hide();
              Navigator.of(context).pop();
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
    bool containsUploadedFile = false;
    for (final file in widget.selectedFiles.files) {
      if (file.uploadedFileID != null) {
        containsUploadedFile = true;
      }
    }
    final actions = List<Widget>();
    if (containsUploadedFile) {
      actions.add(CupertinoActionSheetAction(
        child: Text("this Device"),
        isDestructiveAction: true,
        onPressed: () async {
          await deleteFilesOnDeviceOnly(
              context, widget.selectedFiles.files.toList());
          _clearSelectedFiles();
          showToast("files deleted from device");
          Navigator.of(context, rootNavigator: true).pop();
        },
      ));
      actions.add(CupertinoActionSheetAction(
        child: Text("everywhere"),
        isDestructiveAction: true,
        onPressed: () async {
          await deleteFilesFromEverywhere(
              context, widget.selectedFiles.files.toList());
          _clearSelectedFiles();
          showToast("files deleted from everywhere");
          Navigator.of(context, rootNavigator: true).pop();
        },
      ));
    } else {
      actions.add(CupertinoActionSheetAction(
        child: Text("delete forever"),
        isDestructiveAction: true,
        onPressed: () async {
          await deleteFilesFromEverywhere(
              context, widget.selectedFiles.files.toList());
          _clearSelectedFiles();
          showToast("files deleted from everywhere");
          Navigator.of(context, rootNavigator: true).pop();
        },
      ));
    }
    final action = CupertinoActionSheet(
      title: Text("delete " +
          count.toString() +
          " file" +
          (count == 1 ? "" : "s") +
          (containsUploadedFile ? " from" : "?")),
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
