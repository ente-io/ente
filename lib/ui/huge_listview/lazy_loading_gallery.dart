import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/detail_page.dart';
import 'package:photos/ui/huge_listview/place_holder_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LazyLoadingGallery extends StatefulWidget {
  final List<File> allFiles;
  final List<File> files;
  final int index;
  final Stream<FilesUpdatedEvent> reloadEvent;
  final Future<List<File>> Function(int creationStartTime, int creationEndTime,
      {int limit}) asyncLoader;
  final SelectedFiles selectedFiles;
  final String tag;
  final Stream<int> currentIndexStream;

  LazyLoadingGallery(
    this.allFiles,
    this.files,
    this.index,
    this.reloadEvent,
    this.asyncLoader,
    this.selectedFiles,
    this.tag,
    this.currentIndexStream, {
    Key key,
  }) : super(key: key);

  @override
  _LazyLoadingGalleryState createState() => _LazyLoadingGalleryState();
}

class _LazyLoadingGalleryState extends State<LazyLoadingGallery> {
  static const kSubGalleryItemLimit = 80;
  static const kRecycleLimit = 400;
  static const kMicroSecondsInADay = 86400000000;
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
      bool shouldRender = (currentIndex - widget.index).abs() <
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
    final filesUpdatedThisDay = event.updatedFiles
        .where((file) =>
            file.creationTime !=
            null) // Filtering out noise of deleted files diff from server
        .where((file) {
      final fileDate = DateTime.fromMicrosecondsSinceEpoch(file.creationTime);
      return fileDate.year == galleryDate.year &&
          fileDate.month == galleryDate.month &&
          fileDate.day == galleryDate.day;
    });
    if (filesUpdatedThisDay.isNotEmpty) {
      _logger.info(filesUpdatedThisDay.length.toString() +
          " files were updated on " +
          getDayTitle(galleryDate.microsecondsSinceEpoch));
      if (event.type == EventType.added_or_updated) {
        final dayStartTime =
            DateTime(galleryDate.year, galleryDate.month, galleryDate.day);
        final files = await widget.asyncLoader(
            dayStartTime.microsecondsSinceEpoch,
            dayStartTime.microsecondsSinceEpoch + kMicroSecondsInADay - 1);
        if (files.isEmpty) {
          // All files on this day were deleted, let gallery trigger the reload
        } else {
          if (mounted) {
            setState(() {
              _files = files;
            });
          }
        }
      } else {
        // Files were deleted
        final updateFileIDs = Set<int>();
        for (final file in filesUpdatedThisDay) {
          updateFileIDs.add(file.generatedID);
        }
        final List<File> files = [];
        files.addAll(_files);
        files.removeWhere((file) => updateFileIDs.contains(file.generatedID));
        if (files.isNotEmpty && mounted) {
          // If all files on this day were deleted, ignore and let the gallery reload itself
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
      setState(() {
        _reloadEventSubscription.cancel();
        _init();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_files.length == 0) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          getDayWidget(_files[0].creationTime),
          _shouldRender ? _getGallery() : PlaceHolderWidget(_files.length),
        ],
      ),
    );
  }

  Widget _getGallery() {
    List<Widget> childGalleries = [];
    for (int index = 0; index < _files.length; index += kSubGalleryItemLimit) {
      childGalleries.add(LazyLoadingGridView(
        widget.tag,
        widget.allFiles,
        _files.sublist(index, min(index + kSubGalleryItemLimit, _files.length)),
        widget.selectedFiles,
        index == 0,
        _files.length > kRecycleLimit,
      ));
    }

    return Column(
      children: childGalleries,
    );
  }
}

class LazyLoadingGridView extends StatefulWidget {
  static const kThumbnailDiskLoadDeferDuration = Duration(milliseconds: 40);
  static const kThumbnailServerLoadDeferDuration = Duration(milliseconds: 80);

  final String tag;
  final List<File> allFiles;
  final List<File> files;
  final SelectedFiles selectedFiles;
  final bool shouldRender;
  final bool shouldRecycle;

  LazyLoadingGridView(
    this.tag,
    this.allFiles,
    this.files,
    this.selectedFiles,
    this.shouldRender,
    this.shouldRecycle, {
    Key key,
  }) : super(key: key ?? GlobalKey<_LazyLoadingGridViewState>());

  @override
  _LazyLoadingGridViewState createState() => _LazyLoadingGridViewState();
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
        if (widget.selectedFiles.lastSelections.contains(file)) {
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
      setState(() {
        _shouldRender = widget.shouldRender;
      });
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
      key: Key(widget.tag + widget.files[0].creationTime.toString()),
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
        key: Key(widget.tag + widget.files[0].creationTime.toString()),
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
          NeverScrollableScrollPhysics(), // to disable GridView's scrolling
      itemBuilder: (context, index) {
        return _buildFile(context, widget.files[index]);
      },
      itemCount: widget.files.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      padding: EdgeInsets.all(0),
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
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: widget.selectedFiles.files.contains(file)
              ? Border.all(
                  width: 4.0,
                  color: Theme.of(context).accentColor,
                )
              : null,
        ),
        child: Hero(
          tag: widget.tag + file.tag(),
          child: ThumbnailWidget(
            file,
            diskLoadDeferDuration:
                LazyLoadingGridView.kThumbnailDiskLoadDeferDuration,
            serverLoadDeferDuration:
                LazyLoadingGridView.kThumbnailServerLoadDeferDuration,
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
      widget.allFiles,
      widget.allFiles.indexOf(file),
      widget.tag,
    );
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return page;
        },
        transitionsBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation, Widget child) {
          return Align(
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 200),
        opaque: false,
      ),
    );
  }
}
