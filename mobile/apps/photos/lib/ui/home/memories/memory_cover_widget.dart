import "package:flutter/material.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/effects.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/home/memories/all_memories_page.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/navigation_util.dart";

// TODO: Use a single instance variable for `allMemories` and `allTitles`
class MemoryCoverWidget extends StatefulWidget {
  final List<Memory> memories;
  final List<List<Memory>> allMemories;
  final double height;
  final double width;
  static const outerStrokeWidth = 1.0;
  static const aspectRatio = 0.68;
  static const horizontalPadding = 2.5;
  final String title;
  final List<String> allTitle;
  final int currentMemoryIndex;

  const MemoryCoverWidget({
    required this.memories,
    required this.allMemories,
    required this.height,
    required this.width,
    required this.title,
    required this.allTitle,
    required this.currentMemoryIndex,
    super.key,
  });

  @override
  State<MemoryCoverWidget> createState() => _MemoryCoverWidgetState();
}

class _MemoryCoverWidgetState extends State<MemoryCoverWidget> {
  @override
  void initState() {
    super.initState();
    _preloadFirstUnseenMemory();
  }

  @override
  Widget build(BuildContext context) {
    //memories will be empty if all memories are deleted and setState is called
    //after FullScreenMemory screen is popped
    if (widget.memories.isEmpty) {
      return const SizedBox.shrink();
    }

    final index = _getNextMemoryIndex();
    final title = widget.title;

    final memory = widget.memories[index];
    final isSeen = memory.isSeen();
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MemoryCoverWidget.horizontalPadding,
      ),
      child: GestureDetector(
        onTap: () async {
          await routeToPage(
            context,
            forceCustomPageRoute: true,
            AllMemoriesPage(
              initialPageIndex: widget.currentMemoryIndex,
              allMemories: widget.allMemories,
              allTitles: widget.allTitle,
            ),
          );
          setState(() {});
        },
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            boxShadow: brightness == Brightness.dark
                ? [
                    const BoxShadow(
                      color: strokeFainterDark,
                      spreadRadius: MemoryCoverWidget.outerStrokeWidth,
                      blurRadius: 0,
                    ),
                  ]
                : [...shadowFloatFaintestLight],
            borderRadius: BorderRadius.circular(5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: isSeen
                ? ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFBFBFBF),
                      BlendMode.hue,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Hero(
                          tag: "memories" + memory.file.tag,
                          child: ThumbnailWidget(
                            memory.file,
                            shouldShowArchiveStatus: false,
                            shouldShowSyncStatus: false,
                            key: Key("memories" + memory.file.tag),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                              stops: const [0, 1],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          child: SizedBox(
                            width: widget.width,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Hero(
                                tag: title,
                                child: Center(
                                  child: Text(
                                    title,
                                    style: getEnteTextTheme(context)
                                        .miniBold
                                        .copyWith(
                                          color: isSeen
                                              ? textFaintDark
                                              : Colors.white,
                                        ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Hero(
                        tag: "memories" + memory.file.tag,
                        child: ThumbnailWidget(
                          memory.file,
                          shouldShowArchiveStatus: false,
                          shouldShowSyncStatus: false,
                          key: Key("memories" + memory.file.tag),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                            stops: const [0, 1],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        child: SizedBox(
                          width: widget.width,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Hero(
                              tag: title,
                              child: Center(
                                child: Text(
                                  title,
                                  style: getEnteTextTheme(context)
                                      .miniBold
                                      .copyWith(
                                        color: Colors.white,
                                      ),
                                  textAlign: TextAlign.left,
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
      ),
    );
  }

  void _preloadFirstUnseenMemory() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        if (widget.memories.isEmpty) return;

        final index = _getNextMemoryIndex();
        preloadThumbnail(widget.memories[index].file);
        preloadFile(widget.memories[index].file);
      }
    });
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
}
