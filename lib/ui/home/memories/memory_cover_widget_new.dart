import "package:flutter/material.dart";
import "package:photos/models/memory.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class MemoryCoverWidgetNew extends StatelessWidget {
  final List<Memory> memories;
  final ScrollController controller;
  final double offsetOfItem;

  const MemoryCoverWidgetNew({
    required this.memories,
    required this.controller,
    required this.offsetOfItem,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    //memories will be empty if all memories are deleted and setState is called
    //after FullScreenMemory screen is popped
    if (memories.isEmpty) {
      return const SizedBox.shrink();
    }

    final widthOfScreen = MediaQuery.sizeOf(context).width;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final diff = (controller.offset - offsetOfItem) + widthOfScreen / 7;
        final scale = 1 - (diff / widthOfScreen).abs() / 3;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          //Adding this row is a workaround for making height of memory cover
          //render as 125 * scale. Without this, height of rendered memory
          //cover will be 125.
          child: Row(
            children: [
              SizedBox(
                height: 125 * scale,
                width: 85 * scale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.bottomCenter,
                    children: [
                      child!,
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
              ),
            ],
          ),
        );
      },
      child: ThumbnailWidget(
        memories[0].file,
        shouldShowArchiveStatus: false,
      ),
    );
  }
}
