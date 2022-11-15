import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class NoThumbnailWidget extends StatelessWidget {
  const NoThumbnailWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        border: Border.all(
          color: enteColorScheme.strokeFaint,
          width: 1,
        ),
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
