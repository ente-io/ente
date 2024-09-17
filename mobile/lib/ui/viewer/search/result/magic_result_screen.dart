import "dart:async";

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/events/magic_sort_change_event.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class MagicResultScreen extends StatefulWidget {
  ///This widget expects [files] to be sorted by most relelvant first to the
  ///magic search query.
  final List<EnteFile> files;
  final String name;
  final String heroTag;
  final bool enableGrouping;

  static const GalleryType appBarType = GalleryType.magic;
  static const GalleryType overlayType = GalleryType.magic;

  const MagicResultScreen(
    this.files, {
    required this.name,
    this.enableGrouping = false,
    this.heroTag = "",
    super.key,
  });

  @override
  State<MagicResultScreen> createState() => _MagicResultScreenState();
}

class _MagicResultScreenState extends State<MagicResultScreen> {
  final _selectedFiles = SelectedFiles();
  late final List<EnteFile> files;
  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdatedEvent;
  late final StreamSubscription<MagicSortChangeEvent> _magicSortChangeEvent;
  bool _enableGrouping = false;

  @override
  void initState() {
    super.initState();
    files = widget.files;
    _enableGrouping = widget.enableGrouping;
    _filesUpdatedEvent =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      if (event.type == EventType.deletedFromDevice ||
          event.type == EventType.deletedFromEverywhere ||
          event.type == EventType.deletedFromRemote ||
          event.type == EventType.hide) {
        for (var updatedFile in event.updatedFiles) {
          files.remove(updatedFile);
        }
        setState(() {});
      }
    });

    _magicSortChangeEvent =
        Bus.instance.on<MagicSortChangeEvent>().listen((event) {
      if (event.sortType == MagicSortType.mostRelevant) {
        setState(() {
          _enableGrouping = false;
        });
      } else if (event.sortType == MagicSortType.mostRecent) {
        setState(() {
          _enableGrouping = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _filesUpdatedEvent.cancel();
    _magicSortChangeEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = Gallery(
      key: ValueKey(_enableGrouping),
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        final result = files
            .where(
              (file) =>
                  file.creationTime! >= creationStartTime &&
                  file.creationTime! <= creationEndTime,
            )
            .toList();
        return Future.value(
          FileLoadResult(
            result,
            result.length < files.length,
          ),
        );
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: widget.heroTag,
      selectedFiles: _selectedFiles,
      enableFileGrouping: _enableGrouping,
      initialFiles: [files.first],
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          MagicResultScreen.appBarType,
          widget.name,
          _selectedFiles,
        ),
      ),
      body: SelectionState(
        selectedFiles: _selectedFiles,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOutQuad,
              switchOutCurve: Curves.easeInOutQuad,
              child: gallery,
            ),
            FileSelectionOverlayBar(
              MagicResultScreen.overlayType,
              _selectedFiles,
            ),
          ],
        ),
      ),
    );
  }
}
