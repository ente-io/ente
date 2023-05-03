import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/memory.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/home/memories/full_screen_memory.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/navigation_util.dart";

class MemoryCovertWidget extends StatefulWidget {
  const MemoryCovertWidget({
    Key? key,
    required this.memories,
  }) : super(key: key);

  final List<Memory> memories;

  @override
  State<MemoryCovertWidget> createState() => _MemoryCovertWidgetState();
}

class _MemoryCovertWidgetState extends State<MemoryCovertWidget> {
  @override
  Widget build(BuildContext context) {
    final index = _getNextMemoryIndex();
    final title = _getTitle(widget.memories[index]);
    return GestureDetector(
      onTap: () async {
        await routeToPage(
          context,
          FullScreenMemory(title, widget.memories, index),
          forceCustomPageRoute: true,
        );
        setState(() {});
      },
      child: SizedBox(
        height: 100,
        width: 92,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildMemoryItem(context, index),
              const Padding(padding: EdgeInsets.all(4)),
              Hero(
                tag: title,
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: getEnteTextTheme(context).mini,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container _buildMemoryItem(BuildContext context, int index) {
    final colorScheme = getEnteColorScheme(context);
    final memory = widget.memories[index];
    final isSeen = memory.isSeen();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSeen ? colorScheme.strokeFaint : colorScheme.primary500,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: ClipOval(
        child: SizedBox(
          width: 56,
          height: 56,
          child: Hero(
            tag: "memories" + memory.file.tag,
            child: ThumbnailWidget(
              memory.file,
              shouldShowSyncStatus: false,
              key: Key("memories" + memory.file.tag),
            ),
          ),
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
