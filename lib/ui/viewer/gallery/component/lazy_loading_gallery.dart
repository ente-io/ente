import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/huge_listview/place_holder_widget.dart';
import "package:photos/ui/viewer/gallery/component/day_widget.dart";
import "package:photos/ui/viewer/gallery/component/gallery_file_widget.dart";
import 'package:photos/ui/viewer/gallery/component/lazy_loading_grid_view.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';

class LazyLoadingGallery extends StatefulWidget {
  final List<File> files;
  final int index;
  final Stream<FilesUpdatedEvent>? reloadEvent;
  final Set<EventType> removalEventTypes;
  final GalleryLoader asyncLoader;
  final SelectedFiles? selectedFiles;
  final String tag;
  final String? logTag;
  final Stream<int> currentIndexStream;
  final int photoGridSize;
  final bool areFilesCollatedByDay;
  final bool limitSelectionToOne;
  LazyLoadingGallery(
    this.files,
    this.index,
    this.reloadEvent,
    this.removalEventTypes,
    this.asyncLoader,
    this.selectedFiles,
    this.tag,
    this.currentIndexStream,
    this.areFilesCollatedByDay, {
    this.logTag = "",
    this.photoGridSize = photoGridSizeDefault,
    this.limitSelectionToOne = false,
    Key? key,
  }) : super(key: key ?? UniqueKey());

  @override
  State<LazyLoadingGallery> createState() => _LazyLoadingGalleryState();
}

class _LazyLoadingGalleryState extends State<LazyLoadingGallery> {
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
  void didUpdateWidget(LazyLoadingGallery oldWidget) {
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
            if (widget.areFilesCollatedByDay)
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
            ? GetGallery(
                photoGridSize: widget.photoGridSize,
                files: _files,
                tag: widget.tag,
                asyncLoader: widget.asyncLoader,
                selectedFiles: widget.selectedFiles,
                toggleSelectAllFromDay: _toggleSelectAllFromDay,
                areAllFromDaySelected: _areAllFromDaySelected,
                limitSelectionToOne: widget.limitSelectionToOne,
              )
            : PlaceHolderWidget(
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

class GetGallery extends StatelessWidget {
  final int photoGridSize;
  final List<File> files;
  final String tag;
  final GalleryLoader asyncLoader;
  final SelectedFiles? selectedFiles;
  final ValueNotifier<bool> toggleSelectAllFromDay;
  final ValueNotifier<bool> areAllFromDaySelected;
  final bool limitSelectionToOne;
  const GetGallery({
    required this.photoGridSize,
    required this.files,
    required this.tag,
    required this.asyncLoader,
    required this.selectedFiles,
    required this.toggleSelectAllFromDay,
    required this.areAllFromDaySelected,
    required this.limitSelectionToOne,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const kRecycleLimit = 400;
    final List<Widget> childGalleries = [];
    final subGalleryItemLimit = photoGridSize * subGalleryMultiplier;

    for (int index = 0; index < files.length; index += subGalleryItemLimit) {
      childGalleries.add(
        LazyLoadingGridView(
          tag,
          files.sublist(
            index,
            min(index + subGalleryItemLimit, files.length),
          ),
          asyncLoader,
          selectedFiles,
          index == 0,
          files.length > kRecycleLimit,
          toggleSelectAllFromDay,
          areAllFromDaySelected,
          photoGridSize,
          limitSelectionToOne: limitSelectionToOne,
        ),
      );
    }

    return Column(
      children: childGalleries,
    );
  }
}

class GalleryGridViewWidget extends StatelessWidget {
  final List<File> filesInDay;
  final int photoGridSize;
  final SelectedFiles? selectedFiles;
  final bool limitSelectionToOne;
  final String tag;
  final int? currentUserID;
  final GalleryLoader asyncLoader;
  const GalleryGridViewWidget({
    required this.filesInDay,
    required this.photoGridSize,
    this.selectedFiles,
    required this.limitSelectionToOne,
    required this.tag,
    super.key,
    this.currentUserID,
    required this.asyncLoader,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // to disable GridView's scrolling
      itemBuilder: (context, index) {
        return GalleryFileWidget(
          file: filesInDay[index],
          selectedFiles: selectedFiles,
          limitSelectionToOne: limitSelectionToOne,
          tag: tag,
          photoGridSize: photoGridSize,
          currentUserID: currentUserID,
          filesInDay: filesInDay,
          asyncLoader: asyncLoader,
        );
      },
      itemCount: filesInDay.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        crossAxisCount: photoGridSize,
      ),
      padding: const EdgeInsets.symmetric(vertical: (galleryGridSpacing / 2)),
    );
  }
}
