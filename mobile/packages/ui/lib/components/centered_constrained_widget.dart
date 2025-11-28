import 'package:flutter/material.dart';

/// A widget that is horizontally centered and constrained to a maximum width.
///
/// This widget is useful for creating responsive layouts that look good on both
/// mobile and wider screens (tablets, desktop).
class CenteredConstrainedWidget extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredConstrainedWidget({
    required this.child,
    this.maxWidth = 700,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
