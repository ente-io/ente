import 'dart:ui';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_trash_page_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/common/bottom_shadow.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool filesAreSelected = _selectedFiles.files.isNotEmpty;

    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return TrashDB.instance.getTrashedFiles(
          creationStartTime,
          creationEndTime,
          limit: limit,
          asc: asc,
        );
      },
      reloadEvent: Bus.instance.on<FilesUpdatedEvent>().where(
            (event) =>
                event.updatedFiles.firstWhereOrNull(
                  (element) => element.uploadedFileID != null,
                ) !=
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
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          appBarType,
          S.of(context).trash,
          _selectedFiles,
        ),
      ),
      body: SelectionState(
        selectedFiles: _selectedFiles,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            gallery,
            const BottomShadowWidget(
              offsetDy: 20,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: filesAreSelected ? 0 : 80,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: filesAreSelected ? 0.0 : 1.0,
                curve: Curves.easeIn,
                child: IgnorePointer(
                  ignoring: filesAreSelected,
                  child: const SafeArea(
                    minimum: EdgeInsets.only(bottom: 6),
                    child: BottomButtonsWidget(),
                  ),
                ),
              ),
            ),
            FileSelectionOverlayBar(GalleryType.trash, _selectedFiles),
          ],
        ),
      ),
    );
  }

  Widget _headerWidget() {
    return FutureBuilder<int>(
      future: TrashDB.instance.count(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data! > 0) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              S
                  .of(context)
                  .itemsShowTheNumberOfDaysRemainingBeforePermanentDeletion,
              style:
                  Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 16),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class BottomButtonsWidget extends StatelessWidget {
  const BottomButtonsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 40,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(255, 101, 101, 0.2),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16,
                    ),
                    child: Text(
                      S.of(context).deleteAll,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: const Color.fromRGBO(255, 101, 101, 1),
                          ),
                    ),
                  ),
                ),
              ),
            ),
            onTap: () async {
              await emptyTrash(context);
            },
          ),
        ),
      ],
    );
  }
}
