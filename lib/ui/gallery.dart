import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/events/event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/detail_page.dart';
import 'package:photos/ui/draggable_scrollbar.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class Gallery extends StatefulWidget {
  final List<File> Function() syncLoader;
  final Future<List<File>> Function(File lastFile, int limit) asyncLoader;
  final bool shouldLoadAll;
  final Stream<Event> reloadEvent;
  final SelectedFiles selectedFiles;
  final String tagPrefix;
  final Widget headerWidget;
  final bool isHomePageGallery;

  Gallery({
    this.syncLoader,
    this.asyncLoader,
    this.shouldLoadAll = false,
    this.reloadEvent,
    this.headerWidget,
    @required this.selectedFiles,
    @required this.tagPrefix,
    this.isHomePageGallery,
  });

  @override
  _GalleryState createState() {
    return _GalleryState();
  }
}

class _GalleryState extends State<Gallery> {
  static final int kLoadLimit = 200;
  static final int kEagerLoadTrigger = 10;

  final Logger _logger = Logger("Gallery");
  final List<List<File>> _collatedFiles = List<List<File>>();
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();
  final _scrollKey = GlobalKey<DraggableScrollbarState>();

  ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _requiresLoad = false;
  bool _hasLoadedAll = false;
  bool _isLoadingNext = false;
  bool _hasDraggableScrollbar = false;
  List<File> _files;
  int _lastIndex = 0;

  @override
  void initState() {
    _requiresLoad = true;
    if (widget.reloadEvent != null) {
      widget.reloadEvent.listen((event) {
        _logger.info("Building gallery because reload event fired updated");
        if (mounted) {
          setState(() {
            _requiresLoad = true;
          });
        }
      });
    }
    widget.selectedFiles.addListener(() {
      _logger.info("Building gallery because selected files updated");
      setState(() {
        _requiresLoad = false;
        if (!_hasDraggableScrollbar) {
          _saveScrollPosition();
        }
      });
    });
    if (widget.asyncLoader == null || widget.shouldLoadAll) {
      _hasLoadedAll = true;
    }
    _itemPositionsListener.itemPositions.addListener(_updateScrollbar);
    super.initState();
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_updateScrollbar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("Building " + widget.tagPrefix);
    if (!_requiresLoad) {
      return _onDataLoaded();
    }
    if (widget.syncLoader != null) {
      _files = widget.syncLoader();
      return _onDataLoaded();
    }
    return FutureBuilder<List<File>>(
      future: widget.asyncLoader(null, kLoadLimit),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _requiresLoad = false;
          _files = snapshot.data;
          return _onDataLoaded();
        } else if (snapshot.hasError) {
          _requiresLoad = false;
          return Center(child: Text(snapshot.error.toString()));
        } else {
          return Center(child: loadWidget);
        }
      },
    );
  }

  Widget _onDataLoaded() {
    if (_files.isEmpty) {
      final children = List<Widget>();
      if (widget.headerWidget != null) {
        children.add(widget.headerWidget);
      }
      children.add(Expanded(child: nothingToSeeHere));
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: children,
            ),
          )
        ],
      );
    }
    _collateFiles();
    final itemCount =
        _collatedFiles.length + (widget.headerWidget == null ? 1 : 2);
    _hasDraggableScrollbar = itemCount > 25 || _files.length > 50;
    var gallery;
    if (!_hasDraggableScrollbar) {
      _scrollController = ScrollController(initialScrollOffset: _scrollOffset);
      gallery = ListView.builder(
        itemCount: itemCount,
        itemBuilder: _buildListItem,
        controller: _scrollController,
        cacheExtent: 1500,
        addAutomaticKeepAlives: true,
      );
      return gallery;
    }
    gallery = DraggableScrollbar.semicircle(
      key: _scrollKey,
      initialScrollIndex: _lastIndex,
      labelTextBuilder: (position) {
        final index =
            min((position * itemCount).floor(), _collatedFiles.length - 1);
        return Text(
          getMonthAndYear(DateTime.fromMicrosecondsSinceEpoch(
              _collatedFiles[index][0].creationTime)),
          style: TextStyle(
            color: Colors.black,
            backgroundColor: Colors.white,
            fontSize: 14,
          ),
        );
      },
      labelConstraints: BoxConstraints.tightFor(width: 100.0, height: 36.0),
      onChange: (position) {
        final index =
            min((position * itemCount).floor(), _collatedFiles.length - 1);
        if (index == _lastIndex) {
          return;
        }
        _lastIndex = index;
        _itemScrollController.jumpTo(index: index);
      },
      child: ScrollablePositionedList.builder(
        itemCount: itemCount,
        itemBuilder: _buildListItem,
        itemScrollController: _itemScrollController,
        initialScrollIndex: _lastIndex,
        minCacheExtent: 1500,
        addAutomaticKeepAlives: true,
        physics: _MaxVelocityPhysics(velocityThreshold: 128),
        itemPositionsListener: _itemPositionsListener,
      ),
      itemCount: itemCount,
    );
    if (widget.selectedFiles.files.isNotEmpty && widget.isHomePageGallery) {
      return Stack(children: [
        gallery,
        Container(
          height: 60,
          child: GalleryAppBarWidget(
            GalleryAppBarType.homepage,
            null,
            widget.selectedFiles,
          ),
        ),
      ]);
    } else {
      return gallery;
    }
  }

  Widget _buildListItem(BuildContext context, int index) {
    if (_shouldLoadNextItems(index)) {
      // Eagerly load next batch
      _loadNextItems();
    }
    var fileIndex;
    if (widget.headerWidget != null) {
      if (index == 0) {
        return widget.headerWidget;
      }
      fileIndex = index - 1;
    } else {
      fileIndex = index;
    }
    if (fileIndex == _collatedFiles.length) {
      if (widget.asyncLoader != null) {
        if (!_hasLoadedAll) {
          return loadWidget;
        } else {
          return Container();
        }
      }
    }
    if (fileIndex < 0 || fileIndex >= _collatedFiles.length) {
      return Container();
    }
    var files = _collatedFiles[fileIndex];
    return Column(
      children: <Widget>[_getDay(files[0].creationTime), _getGallery(files)],
    );
  }

  bool _shouldLoadNextItems(int index) =>
      widget.asyncLoader != null &&
      !_isLoadingNext &&
      (index >= _collatedFiles.length - kEagerLoadTrigger) &&
      !_hasLoadedAll;

  void _loadNextItems() {
    _isLoadingNext = true;
    widget.asyncLoader(_files[_files.length - 1], kLoadLimit).then((files) {
      setState(() {
        _isLoadingNext = false;
        _saveScrollPosition();
        if (files.length < kLoadLimit) {
          _hasLoadedAll = true;
        }
        _files.addAll(files);
      });
    });
  }

  void _saveScrollPosition() {
    _scrollOffset = _scrollController.offset;
  }

  Widget _getDay(int timestamp) {
    final date = DateTime.fromMicrosecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    var title = getDayAndMonth(date);
    if (date.year == now.year && date.month == now.month) {
      if (date.day == now.day) {
        title = "Today";
      } else if (date.day == now.day - 1) {
        title = "Yesterday";
      }
    }
    if (date.year != DateTime.now().year) {
      title += " " + date.year.toString();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 0, 8),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _getGallery(List<File> files) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: 12),
      physics:
          NeverScrollableScrollPhysics(), // to disable GridView's scrolling
      itemBuilder: (context, index) {
        return _buildFile(context, files[index]);
      },
      itemCount: files.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
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
          tag: widget.tagPrefix + file.tag(),
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
      _files,
      _files.indexOf(file),
      widget.tagPrefix,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  void _collateFiles() {
    final dailyFiles = List<File>();
    final collatedFiles = List<List<File>>();
    for (int index = 0; index < _files.length; index++) {
      if (index > 0 &&
          !_areFilesFromSameDay(_files[index - 1], _files[index])) {
        final collatedDailyFiles = List<File>();
        collatedDailyFiles.addAll(dailyFiles);
        collatedFiles.add(collatedDailyFiles);
        dailyFiles.clear();
      }
      dailyFiles.add(_files[index]);
    }
    if (dailyFiles.isNotEmpty) {
      collatedFiles.add(dailyFiles);
    }
    _collatedFiles.clear();
    _collatedFiles.addAll(collatedFiles);
  }

  bool _areFilesFromSameDay(File first, File second) {
    var firstDate = DateTime.fromMicrosecondsSinceEpoch(first.creationTime);
    var secondDate = DateTime.fromMicrosecondsSinceEpoch(second.creationTime);
    return firstDate.year == secondDate.year &&
        firstDate.month == secondDate.month &&
        firstDate.day == secondDate.day;
  }

  void _updateScrollbar() {
    final index = _itemPositionsListener.itemPositions.value.first.index;
    _lastIndex = index;
    _scrollKey.currentState?.setPosition(index / _collatedFiles.length);
  }
}

class _MaxVelocityPhysics extends AlwaysScrollableScrollPhysics {
  final double velocityThreshold;

  _MaxVelocityPhysics({@required this.velocityThreshold, ScrollPhysics parent})
      : super(parent: parent);

  @override
  bool recommendDeferredLoading(
      double velocity, ScrollMetrics metrics, BuildContext context) {
    return velocity.abs() > velocityThreshold;
  }

  @override
  _MaxVelocityPhysics applyTo(ScrollPhysics ancestor) {
    return _MaxVelocityPhysics(
        velocityThreshold: velocityThreshold, parent: buildParent(ancestor));
  }
}
