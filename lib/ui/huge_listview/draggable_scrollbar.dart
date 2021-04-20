import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/ui/huge_listview/scroll_bar_thumb.dart';

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
  final String Function(int) labelTextBuilder;
  final bool isEnabled;

  DraggableScrollbar({
    Key key,
    @required this.child,
    this.backgroundColor = Colors.white,
    this.drawColor = Colors.grey,
    this.heightScrollThumb = 80.0,
    this.padding,
    this.totalCount = 1,
    this.initialScrollIndex = 0,
    this.currentFirstIndex = 0,
    @required this.labelTextBuilder,
    this.onChange,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  DraggableScrollbarState createState() => DraggableScrollbarState();
}

class DraggableScrollbarState extends State<DraggableScrollbar>
    with TickerProviderStateMixin {
  static final animationDuration = Duration(milliseconds: 1000);
  double thumbOffset = 0.0;
  bool isDragging = false;
  int currentFirstIndex;

  double get thumbMin => 0.0;

  double get thumbMax => context.size.height - widget.heightScrollThumb;

  AnimationController _thumbAnimationController;
  Animation<double> _thumbAnimation;
  AnimationController _labelAnimationController;
  Animation<double> _labelAnimation;
  Timer _fadeoutTimer;

  @override
  void initState() {
    super.initState();
    currentFirstIndex = widget.currentFirstIndex;

    if (widget.initialScrollIndex > 0 && widget.totalCount > 1) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        setState(() => thumbOffset =
            (widget.initialScrollIndex / widget.totalCount) *
                (thumbMax - thumbMin));
      });
    }

    _thumbAnimationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    _thumbAnimation = CurvedAnimation(
      parent: _thumbAnimationController,
      curve: Curves.fastOutSlowIn,
    );

    _labelAnimationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    _labelAnimation = CurvedAnimation(
      parent: _labelAnimationController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    _labelAnimationController.dispose();
    _fadeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEnabled) {
      return Stack(
        children: [
          RepaintBoundary(child: widget.child),
          RepaintBoundary(child: buildDetector()),
        ],
      );
    } else {
      return widget.child;
    }
  }

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
          child: ScrollBarThumb(
            widget.backgroundColor,
            widget.drawColor,
            widget.heightScrollThumb,
            widget.labelTextBuilder.call(this.currentFirstIndex),
            _labelAnimation,
            _thumbAnimation,
          ),
        ),
      );

  void setPosition(double position, int currentFirstIndex) {
    setState(() {
      this.currentFirstIndex = currentFirstIndex;
      thumbOffset = position * (thumbMax - thumbMin);
      if (_thumbAnimationController.status != AnimationStatus.forward) {
        _thumbAnimationController.forward();
      }
      _fadeoutTimer?.cancel();
      _fadeoutTimer = Timer(animationDuration, () {
        _thumbAnimationController.reverse();
        _labelAnimationController.reverse();
        _fadeoutTimer = null;
      });
    });
  }

  void onDragStart(DragStartDetails details) {
    setState(() {
      isDragging = true;
      _labelAnimationController.forward();
      _fadeoutTimer?.cancel();
    });
  }

  void onDragUpdate(DragUpdateDetails details) {
    setState(() {
      if (_thumbAnimationController.status != AnimationStatus.forward) {
        _thumbAnimationController.forward();
      }
      if (isDragging && details.delta.dy != 0) {
        thumbOffset += details.delta.dy;
        thumbOffset = thumbOffset.clamp(thumbMin, thumbMax);
        double position = thumbOffset / (thumbMax - thumbMin);
        widget.onChange?.call(position);
      }
    });
  }

  void onDragEnd(DragEndDetails details) {
    _fadeoutTimer = Timer(animationDuration, () {
      _thumbAnimationController.reverse();
      _labelAnimationController.reverse();
      _fadeoutTimer = null;
    });
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
