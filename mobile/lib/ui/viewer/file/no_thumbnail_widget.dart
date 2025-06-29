import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class NoThumbnailWidget extends StatelessWidget {
  final bool addBorder;
  final double borderRadius;
  const NoThumbnailWidget({
    this.addBorder = true,
    this.borderRadius = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: addBorder
            ? Border.all(
                color: enteColorScheme.strokeFaint,
                width: 1,
              )
            : null,
        color: enteColorScheme.fillFaint,
      ),
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          color: enteColorScheme.strokeMuted,
          size: 24,
        ),
      ),
    );
  }
}
