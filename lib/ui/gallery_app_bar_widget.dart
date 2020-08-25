import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/file_repository.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/email_entry_page.dart';
import 'package:photos/ui/ott_verification_page.dart';
import 'package:photos/ui/share_folder_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/share_util.dart';

enum GalleryAppBarType {
  homepage,
  local_folder,
  remote_folder,
  search_results,
}

class GalleryAppBarWidget extends StatefulWidget
    implements PreferredSizeWidget {
  final GalleryAppBarType type;
  final String title;
  final SelectedFiles selectedFiles;
  final String path;

  GalleryAppBarWidget(
    this.type,
    this.title,
    this.selectedFiles, [
    this.path,
  ]);

  @override
  _GalleryAppBarWidgetState createState() => _GalleryAppBarWidgetState();

  @override
  Size get preferredSize => Size.fromHeight(60.0);
}

class _GalleryAppBarWidgetState extends State<GalleryAppBarWidget> {
  @override
  void initState() {
    widget.selectedFiles.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedFiles.files.isEmpty) {
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
      title: Text(widget.selectedFiles.files.length.toString()),
      actions: _getActions(context),
    );
  }

  List<Widget> _getDefaultActions(BuildContext context) {
    List<Widget> actions = List<Widget>();
    if (!Configuration.instance.hasConfiguredAccount()) {
      actions.add(IconButton(
        icon: Icon(Configuration.instance.hasConfiguredAccount()
            ? Icons.sync_problem
            : Icons.sync_disabled),
        onPressed: () {
          _navigateToSignInPage(context);
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
    if (widget.selectedFiles.files.isNotEmpty) {
      if (widget.type != GalleryAppBarType.remote_folder &&
          widget.type != GalleryAppBarType.search_results) {
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
    shareMultiple(context, widget.selectedFiles.files.toList());
  }

  void _showDeleteSheet(BuildContext context) {
    final action = CupertinoActionSheet(
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Delete on device"),
          isDestructiveAction: true,
          onPressed: () {
            _deleteSelected(context, false);
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Delete everywhere [WiP]"),
          isDestructiveAction: true,
          onPressed: () {
            _deleteSelected(context, true);
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

  _deleteSelected(BuildContext context, bool deleteEveryWhere) async {
    Navigator.of(context, rootNavigator: true).pop();
    final dialog = createProgressDialog(context, "Deleting...");
    await dialog.show();
    await deleteFiles(widget.selectedFiles.files.toList(),
        deleteEveryWhere: deleteEveryWhere);
    await FileRepository.instance.reloadFiles();
    _clearSelectedFiles();
    await dialog.hide();
  }

  void _clearSelectedFiles() {
    widget.selectedFiles.clearAll();
  }

  void _navigateToSignInPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return EmailEntryPage();
        },
      ),
    );
  }
}
