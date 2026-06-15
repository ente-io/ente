import 'package:flutter/material.dart';

/// Ente loading spinner.
class EnteLoadingWidget extends StatelessWidget {
  final Color? color;
  final double size;
  final double padding;
  final Alignment alignment;

  /// Creates Ente loading spinner.
  const EnteLoadingWidget({
    super.key,
    this.color,
    this.size = 14,
    this.padding = 5,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: SizedBox.fromSize(
          size: Size.square(size),
          child: RepaintBoundary(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color ?? Colors.white,
              strokeCap: StrokeCap.round,
            ),
          ),
        ),
      ),
    );
  }
}
