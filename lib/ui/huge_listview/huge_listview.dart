import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:photos/ui/huge_listview/draggable_scrollbar.dart';
import 'package:photos/ui/huge_listview/page_result.dart';
import 'package:quiver/cache.dart';
import 'package:quiver/collection.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

typedef HugeListViewPageFuture<T> = Future<List<T>> Function(int pageIndex);
typedef HugeListViewItemBuilder<T> = Widget Function(
    BuildContext context, int index, T entry);
typedef HugeListViewErrorBuilder = Widget Function(
    BuildContext context, dynamic error);

class HugeListView<T> extends StatefulWidget {
  /// A [ScrollablePositionedList] controller for jumping or scrolling to an item.
  final ItemScrollController controller;

  /// Size of the page. [HugeListView] only keeps a few pages of items in memory any time.
  final int pageSize;

  /// Index of an item to initially align within the viewport.
  final int startIndex;

  /// Total number of items in the list.
  final int totalCount;

  /// Called to build items for the list with the specified [pageIndex].
  final HugeListViewPageFuture<T> pageFuture;

  /// Called to build the thumb. One of [DraggableScrollbarThumbs.RoundedRectThumb], [DraggableScrollbarThumbs.ArrowThumb]
  /// or [DraggableScrollbarThumbs.SemicircleThumb], or build your own.
  final String Function(int) labelTextBuilder;

  /// Background color of scroll thumb, defaults to white.
  final Color thumbBackgroundColor;

  /// Drawing color of scroll thumb, defaults to gray.
  final Color thumbDrawColor;

  /// Height of scroll thumb, defaults to 48.
  final double thumbHeight;

  /// Called to build an individual item with the specified [index].
  final HugeListViewItemBuilder<T> itemBuilder;

  /// Called to build a placeholder while the item is not yet availabe.
  final IndexedWidgetBuilder placeholderBuilder;

  /// Called to build a progress widget while the whole list is initialized.
  final WidgetBuilder waitBuilder;

  /// Called to build a widget when the list is empty.
  final WidgetBuilder emptyResultBuilder;

  /// Called to build a widget when there is an error.
  final HugeListViewErrorBuilder errorBuilder;

  /// The velocity above which the individual items stop being drawn until the scrolling rate drops.
  final double velocityThreshold;

  /// Event to call with the index of the topmost visible item in the viewport while scrolling.
  /// Can be used to display the current letter of an alphabetically sorted list, for instance.
  final ValueChanged<int> firstShown;

  HugeListView({
    Key key,
    this.controller,
    @required this.pageSize,
    @required this.startIndex,
    @required this.totalCount,
    @required this.pageFuture,
    @required this.labelTextBuilder,
    @required this.itemBuilder,
    @required this.placeholderBuilder,
    this.waitBuilder,
    this.emptyResultBuilder,
    this.errorBuilder,
    this.velocityThreshold = 128,
    this.firstShown,
    this.thumbBackgroundColor = Colors.white,
    this.thumbDrawColor = Colors.grey,
    this.thumbHeight = 48.0,
  })  : assert(pageSize > 0),
        assert(velocityThreshold >= 0),
        super(key: key);

  @override
  HugeListViewState<T> createState() => HugeListViewState<T>();
}

class HugeListViewState<T> extends State<HugeListView<T>> {
  final scrollKey = GlobalKey<DraggableScrollbarState>();
  final listener = ItemPositionsListener.create();
  Map<int, HugeListViewPageResult<T>> map;
  MapCache<int, HugeListViewPageResult<T>> cache;
  dynamic error;
  bool _frameCallbackInProgress = false;

  @override
  void initState() {
    super.initState();

    _initCache();
    listener.itemPositions.addListener(_sendScroll);
  }

  @override
  void dispose() {
    listener.itemPositions.removeListener(_sendScroll);
    super.dispose();
  }

  void _sendScroll() {
    int current = _currentFirst();
    widget.firstShown?.call(current);
    scrollKey.currentState?.setPosition(current / widget.totalCount, current);
  }

  int _currentFirst() {
    try {
      return listener.itemPositions.value.first.index;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null && widget.errorBuilder != null)
      return widget.errorBuilder(context, error);
    if (widget.totalCount == -1 && widget.waitBuilder != null)
      return widget.waitBuilder(context);
    if (widget.totalCount == 0 && widget.emptyResultBuilder != null)
      return widget.emptyResultBuilder(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return DraggableScrollbar(
          key: scrollKey,
          totalCount: widget.totalCount,
          initialScrollIndex: widget.startIndex,
          onChange: (position) {
            widget.controller
                ?.jumpTo(index: (position * widget.totalCount).floor());
          },
          labelTextBuilder: widget.labelTextBuilder,
          backgroundColor: widget.thumbBackgroundColor,
          drawColor: widget.thumbDrawColor,
          heightScrollThumb: widget.thumbHeight,
          currentFirstIndex: _currentFirst(),
          child: ScrollablePositionedList.builder(
            itemScrollController: widget.controller,
            itemPositionsListener: listener,
            physics: _MaxVelocityPhysics(
                velocityThreshold: widget.velocityThreshold),
            initialScrollIndex: widget.startIndex,
            itemCount: max(widget.totalCount, 0),
            itemBuilder: (context, index) {
              final page = index ~/ widget.pageSize;
              final pageResult = map[page];
              final value = pageResult?.items?.elementAt(index % widget.pageSize);
              if (value != null) {
                return widget.itemBuilder(context, index, value);
              }

              if (!Scrollable.recommendDeferredLoadingForContext(context)) {
                cache //
                    .get(page, ifAbsent: _loadPage)
                    .then(_reload)
                    .catchError(_error);
              } else if (!_frameCallbackInProgress) {
                _frameCallbackInProgress = true;
                SchedulerBinding.instance
                    ?.scheduleFrameCallback((d) => _deferredReload(context));
              }
              return ConstrainedBox(
                constraints: BoxConstraints(minHeight: 10),
                child: widget.placeholderBuilder(context, index),
              );
            },
          ),
        );
      },
    );
  }

  Future<HugeListViewPageResult<T>> _loadPage(int index) async {
    return HugeListViewPageResult(index, await widget.pageFuture(index));
  }

  void _initCache() {
    map = LruMap<int, HugeListViewPageResult<T>>(
        maximumSize: 256 ~/ widget.pageSize);
    cache = MapCache<int, HugeListViewPageResult<T>>(map: map);
  }

  void _error(dynamic e, StackTrace stackTrace) {
    if (widget.errorBuilder == null) throw e;
    if (mounted) setState(() => error = e);
  }

  void _reload(HugeListViewPageResult<T> value) => _doReload(value?.index ?? 0);

  void _deferredReload(BuildContext context) {
    if (!Scrollable.recommendDeferredLoadingForContext(context)) {
      _frameCallbackInProgress = false;
      _doReload(-1);
    } else
      SchedulerBinding.instance?.scheduleFrameCallback(
          (d) => _deferredReload(context),
          rescheduling: true);
  }

  void _doReload(int index) {
    if (mounted) setState(() {});
  }

  /// Jump to the [position] in the list. [position] is between 0.0 (first item) and 1.0 (last item), practically currentIndex / totalCount.
  /// To jump to a specific item, use [ItemScrollController.jumpTo] or [ItemScrollController.scrollTo].
  void setPosition(double position) {
    scrollKey.currentState?.setPosition(position, _currentFirst());
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
