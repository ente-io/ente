import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:photos/ui/huge_listview/draggable_scrollbar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

typedef HugeListViewItemBuilder<T> = Widget Function(
    BuildContext context, int index);
typedef HugeListViewErrorBuilder = Widget Function(
    BuildContext context, dynamic error);

class HugeListView<T> extends StatefulWidget {
  /// A [ScrollablePositionedList] controller for jumping or scrolling to an item.
  final ItemScrollController controller;

  /// Index of an item to initially align within the viewport.
  final int startIndex;

  /// Total number of items in the list.
  final int totalCount;

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

  /// Called to build a progress widget while the whole list is initialized.
  final WidgetBuilder waitBuilder;

  /// Called to build a widget when the list is empty.
  final WidgetBuilder emptyResultBuilder;

  /// Called to build a widget when there is an error.
  final HugeListViewErrorBuilder errorBuilder;

  /// Event to call with the index of the topmost visible item in the viewport while scrolling.
  /// Can be used to display the current letter of an alphabetically sorted list, for instance.
  final ValueChanged<int> firstShown;

  final bool isDraggableScrollbarEnabled;

  HugeListView({
    Key key,
    this.controller,
    @required this.startIndex,
    @required this.totalCount,
    @required this.labelTextBuilder,
    @required this.itemBuilder,
    this.waitBuilder,
    this.emptyResultBuilder,
    this.errorBuilder,
    this.firstShown,
    this.thumbBackgroundColor = Colors.white,
    this.thumbDrawColor = Colors.grey,
    this.thumbHeight = 48.0,
    this.isDraggableScrollbarEnabled = true,
  })  : super(key: key);

  @override
  HugeListViewState<T> createState() => HugeListViewState<T>();
}

class HugeListViewState<T> extends State<HugeListView<T>> {
  final scrollKey = GlobalKey<DraggableScrollbarState>();
  final listener = ItemPositionsListener.create();
  dynamic error;

  @override
  void initState() {
    super.initState();

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
    if (error != null && widget.errorBuilder != null) {
      return widget.errorBuilder(context, error);
    }
    if (widget.totalCount == -1 && widget.waitBuilder != null) {
      return widget.waitBuilder(context);
    }
    if (widget.totalCount == 0 && widget.emptyResultBuilder != null) {
      return widget.emptyResultBuilder(context);
    }

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
          isEnabled: widget.isDraggableScrollbarEnabled,
          child: ScrollablePositionedList.builder(
            itemScrollController: widget.controller,
            itemPositionsListener: listener,
            initialScrollIndex: widget.startIndex,
            itemCount: max(widget.totalCount, 0),
            itemBuilder: (context, index) {
              return widget.itemBuilder(context, index);
            },
          ),
        );
      },
    );
  }

  /// Jump to the [position] in the list. [position] is between 0.0 (first item) and 1.0 (last item), practically currentIndex / totalCount.
  /// To jump to a specific item, use [ItemScrollController.jumpTo] or [ItemScrollController.scrollTo].
  void setPosition(double position) {
    scrollKey.currentState?.setPosition(position, _currentFirst());
  }
}
