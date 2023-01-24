import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class NoThumbnailWidget extends StatelessWidget {
  final bool hasBorder;
  const NoThumbnailWidget({this.hasBorder = true, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        border: hasBorder
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
