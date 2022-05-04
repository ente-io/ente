import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_trash_page_event.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/models/trash_file.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/gallery_overlay_widget.dart';

class TrashPage extends StatelessWidget {
  final String tagPrefix;
  final GalleryAppBarType appBarType;
  final GalleryOverlayType overlayType;
  final _selectedFiles = SelectedFiles();

  TrashPage({
    this.tagPrefix = "trash_page",
    this.appBarType = GalleryAppBarType.trash,
    this.overlayType = GalleryOverlayType.trash,
    Key key,
  }) : super(key: key);

  @override
  Widget build(Object context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return TrashDB.instance.getTrashedFiles(
            creationStartTime, creationEndTime,
            limit: limit, asc: asc);
      },
      reloadEvent: Bus.instance.on<FilesUpdatedEvent>().where(
            (event) =>
                event.updatedFiles.firstWhere(
                    (element) => element.uploadedFileID != null,
                    orElse: () => null) !=
                null,
          ),
      forceReloadEvents: [
        Bus.instance.on<ForceReloadTrashPageEvent>(),
      ],
      tagPrefix: tagPrefix,
      selectedFiles: _selectedFiles,
      header: _headerWidget(),
      initialFiles: null,
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          appBarType,
          "Trash",
          _selectedFiles,
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          gallery,
          GalleryOverflowWidget(
            overlayType,
            "Trash",
            _selectedFiles,
          )
        ],
      ),
    );
  }

  Widget _headerWidget() {
    return FutureBuilder<TrashFile>(
      future: TrashDB.instance.getRecentlyTrashedFile(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Items show the number the days remaining before permanent deletion',
              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }
}
