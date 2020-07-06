import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/file_db.dart';
import 'package:photos/events/remote_sync_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/file_repository.dart';
import 'package:photos/ui/setup_page.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/ui/share_folder_widget.dart';
import 'package:photos/utils/share_util.dart';

enum GalleryAppBarType {
  homepage,
  local_folder,
  remote_folder,
}

class GalleryAppBarWidget extends StatefulWidget
    implements PreferredSizeWidget {
  final GalleryAppBarType type;
  final String title;
  final String path;
  final Set<File> selectedFiles;
  final Function() onSelectionClear;

  GalleryAppBarWidget(this.type, this.title, this.path, this.selectedFiles,
      {this.onSelectionClear});

  @override
  _GalleryAppBarWidgetState createState() => _GalleryAppBarWidgetState();

  @override
  Size get preferredSize => Size.fromHeight(60.0);
}

class _GalleryAppBarWidgetState extends State<GalleryAppBarWidget> {
  bool _hasSyncErrors = false;
  StreamSubscription<RemoteSyncEvent> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<RemoteSyncEvent>().listen((event) {
      setState(() {
        _hasSyncErrors = !event.success;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedFiles.isEmpty) {
      return AppBar(
        title: Text(widget.title),
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
      title: Text(widget.selectedFiles.length.toString()),
      actions: _getActions(context),
    );
  }

  List<Widget> _getDefaultActions(BuildContext context) {
    List<Widget> actions = List<Widget>();
    if (_hasSyncErrors || !Configuration.instance.hasConfiguredAccount()) {
      actions.add(IconButton(
        icon: Icon(Configuration.instance.hasConfiguredAccount()
            ? Icons.sync_problem
            : Icons.sync_disabled),
        onPressed: () {
          _openSyncConfiguration(context);
        },
      ));
    } else if (widget.type == GalleryAppBarType.local_folder &&
        widget.title != "Favorites") {
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
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return ShareFolderWidget(widget.title, widget.path);
      },
    );
  }

  List<Widget> _getActions(BuildContext context) {
    List<Widget> actions = List<Widget>();
    if (widget.selectedFiles.isNotEmpty) {
      if (widget.type != GalleryAppBarType.remote_folder) {
        actions.add(IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            _showDeleteSheet(context);
          },
        ));
      }
      actions.add(IconButton(
        icon: Icon(Icons.share),
        onPressed: () {
          _shareSelected(context);
        },
      ));
    }
    return actions;
  }

  void _shareSelected(BuildContext context) {
    shareMultiple(widget.selectedFiles.toList());
  }

  void _showDeleteSheet(BuildContext context) {
    final action = CupertinoActionSheet(
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Delete on device"),
          isDestructiveAction: true,
          onPressed: () async {
            await _deleteSelected(context, false);
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Delete everywhere [WiP]"),
          isDestructiveAction: true,
          onPressed: () async {
            await _deleteSelected(context, true);
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (_) => action);
  }

  Future _deleteSelected(BuildContext context, bool deleteEverywhere) async {
    await PhotoManager.editor
        .deleteWithIds(widget.selectedFiles.map((p) => p.localId).toList());

    for (File file in widget.selectedFiles) {
      deleteEverywhere
          ? await FileDB.instance.markForDeletion(file)
          : await FileDB.instance.delete(file);
    }
    Navigator.of(context, rootNavigator: true).pop();
    FileRepository.instance.reloadFiles();
    _clearSelectedFiles();
  }

  void _clearSelectedFiles() {
    setState(() {
      widget.selectedFiles.clear();
    });
    if (widget.onSelectionClear != null) {
      widget.onSelectionClear();
    }
  }

  void _openSyncConfiguration(BuildContext context) {
    final page = SetupPage();
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: "/setup"),
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
