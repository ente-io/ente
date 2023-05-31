import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/viewer/gallery/component/day_widget.dart";
import 'package:photos/ui/viewer/gallery/component/grid/place_holder_grid_view_widget.dart';
import "package:photos/ui/viewer/gallery/component/group/group_gallery.dart";
import 'package:photos/ui/viewer/gallery/gallery.dart';

class LazyGroupGallery extends StatefulWidget {
  final List<File> files;
  final int index;
  final Stream<FilesUpdatedEvent>? reloadEvent;
  final Set<EventType> removalEventTypes;
  final GalleryLoader asyncLoader;
  final bool sortOrderAsc;
  final SelectedFiles? selectedFiles;
  final String tag;
  final String? logTag;
  final Stream<int> currentIndexStream;
  final int photoGridSize;
  final bool enableFileGrouping;
  final bool limitSelectionToOne;
  LazyGroupGallery(
    this.files,
    this.index,
    this.reloadEvent,
    this.removalEventTypes,
    this.asyncLoader,
    this.sortOrderAsc,
    this.selectedFiles,
    this.tag,
    this.currentIndexStream,
    this.enableFileGrouping, {
    this.logTag = "",
    this.photoGridSize = photoGridSizeDefault,
    this.limitSelectionToOne = false,
    Key? key,
  }) : super(key: key ?? UniqueKey());

  @override
  State<LazyGroupGallery> createState() => _LazyGroupGalleryState();
}

class _LazyGroupGalleryState extends State<LazyGroupGallery> {
  static const kNumberOfDaysToRenderBeforeAndAfter = 8;

  late Logger _logger;

  late List<File> _files;
  late StreamSubscription<FilesUpdatedEvent>? _reloadEventSubscription;
  late StreamSubscription<int> _currentIndexSubscription;
  bool? _shouldRender;
  final ValueNotifier<bool> _toggleSelectAllFromDay = ValueNotifier(false);
  final ValueNotifier<bool> _showSelectAllButton = ValueNotifier(false);
  final ValueNotifier<bool> _areAllFromDaySelected = ValueNotifier(false);

  @override
  void initState() {
    //this is for removing the 'select all from day' icon on unselecting all files with 'cancel'
    widget.selectedFiles?.addListener(_selectedFilesListener);
    super.initState();
    _init();
  }

  void _init() {
    _logger = Logger("LazyLoading_${widget.logTag}");
    _shouldRender = true;
    _files = widget.files;
    _reloadEventSubscription = widget.reloadEvent?.listen((e) => _onReload(e));

    _currentIndexSubscription =
        widget.currentIndexStream.listen((currentIndex) {
      final bool shouldRender = (currentIndex - widget.index).abs() <
          kNumberOfDaysToRenderBeforeAndAfter;
      if (mounted && shouldRender != _shouldRender) {
        setState(() {
          _shouldRender = shouldRender;
        });
      }
    });
  }

  Future _onReload(FilesUpdatedEvent event) async {
    final galleryDate =
        DateTime.fromMicrosecondsSinceEpoch(_files[0].creationTime!);
    final filesUpdatedThisDay = event.updatedFiles.where((file) {
      final fileDate = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      return fileDate.year == galleryDate.year &&
          fileDate.month == galleryDate.month &&
          fileDate.day == galleryDate.day;
    });
    if (filesUpdatedThisDay.isNotEmpty) {
      if (kDebugMode) {
        _logger.info(
          filesUpdatedThisDay.length.toString() +
              " files were updated due to ${event.reason} on " +
              DateTime.fromMicrosecondsSinceEpoch(
                galleryDate.microsecondsSinceEpoch,
              ).toIso8601String(),
        );
      }
      if (event.type == EventType.addedOrUpdated) {
        final dayStartTime =
            DateTime(galleryDate.year, galleryDate.month, galleryDate.day);
        final result = await widget.asyncLoader(
          dayStartTime.microsecondsSinceEpoch,
          dayStartTime.microsecondsSinceEpoch + microSecondsInDay - 1,
          asc: widget.sortOrderAsc,
        );
        if (mounted) {
          setState(() {
            _files = result.files;
          });
        }
      } else if (widget.removalEventTypes.contains(event.type)) {
        // Files were removed
        final generatedFileIDs = <int?>{};
        final uploadedFileIds = <int?>{};
        for (final file in filesUpdatedThisDay) {
          if (file.generatedID != null) {
            generatedFileIDs.add(file.generatedID);
          } else if (file.uploadedFileID != null) {
            uploadedFileIds.add(file.uploadedFileID);
          }
        }
        final List<File> files = [];
        files.addAll(_files);
        files.removeWhere(
          (file) =>
              generatedFileIDs.contains(file.generatedID) ||
              uploadedFileIds.contains(file.uploadedFileID),
        );
        if (kDebugMode) {
          _logger.finest(
            "removed ${_files.length - files.length} due to ${event.reason}",
          );
        }
        if (mounted) {
          setState(() {
            _files = files;
          });
        }
      } else {
        if (kDebugMode) {
          debugPrint("Unexpected event ${event.type.name}");
        }
      }
    }
  }

  @override
  void dispose() {
    _reloadEventSubscription?.cancel();
    _currentIndexSubscription.cancel();
    widget.selectedFiles?.removeListener(_selectedFilesListener);
    _toggleSelectAllFromDay.dispose();
    _showSelectAllButton.dispose();
    _areAllFromDaySelected.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LazyGroupGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(_files, widget.files)) {
      _reloadEventSubscription?.cancel();
      _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_files.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.enableFileGrouping)
              DayWidget(
                timestamp: _files[0].creationTime!,
                gridSize: widget.photoGridSize,
              ),
            widget.limitSelectionToOne
                ? const SizedBox.shrink()
                : ValueListenableBuilder(
                    valueListenable: _showSelectAllButton,
                    builder: (context, dynamic value, _) {
                      return !value
                          ? const SizedBox.shrink()
                          : GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              child: SizedBox(
                                width: 48,
                                height: 44,
                                child: ValueListenableBuilder(
                                  valueListenable: _areAllFromDaySelected,
                                  builder: (context, dynamic value, _) {
                                    return value
                                        ? const Icon(
                                            Icons.check_circle,
                                            size: 18,
                                          )
                                        : Icon(
                                            Icons.check_circle_outlined,
                                            color: getEnteColorScheme(context)
                                                .strokeMuted,
                                            size: 18,
                                          );
                                  },
                                ),
                              ),
                              onTap: () {
                                //this value has no significance
                                //changing only to notify the listeners
                                _toggleSelectAllFromDay.value =
                                    !_toggleSelectAllFromDay.value;
                              },
                            );
                    },
                  )
          ],
        ),
        _shouldRender!
            ? GroupGallery(
                photoGridSize: widget.photoGridSize,
                files: _files,
                tag: widget.tag,
                asyncLoader: widget.asyncLoader,
                selectedFiles: widget.selectedFiles,
                toggleSelectAllFromDay: _toggleSelectAllFromDay,
                areAllFromDaySelected: _areAllFromDaySelected,
                limitSelectionToOne: widget.limitSelectionToOne,
              )
            // todo: perf eval should we have separate PlaceHolder for Groups
            //  instead of creating a large cached view
            : PlaceHolderGridViewWidget(
                _files.length,
                widget.photoGridSize,
              ),
      ],
    );
  }

  void _selectedFilesListener() {
    if (widget.selectedFiles!.files.isEmpty) {
      _showSelectAllButton.value = false;
    } else {
      _showSelectAllButton.value = true;
    }
  }
}
