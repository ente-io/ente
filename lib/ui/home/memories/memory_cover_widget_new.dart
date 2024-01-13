import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/memory.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/home/memories/full_screen_memory.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/navigation_util.dart";

class MemoryCoverWidgetNew extends StatefulWidget {
  final List<Memory> memories;
  final ScrollController controller;
  final double offsetOfItem;
  static const centerStrokeWidth = 0.5;

  const MemoryCoverWidgetNew({
    required this.memories,
    required this.controller,
    required this.offsetOfItem,
    super.key,
  });

  @override
  State<MemoryCoverWidgetNew> createState() => _MemoryCoverWidgetNewState();
}

class _MemoryCoverWidgetNewState extends State<MemoryCoverWidgetNew> {
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

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final diff = (widget.controller.offset - widget.offsetOfItem) +
            widthOfScreen / 7;
        final scale = 1 - (diff / widthOfScreen).abs() / 3;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          //Adding this row is a workaround for making height of memory cover
          //render as 125 * scale. Without this, height of rendered memory
          //cover will be 125.
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
                  height: 125 * scale,
                  width: 85 * scale,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: isSeen
                            ? Colors.transparent
                            : const Color.fromRGBO(1, 222, 77, 0.11),
                        spreadRadius: MemoryCoverWidgetNew.centerStrokeWidth,
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
                        isSeen
                            ? const SizedBox.shrink()
                            : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        const Color.fromRGBO(1, 222, 77, 0.11),
                                    width:
                                        MemoryCoverWidgetNew.centerStrokeWidth,
                                  ),
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
                                    stops: [0, 0.35, 0.5],
                                    colors: [
                                      Color.fromARGB(71, 1, 222, 78),
                                      Color(0x1901DE4D),
                                      Color(0x0001DE4D),
                                    ],
                                    transform: GradientRotation(-1.2),
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
                                              stops: [0, 0.5, 1],
                                              colors: [
                                                Colors.transparent,
                                                Color(0xFF01DE4D),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          height: 1 * scale,
                                          width: 68 * scale,
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
                              width: 85,
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
