import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/events/event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/detail_page.dart';
import 'package:photos/ui/huge_listview/place_holder_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LazyLoadingGallery extends StatefulWidget {
  final List<File> files;
  final Stream<Event> reloadEvent;
  final Future<List<File>> Function(int creationStartTime, int creationEndTime,
      {int limit}) asyncLoader;
  final SelectedFiles selectedFiles;
  final String tag;

  LazyLoadingGallery(this.files, this.reloadEvent, this.asyncLoader,
      this.selectedFiles, this.tag,
      {Key key})
      : super(key: key);

  @override
  _LazyLoadingGalleryState createState() => _LazyLoadingGalleryState();
}

class _LazyLoadingGalleryState extends State<LazyLoadingGallery> {
  static const kSubGalleryItemLimit = 80;
  static const kMicroSecondsInADay = 86400000000;

  static final Logger _logger = Logger("LazyLoadingGallery");

  List<File> _files;

  @override
  void initState() {
    super.initState();
    _files = widget.files;
    final galleryDate =
        DateTime.fromMicrosecondsSinceEpoch(_files[0].creationTime);
    widget.reloadEvent.listen((event) async {
      if (event is LocalPhotosUpdatedEvent) {
        bool isOnSameDay = event.updatedFiles.where((file) {
          final fileDate =
              DateTime.fromMicrosecondsSinceEpoch(file.creationTime);
          return fileDate.year == galleryDate.year &&
              fileDate.month == galleryDate.month &&
              fileDate.day == galleryDate.day;
        }).isNotEmpty;
        if (isOnSameDay) {
          final dayStartTime =
              DateTime(galleryDate.year, galleryDate.month, galleryDate.day);
          final files = await widget.asyncLoader(
              dayStartTime.microsecondsSinceEpoch,
              dayStartTime.microsecondsSinceEpoch + kMicroSecondsInADay - 1);
          if (mounted) {
            setState(() {
              _files = files;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_files.length == 0) {
      return Container();
    }
    return Column(
      children: <Widget>[
        getDayWidget(_files[0].creationTime),
        _getGallery(),
      ],
    );
  }

  Widget _getGallery() {
    List<Widget> childGalleries = [];
    for (int index = 0; index < _files.length; index += kSubGalleryItemLimit) {
      childGalleries.add(LazyLoadingGridView(
        widget.tag,
        _files.sublist(index, min(index + kSubGalleryItemLimit, _files.length)),
        widget.asyncLoader,
        widget.selectedFiles,
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: childGalleries,
      ),
    );
  }
}

class LazyLoadingGridView extends StatefulWidget {
  final tag;
  final files;
  final asyncLoader;
  final selectedFiles;

  LazyLoadingGridView(
      this.tag, this.files, this.asyncLoader, this.selectedFiles,
      {Key key})
      : super(key: key);

  @override
  _LazyLoadingGridViewState createState() => _LazyLoadingGridViewState();
}

class _LazyLoadingGridViewState extends State<LazyLoadingGridView> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return VisibilityDetector(
        key: Key(widget.tag + widget.files[0].creationTime.toString()),
        onVisibilityChanged: (visibility) {
          if (visibility.visibleFraction > 0 && !_isVisible) {
            setState(() {
              _isVisible = true;
            });
          }
        },
        child: PlaceHolderWidget(widget.files.length),
      );
    } else {
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
      );
    }
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
          child: ThumbnailWidget(file),
        ),
      ),
    );
  }

  void _selectFile(File file) {
    widget.selectedFiles.toggleSelection(file);
  }

  void _routeToDetailPage(File file, BuildContext context) {
    final page = DetailPage(
      widget.files,
      widget.asyncLoader,
      widget.files.indexOf(file),
      widget.tag,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }
}
