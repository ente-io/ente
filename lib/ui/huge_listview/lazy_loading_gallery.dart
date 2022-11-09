// @dart=2.9

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/huge_listview/place_holder_widget.dart';
import 'package:photos/ui/viewer/file/detail_page.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LazyLoadingGallery extends StatefulWidget {
  final List<File> files;
  final int index;
  final Stream<FilesUpdatedEvent> reloadEvent;
  final Set<EventType> removalEventTypes;
  final GalleryLoader asyncLoader;
  final SelectedFiles selectedFiles;
  final String tag;
  final Stream<int> currentIndexStream;
  final bool smallerTodayFont;

  LazyLoadingGallery(
    this.files,
    this.index,
    this.reloadEvent,
    this.removalEventTypes,
    this.asyncLoader,
    this.selectedFiles,
    this.tag,
    this.currentIndexStream, {
    this.smallerTodayFont,
    Key key,
  }) : super(key: key ?? UniqueKey());

  @override
  State<LazyLoadingGallery> createState() => _LazyLoadingGalleryState();
}

class _LazyLoadingGalleryState extends State<LazyLoadingGallery> {
  static const kSubGalleryItemLimit = 80;
  static const kRecycleLimit = 400;
  static const kNumberOfDaysToRenderBeforeAndAfter = 8;

  static final Logger _logger = Logger("LazyLoadingGallery");

  List<File> _files;
  StreamSubscription<FilesUpdatedEvent> _reloadEventSubscription;
  StreamSubscription<int> _currentIndexSubscription;
  bool _shouldRender;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    _shouldRender = true;
    _files = widget.files;

    _reloadEventSubscription = widget.reloadEvent.listen((e) => _onReload(e));

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
        DateTime.fromMicrosecondsSinceEpoch(_files[0].creationTime);
    final filesUpdatedThisDay = event.updatedFiles.where((file) {
      final fileDate = DateTime.fromMicrosecondsSinceEpoch(file.creationTime);
      return fileDate.year == galleryDate.year &&
          fileDate.month == galleryDate.month &&
          fileDate.day == galleryDate.day;
    });
    if (filesUpdatedThisDay.isNotEmpty) {
      _logger.info(
        filesUpdatedThisDay.length.toString() +
            " files were updated on " +
            getDayTitle(galleryDate.microsecondsSinceEpoch),
      );
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
        final updateFileIDs = <int>{};
        for (final file in filesUpdatedThisDay) {
          updateFileIDs.add(file.generatedID);
        }
        final List<File> files = [];
        files.addAll(_files);
        files.removeWhere((file) => updateFileIDs.contains(file.generatedID));
        if (mounted) {
          setState(() {
            _files = files;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _reloadEventSubscription.cancel();
    _currentIndexSubscription.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(LazyLoadingGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(_files, widget.files)) {
      _reloadEventSubscription.cancel();
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
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              getDayWidget(
                context,
                _files[0].creationTime,
                widget.smallerTodayFont,
              ),
              GestureDetector(
                child: Icon(
                  Icons.check_circle_outlined,
                  color: getEnteColorScheme(context).strokeMuted,
                  size: 18,
                ),
              )
            ],
          ),
        ),
        _shouldRender ? _getGallery() : PlaceHolderWidget(_files.length),
      ],
    );
  }

  Widget _getGallery() {
    final List<Widget> childGalleries = [];
    for (int index = 0; index < _files.length; index += kSubGalleryItemLimit) {
      childGalleries.add(
        LazyLoadingGridView(
          widget.tag,
          _files.sublist(
            index,
            min(index + kSubGalleryItemLimit, _files.length),
          ),
          widget.asyncLoader,
          widget.selectedFiles,
          index == 0,
          _files.length > kRecycleLimit,
        ),
      );
    }

    return Column(
      children: childGalleries,
    );
  }
}

class LazyLoadingGridView extends StatefulWidget {
  final String tag;
  final List<File> files;
  final GalleryLoader asyncLoader;
  final SelectedFiles selectedFiles;
  final bool shouldRender;
  final bool shouldRecycle;

  LazyLoadingGridView(
    this.tag,
    this.files,
    this.asyncLoader,
    this.selectedFiles,
    this.shouldRender,
    this.shouldRecycle, {
    Key key,
  }) : super(key: key ?? UniqueKey());

  @override
  State<LazyLoadingGridView> createState() => _LazyLoadingGridViewState();
}

class _LazyLoadingGridViewState extends State<LazyLoadingGridView> {
  bool _shouldRender;

  @override
  void initState() {
    super.initState();
    _shouldRender = widget.shouldRender;
    widget.selectedFiles.addListener(() {
      bool shouldRefresh = false;
      for (final file in widget.files) {
        if (widget.selectedFiles.isPartOfLastSection(file)) {
          shouldRefresh = true;
        }
      }
      if (shouldRefresh && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(LazyLoadingGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.files, oldWidget.files)) {
      _shouldRender = widget.shouldRender;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shouldRecycle) {
      return _getRecyclableView();
    } else {
      return _getNonRecyclableView();
    }
  }

  Widget _getRecyclableView() {
    return VisibilityDetector(
      key: UniqueKey(),
      onVisibilityChanged: (visibility) {
        final shouldRender = visibility.visibleFraction > 0;
        if (mounted && shouldRender != _shouldRender) {
          setState(() {
            _shouldRender = shouldRender;
          });
        }
      },
      child: _shouldRender
          ? _getGridView()
          : PlaceHolderWidget(widget.files.length),
    );
  }

  Widget _getNonRecyclableView() {
    if (!_shouldRender) {
      return VisibilityDetector(
        key: UniqueKey(),
        onVisibilityChanged: (visibility) {
          if (mounted && visibility.visibleFraction > 0 && !_shouldRender) {
            setState(() {
              _shouldRender = true;
            });
          }
        },
        child: PlaceHolderWidget(widget.files.length),
      );
    } else {
      return _getGridView();
    }
  }

  Widget _getGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // to disable GridView's scrolling
      itemBuilder: (context, index) {
        return _buildFile(context, widget.files[index]);
      },
      itemCount: widget.files.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      padding: const EdgeInsets.all(0),
    );
  }

  Widget _buildFile(BuildContext context, File file) {
    return GestureDetector(
      onTap: () {
        if (widget.selectedFiles.files.isNotEmpty) {
          _selectFile(file);
        } else {
          _routeToDetailPage(file, context);
        }
      },
      onLongPress: () {
        HapticFeedback.lightImpact();
        _selectFile(file);
      },
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Hero(
                tag: widget.tag + file.tag,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(
                      widget.selectedFiles.isFileSelected(file) ? 0.4 : 0,
                    ),
                    BlendMode.darken,
                  ),
                  child: ThumbnailWidget(
                    file,
                    diskLoadDeferDuration: thumbnailDiskLoadDeferDuration,
                    serverLoadDeferDuration: thumbnailServerLoadDeferDuration,
                    shouldShowLivePhotoOverlay: true,
                    key: Key(widget.tag + file.tag),
                  ),
                ),
              ),
              Visibility(
                visible: widget.selectedFiles.isFileSelected(file),
                child: const Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: Colors.white, //same for both themes
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _selectFile(File file) {
    widget.selectedFiles.toggleSelection(file);
  }

  void _routeToDetailPage(File file, BuildContext context) {
    final page = DetailPage(
      DetailPageConfiguration(
        List.unmodifiable(widget.files),
        widget.asyncLoader,
        widget.files.indexOf(file),
        widget.tag,
      ),
    );
    routeToPage(context, page, forceCustomPageRoute: true);
  }
}
