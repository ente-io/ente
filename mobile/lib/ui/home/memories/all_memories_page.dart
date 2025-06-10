import 'package:flutter/material.dart';
import "package:photos/models/memories/memory.dart";
import "package:photos/ui/home/memories/full_screen_memory.dart";

class AllMemoriesPage extends StatefulWidget {
  final int initialPageIndex;
  final List<List<Memory>> allMemories;
  final List<String> allTitles;

  const AllMemoriesPage({
    super.key,
    required this.allMemories,
    required this.allTitles,
    required this.initialPageIndex,
  });

  @override
  State<AllMemoriesPage> createState() => _AllMemoriesPageState();
}

class _AllMemoriesPageState extends State<AllMemoriesPage>
    with SingleTickerProviderStateMixin {
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: widget.initialPageIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.allMemories.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: pageController,
            builder: (context, child) {
              double value = 1.0;
              if (pageController.position.haveDimensions) {
                value = pageController.page! - index;
                value = (1 - (value.abs() * 0.5)).clamp(0.0, 1.0);
              }
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: FullScreenMemoryDataUpdater(
                    initialIndex: _getNextMemoryIndex(index),
                    memories: widget.allMemories[index],
                    child: FullScreenMemory(
                      widget.allTitles[index],
                      _getNextMemoryIndex(index),
                      onNextMemory: index < widget.allMemories.length - 1
                          ? () => pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.ease,
                              )
                          : null,
                      onPreviousMemory: index > 0
                          ? () => pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.ease,
                              )
                          : null,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _getNextMemoryIndex(int currentIndex) {
    int lastSeenIndex = 0;
    int lastSeenTimestamp = 0;
    for (var index = 0;
        index < widget.allMemories[currentIndex].length;
        index++) {
      final memory = widget.allMemories[currentIndex][index];
      if (!memory.isSeen()) {
        return index;
      } else {
        if (memory.seenTime() > lastSeenTimestamp) {
          lastSeenIndex = index;
          lastSeenTimestamp = memory.seenTime();
        }
      }
    }
    if (lastSeenIndex == widget.allMemories[currentIndex].length - 1) {
      return 0;
    }
    return lastSeenIndex + 1;
  }
}
