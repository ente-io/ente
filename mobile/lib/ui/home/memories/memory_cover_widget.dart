import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/effects.dart";
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
  static const outerStrokeWidth = 1.0;
  static const aspectRatio = 0.68;
  static const horizontalPadding = 2.5;
  final double maxScaleOffsetX;
  final String? title;

  const MemoryCoverWidget({
    required this.memories,
    required this.controller,
    required this.offsetOfItem,
    required this.maxHeight,
    required this.maxWidth,
    required this.maxScaleOffsetX,
    this.title,
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
    // TODO: lau: remove (I) from name when opening up the feature flag
    final title = widget.title != null
        ? widget.title! == "filler"
            ? _getTitle(widget.memories[index]) + "(I)"
            : widget.title! + "(I)"
        : _getTitle(widget.memories[index]);
    final memory = widget.memories[index];
    final isSeen = memory.isSeen();
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final diff = (widget.controller.offset - widget.offsetOfItem) +
            widget.maxScaleOffsetX;
        final scale = 1 - (diff / widthOfScreen).abs() / 3.7;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoryCoverWidget.horizontalPadding,
          ),
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
            }, //Adding this row is a workaround for making height of memory cover
            //render as [MemoryCoverWidgetNew.height] * scale. Without this, height of rendered memory
            //cover will be [MemoryCoverWidgetNew.height].
            child: Row(
              children: [
                Container(
                  height: widget.maxHeight * scale,
                  width: widget.maxWidth * scale,
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
                                child!,
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.5),
                                        Colors.transparent,
                                      ],
                                      stops: const [0, 1],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
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
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.bottomCenter,
                            children: [
                              child!,
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.5),
                                      Colors.transparent,
                                    ],
                                    stops: const [0, 1],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
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
          shouldShowSyncStatus: false,
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
