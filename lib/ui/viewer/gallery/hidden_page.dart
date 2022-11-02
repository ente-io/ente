// @dart=2.9

import 'package:flutter/material.dart';

import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import 'package:photos/ui/viewer/gallery/gallery_overlay_widget.dart';

class HiddenPage extends StatelessWidget {
  final String tagPrefix;
  final GalleryType appBarType;
  final GalleryType overlayType;
  final _selectedFiles = SelectedFiles();

  HiddenPage({
    this.tagPrefix = "hidden_page",
    this.appBarType = GalleryType.hidden,
    this.overlayType = GalleryType.hidden,
    Key key,
  }) : super(key: key);

  @override
  Widget build(Object context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getFilesInCollections(
          CollectionsService.instance.getHiddenCollections().toList(),
          creationStartTime,
          creationEndTime,
          Configuration.instance.getUserID(),
          limit: limit,
          asc: asc,
        );
      },
      reloadEvent: Bus.instance.on<FilesUpdatedEvent>().where(
            (event) =>
                event.updatedFiles.firstWhere(
                  (element) => element.uploadedFileID != null,
                  orElse: () => null,
                ) !=
                null,
          ),
      removalEventTypes: const {EventType.unhide},
      forceReloadEvents: [
        Bus.instance.on<FilesUpdatedEvent>().where(
              (event) =>
                  event.updatedFiles.firstWhere(
                    (element) => element.uploadedFileID != null,
                    orElse: () => null,
                  ) !=
                  null,
            ),
      ],
      tagPrefix: tagPrefix,
      selectedFiles: _selectedFiles,
      initialFiles: null,
      emptyState: const HiddenEmptyWidget(),
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          appBarType,
          "Hidden",
          _selectedFiles,
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          gallery,
          GalleryOverlayWidget(
            overlayType,
            _selectedFiles,
          )
        ],
      ),
    );
  }
}

class HiddenEmptyWidget extends StatelessWidget {
  const HiddenEmptyWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off,
            color: Theme.of(context).iconTheme.color.withOpacity(0.1),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            "No hidden photos or videos",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .defaultTextColor
                  .withOpacity(0.2),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 36),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HiddenEmptyStateTextWidget("To hide a photo or video"),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HiddenEmptyStateTextWidget("• Open the item"),
                    const SizedBox(height: 2),
                    const HiddenEmptyStateTextWidget(
                      "• Click on the overflow menu",
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          const HiddenEmptyStateTextWidget("• Click "),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.visibility_off,
                            color: Theme.of(context)
                                .iconTheme
                                .color
                                .withOpacity(0.7),
                            size: 16,
                          ),
                          const Padding(
                            padding: EdgeInsets.all(4),
                          ),
                          Text(
                            "Hide",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .defaultTextColor
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HiddenEmptyStateTextWidget extends StatelessWidget {
  final String text;

  const HiddenEmptyStateTextWidget(
    this.text, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Theme.of(context).colorScheme.defaultTextColor.withOpacity(0.35),
      ),
    );
  }
}
