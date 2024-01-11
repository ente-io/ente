import "package:flutter/material.dart";
import "package:photos/models/memory.dart";
import "package:photos/theme/ente_theme.dart";

class MemoryCoverWidgetNew extends StatelessWidget {
  final double scale;
  final Widget thumbnailWidget;
  final List<Memory> memories;

  const MemoryCoverWidgetNew({
    required this.memories,
    required this.thumbnailWidget,
    required this.scale,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 125 * scale,
      width: 85 * scale,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.bottomCenter,
          children: [
            thumbnailWidget,
            Positioned(
              bottom: 8 * scale,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: 85,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ),
                    child: Text(
                      "1 year ago",
                      style: getEnteTextTheme(context).miniBold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
