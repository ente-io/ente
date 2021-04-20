import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/huge_listview/place_holder_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LazyLoadingGallery extends StatelessWidget {
  static const kSubGalleryItemLimit = 80;
  static final _logger = Logger("LazyLoadingDayGallery");
  final files;
  final selectedFiles;
  final tag;
  LazyLoadingGallery(this.files, this.selectedFiles, this.tag, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        getDayWidget(files[0].creationTime),
        _getGallery(files),
      ],
    );
  }

  Widget _getGallery(List<File> files) {
    _logger.info("Building sub gallery of length: " + files.length.toString());
    List<Widget> childGalleries = [];
    for (int index = 0; index < files.length; index += kSubGalleryItemLimit) {
      childGalleries.add(LazyLoadingGridView(
        tag,
        files.sublist(index, min(index + kSubGalleryItemLimit, files.length)),
        selectedFiles,
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
  final selectedFiles;

  LazyLoadingGridView(this.tag, this.files, this.selectedFiles, {Key key})
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
    // TODO
    // final page = DetailPage(
    //   _files,
    //   _files.indexOf(file),
    //   widget.tagPrefix,
    // );
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (BuildContext context) {
    //       return page;
    //     },
    //   ),
    // );
  }
}
