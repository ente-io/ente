import 'package:flutter/material.dart';
import "package:photos/models/memories/memory.dart";
import "package:photos/theme/colors.dart";
import "package:photos/ui/home/memories/full_screen_memory.dart";

// TODO: Use a single instance variable for `allMemories` and `allTitles`
class AllMemoriesPage extends StatefulWidget {
  final int initialPageIndex;
  final int inititalFileIndex;
  final List<List<Memory>> allMemories;
  final List<String> allTitles;
  final bool isFromWidgetOrNotifications;

  const AllMemoriesPage({
    super.key,
    required this.allMemories,
    required this.allTitles,
    required this.initialPageIndex,
    this.inititalFileIndex = 0,
    this.isFromWidgetOrNotifications = false,
  });

  @override
  State<AllMemoriesPage> createState() => _AllMemoriesPageState();
}

class _AllMemoriesPageState extends State<AllMemoriesPage>
    with SingleTickerProviderStateMixin {
  late PageController pageController;
  bool isFirstLoad = true;

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
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundBaseDark,
      child: PageView.builder(
        controller: pageController,
        physics: const BouncingScrollPhysics(),
        hitTestBehavior: HitTestBehavior.translucent,
        itemCount: widget.allMemories.length,
        itemBuilder: (context, index) {
          final initialMemoryIndex =
              widget.isFromWidgetOrNotifications && isFirstLoad
                  ? widget.inititalFileIndex
                  : _getNextMemoryIndex(index);
          isFirstLoad = false;
          return FullScreenMemoryDataUpdater(
            initialIndex: initialMemoryIndex,
            memories: widget.allMemories[index],
            child: FullScreenMemory(
              widget.allTitles[index],
              initialMemoryIndex,
              onNextMemory: index < widget.allMemories.length - 1
                  ? () => pageController.nextPage(
                        duration: const Duration(milliseconds: 675),
                        curve: Curves.easeOutQuart,
                      )
                  : null,
              onPreviousMemory: index > 0
                  ? () => pageController.previousPage(
                        duration: const Duration(milliseconds: 675),
                        curve: Curves.easeOutQuart,
                      )
                  : null,
            ),
          );
        },
      ),
    );
  }

  int _getNextMemoryIndex(int currentIndex) {
    int lastSeenIndex = 0;
    int lastSeenTimestamp = 0;
    final allMemoriesLength = widget.allMemories[currentIndex].length;
    for (var index = 0; index < allMemoriesLength; index++) {
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
