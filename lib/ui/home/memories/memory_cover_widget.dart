import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/memory.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/home/memories/full_screen_memory.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/navigation_util.dart";

class MemoryCoverWidget extends StatefulWidget {
  final List<Memory> memories;
  final ScrollController controller;
  final double offsetOfItem;
  final double maxHeight;
  final double maxWidth;
  static const centerStrokeWidth = 1.0;
  static const aspectRatio = 0.68;

  const MemoryCoverWidget({
    required this.memories,
    required this.controller,
    required this.offsetOfItem,
    required this.maxHeight,
    required this.maxWidth,
    super.key,
  });

  @override
  State<MemoryCoverWidget> createState() => _MemoryCoverWidgetState();
}

class _MemoryCoverWidgetState extends State<MemoryCoverWidget> {
  @override
  Widget build(BuildContext context) {
    //memories will be empty if all memories are deleted and setState is called
    //after FullScreenMemory screen is popped
    if (widget.memories.isEmpty) {
      return const SizedBox.shrink();
    }

    final widthOfScreen = MediaQuery.sizeOf(context).width;
    final index = _getNextMemoryIndex();
    final title = _getTitle(widget.memories[index]);
    final memory = widget.memories[index];
    final isSeen = memory.isSeen();
    final currentTheme = MediaQuery.platformBrightnessOf(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final diff = (widget.controller.offset - widget.offsetOfItem) +
            widthOfScreen / 7;
        final scale = 1 - (diff / widthOfScreen).abs() / 3.7;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          //Adding this row is a workaround for making height of memory cover
          //render as [MemoryCoverWidgetNew.height] * scale. Without this, height of rendered memory
          //cover will be [MemoryCoverWidgetNew.height].
          child: GestureDetector(
            onTap: () async {
              await routeToPage(
                context,
                FullScreenMemoryDataUpdater(
                  initialIndex: index,
                  memories: widget.memories,
                  child: FullScreenMemory(title, index),
                ),
                forceCustomPageRoute: true,
              );
              setState(() {});
            },
            child: Row(
              children: [
                Container(
                  height: widget.maxHeight * scale,
                  width: widget.maxWidth * scale,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: isSeen
                            ? currentTheme == Brightness.dark
                                ? const Color.fromRGBO(104, 104, 104, 0.32)
                                : Colors.transparent
                            : const Color.fromRGBO(1, 222, 77, 0.11),
                        spreadRadius: MemoryCoverWidget.centerStrokeWidth / 2,
                        blurRadius: 0,
                      ),
                      const BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.13),
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.bottomCenter,
                      children: [
                        child!,
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSeen
                                  ? currentTheme == Brightness.dark
                                      ? const Color.fromRGBO(
                                          104,
                                          104,
                                          104,
                                          0.32,
                                        )
                                      : Colors.transparent
                                  : const Color.fromRGBO(1, 222, 77, 0.11),
                              width: MemoryCoverWidget.centerStrokeWidth / 2,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.5),
                                Colors.transparent,
                              ],
                              stops: const [0, 0.85],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        isSeen
                            ? const SizedBox.shrink()
                            : Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    stops: [0, 0.27, 0.4],
                                    colors: [
                                      Color.fromRGBO(1, 222, 78, 0.293),
                                      Color.fromRGBO(1, 222, 77, 0.07),
                                      Colors.transparent,
                                    ],
                                    transform: GradientRotation(-1.1),
                                  ),
                                ),
                              ),
                        isSeen
                            ? const SizedBox.shrink()
                            : Stack(
                                fit: StackFit.expand,
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              stops: [0, 0.1, 0.5, 0.9, 1],
                                              colors: [
                                                Colors.transparent,
                                                Color.fromRGBO(1, 222, 77, 0.1),
                                                Color.fromRGBO(1, 222, 77, 1),
                                                Color.fromRGBO(1, 222, 77, 0.1),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          height: 1 * scale,
                                          width: (widget.maxWidth - 16) * scale,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                        Positioned(
                          bottom: 8 * scale,
                          child: Transform.scale(
                            scale: scale,
                            child: SizedBox(
                              width: widget.maxWidth,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Hero(
                                  tag: title,
                                  child: Text(
                                    title,
                                    style: getEnteTextTheme(context)
                                        .miniBold
                                        .copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
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
          ),
        );
      },
      child: Hero(
        tag: "memories" + memory.file.tag,
        child: ThumbnailWidget(
          memory.file,
          shouldShowArchiveStatus: false,
          key: Key("memories" + memory.file.tag),
        ),
      ),
    );
  }

  // Returns either the first unseen memory or the memory that succeeds the
  // last seen memory
  int _getNextMemoryIndex() {
    int lastSeenIndex = 0;
    int lastSeenTimestamp = 0;
    for (var index = 0; index < widget.memories.length; index++) {
      final memory = widget.memories[index];
      if (!memory.isSeen()) {
        return index;
      } else {
        if (memory.seenTime() > lastSeenTimestamp) {
          lastSeenIndex = index;
          lastSeenTimestamp = memory.seenTime();
        }
      }
    }
    if (lastSeenIndex == widget.memories.length - 1) {
      return 0;
    }
    return lastSeenIndex + 1;
  }

  String _getTitle(Memory memory) {
    final present = DateTime.now();
    final then = DateTime.fromMicrosecondsSinceEpoch(memory.file.creationTime!);
    final diffInYears = present.year - then.year;
    return S.of(context).yearsAgo(diffInYears);
  }
}
