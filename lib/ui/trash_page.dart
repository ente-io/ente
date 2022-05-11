import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_trash_page_event.dart';
import 'package:photos/models/galleryType.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/common/bottomShadow.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/gallery_overlay_widget.dart';

class TrashPage extends StatelessWidget {
  final String tagPrefix;
  final GalleryType appBarType;
  final GalleryType overlayType;
  final _selectedFiles = SelectedFiles();

  TrashPage({
    this.tagPrefix = "trash_page",
    this.appBarType = GalleryType.trash,
    this.overlayType = GalleryType.trash,
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
          BottomShadowWidget(),
          GalleryOverlayWidget(
            overlayType,
            _selectedFiles,
          )
        ],
      ),
    );
  }

  Widget _headerWidget() {
    return FutureBuilder<int>(
      future: TrashDB.instance.count(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data > 0) {
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
