import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_trash_page_event.dart';
import 'package:photos/models/galleryType.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/common/bottomShadow.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/gallery_overlay_widget.dart';
import 'package:photos/utils/delete_file_util.dart';

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
          BottomButtonsWidget(),
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

class BottomButtonsWidget extends StatelessWidget {
  const BottomButtonsWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 101, 101, 0.2),
                  borderRadius: BorderRadius.circular(24)),
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Text(
                  'Delete All',
                  style: Theme.of(context).textTheme.subtitle2.copyWith(
                        color: Color.fromRGBO(255, 101, 101, 1),
                      ),
                ),
              ),
            ),
            onTap: () async {
              await emptyTrash(context);
            },
          ),
          const SizedBox(width: 16),
          Container(
            height: 40,
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .defaultTextColor
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(24)),
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Text('Restore All',
                  style: Theme.of(context).textTheme.subtitle2),
            ),
          )
        ],
      ),
    );
  }
}


// ElevatedButton(
//           style: ButtonStyle(
//             shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//               RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(24),
//               ),
//             ),
//             backgroundColor:
//                 MaterialStateProperty.all(Color.fromRGBO(255, 101, 101, 0.2)),
//           ),
//           onPressed: () {},
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
            // child: Text('Delete All',
            //     style: Theme.of(context)
            //         .textTheme
            //         .subtitle2
            //         .copyWith(color: Color.fromRGBO(255, 101, 101, 1))),
//           ),
//         ),