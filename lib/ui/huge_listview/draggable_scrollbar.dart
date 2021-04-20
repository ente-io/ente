import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/ui/huge_listview/draggable_scrollbar_thumbs.dart';

class DraggableScrollbar extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final Color drawColor;
  final double heightScrollThumb;
  final EdgeInsetsGeometry padding;
  final int totalCount;
  final int initialScrollIndex;
  final int currentFirstIndex;
  final ValueChanged<double> onChange;
  final ScrollThumbBuilder scrollThumbBuilder;

  DraggableScrollbar({
    Key key,
    @required this.child,
    this.backgroundColor = Colors.white,
    this.drawColor = Colors.grey,
    this.heightScrollThumb = 48.0,
    this.padding,
    this.totalCount = 1,
    this.initialScrollIndex = 0,
    this.currentFirstIndex = 0,
    @required this.scrollThumbBuilder,
    this.onChange,
  }) : super(key: key);

  @override
  DraggableScrollbarState createState() => DraggableScrollbarState();
}

class DraggableScrollbarState extends State<DraggableScrollbar>
    with TickerProviderStateMixin {
  double thumbOffset = 0.0;
  bool isDragging = false;

  double get thumbMin => 0.0;

  double get thumbMax => context.size.height - widget.heightScrollThumb;

  @override
  void initState() {
    super.initState();

    if (widget.initialScrollIndex > 0 && widget.totalCount > 1) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        setState(() => thumbOffset =
            (widget.initialScrollIndex / widget.totalCount) *
                (thumbMax - thumbMin));
      });
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          RepaintBoundary(child: widget.child),
          RepaintBoundary(child: buildDetector()),
        ],
      );

  Widget buildKeyboard() {
    if (defaultTargetPlatform == TargetPlatform.windows)
      return RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: keyHandler,
        child: buildDetector(),
      );
    else
      return buildDetector();
  }

  Widget buildDetector() => GestureDetector(
        onVerticalDragStart: onDragStart,
        onVerticalDragUpdate: onDragUpdate,
        onVerticalDragEnd: onDragEnd,
        child: Container(
          alignment: Alignment.topRight,
          margin: EdgeInsets.only(top: thumbOffset),
          padding: widget.padding,
          child: widget.scrollThumbBuilder.call(
              widget.backgroundColor,
              widget.drawColor,
              widget.heightScrollThumb,
              widget.currentFirstIndex),
        ),
      );

  void setPosition(double position) {
    setState(() {
      thumbOffset = position * (thumbMax - thumbMin);
    });
  }

  void onDragStart(DragStartDetails details) {
    setState(() => isDragging = true);
  }

  void onDragUpdate(DragUpdateDetails details) {
    setState(() {
      if (isDragging && details.delta.dy != 0) {
        thumbOffset += details.delta.dy;
        thumbOffset = thumbOffset.clamp(thumbMin, thumbMax);
        double position = thumbOffset / (thumbMax - thumbMin);
        widget.onChange?.call(position);
      }
    });
  }

  void onDragEnd(DragEndDetails details) {
    setState(() => isDragging = false);
  }

  void keyHandler(RawKeyEvent value) {
    if (value.runtimeType == RawKeyDownEvent) {
      if (value.logicalKey == LogicalKeyboardKey.arrowDown)
        onDragUpdate(DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: Offset(0, 2),
        ));
      else if (value.logicalKey == LogicalKeyboardKey.arrowUp)
        onDragUpdate(DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: Offset(0, -2),
        ));
      else if (value.logicalKey == LogicalKeyboardKey.pageDown)
        onDragUpdate(DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: Offset(0, 25),
        ));
      else if (value.logicalKey == LogicalKeyboardKey.pageUp)
        onDragUpdate(DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: Offset(0, -25),
        ));
    }
  }
}
