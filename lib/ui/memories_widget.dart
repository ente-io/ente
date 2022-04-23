import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/memory.dart';
import 'package:photos/services/memories_service.dart';
import 'package:photos/ui/blurred_file_backdrop.dart';
import 'package:photos/ui/extents_page_view.dart';
import 'package:photos/ui/file_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/share_util.dart';

class MemoriesWidget extends StatelessWidget {
  const MemoriesWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Memory>>(
      future: MemoriesService.instance.getMemories(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data.isEmpty) {
          return Container();
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMemories(snapshot.data),
              Divider(
                thickness: 1,
              )
            ],
          );
        }
      },
    );
  }

  Widget _buildMemories(List<Memory> memories) {
    final collatedMemories = _collateMemories(memories);
    final List<Widget> memoryWidgets = [];
    for (final memories in collatedMemories) {
      memoryWidgets.add(MemoryWidget(memories: memories));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: memoryWidgets),
    );
  }

  List<List<Memory>> _collateMemories(List<Memory> memories) {
    final List<Memory> yearlyMemories = [];
    final List<List<Memory>> collatedMemories = [];
    for (int index = 0; index < memories.length; index++) {
      if (index > 0 &&
          !_areMemoriesFromSameYear(memories[index - 1], memories[index])) {
        final List<Memory> collatedYearlyMemories = [];
        collatedYearlyMemories.addAll(yearlyMemories);
        collatedMemories.add(collatedYearlyMemories);
        yearlyMemories.clear();
      }
      yearlyMemories.add(memories[index]);
    }
    if (yearlyMemories.isNotEmpty) {
      collatedMemories.add(yearlyMemories);
    }
    return collatedMemories.reversed.toList();
  }

  bool _areMemoriesFromSameYear(Memory first, Memory second) {
    var firstDate =
        DateTime.fromMicrosecondsSinceEpoch(first.file.creationTime);
    var secondDate =
        DateTime.fromMicrosecondsSinceEpoch(second.file.creationTime);
    return firstDate.year == secondDate.year;
  }
}

class MemoryWidget extends StatefulWidget {
  const MemoryWidget({
    Key key,
    @required this.memories,
  }) : super(key: key);

  final List<Memory> memories;

  @override
  State<MemoryWidget> createState() => _MemoryWidgetState();
}

class _MemoryWidgetState extends State<MemoryWidget> {
  @override
  Widget build(BuildContext context) {
    final index = _getNextMemoryIndex();
    final title = _getTitle(widget.memories[index]);
    return GestureDetector(
      onTap: () async {
        await routeToPage(
            context, FullScreenMemory(title, widget.memories, index));
        setState(() {});
      },
      child: SizedBox(
        width: 100,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _buildMemoryItem(context, index),
              Padding(padding: EdgeInsets.all(4)),
              Hero(
                tag: title,
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1
                        .copyWith(fontSize: 12),
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
    final memory = widget.memories[index];
    final isSeen = memory.isSeen();
    return Container(
      decoration: BoxDecoration(
        border: isSeen
            ? Border()
            : Border.all(
                color: Theme.of(context).buttonColor,
                width: isSeen ? 0 : 2,
              ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: ClipOval(
        child: SizedBox(
          width: isSeen ? 60 : 56,
          height: isSeen ? 60 : 56,
          child: Hero(
            tag: "memories" + memory.file.tag(),
            child: ThumbnailWidget(
              memory.file,
              shouldShowSyncStatus: false,
              key: Key("memories" + memory.file.tag()),
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
    final then = DateTime.fromMicrosecondsSinceEpoch(memory.file.creationTime);
    final diffInYears = present.year - then.year;
    if (diffInYears == 1) {
      return "1 year ago";
    } else {
      return diffInYears.toString() + " years ago";
    }
  }
}

class FullScreenMemory extends StatefulWidget {
  final String title;
  final List<Memory> memories;
  final int index;

  FullScreenMemory(this.title, this.memories, this.index, {Key key})
      : super(key: key);

  @override
  _FullScreenMemoryState createState() => _FullScreenMemoryState();
}

class _FullScreenMemoryState extends State<FullScreenMemory> {
  int _index = 0;
  double _opacity = 1;
  PageController _pageController;
  bool _shouldDisableScroll = false;

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _opacity = 0;
        });
      }
    });
    MemoriesService.instance.markMemoryAsSeen(widget.memories[_index]);
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.memories[_index].file;
    return Scaffold(
      appBar: AppBar(
        title: Text(getFormattedDate(
            DateTime.fromMicrosecondsSinceEpoch(file.creationTime))),
        backgroundColor: Color(0x00000000),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              share(context, [file]);
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        color: Colors.black,
        child: Stack(children: [
          BlurredFileBackdrop(file),
          _buildSwiper(),
          _buildTitleText(),
          _buildIndexText(),
        ]),
      ),
    );
  }

  Hero _buildTitleText() {
    return Hero(
      tag: widget.title,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.fromLTRB(0, 0, 0, 160),
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: Duration(milliseconds: 500),
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              widget.title,
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndexText() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Text(
        (_index + 1).toString() + " / " + widget.memories.length.toString(),
        style: TextStyle(
          fontSize: 24,
          decoration: TextDecoration.none,
          color: Colors.white60,
        ),
      ),
    );
  }

  Widget _buildSwiper() {
    _pageController = PageController(initialPage: _index);
    return ExtentsPageView.extents(
      itemBuilder: (BuildContext context, int index) {
        if (index < widget.memories.length - 1) {
          final nextFile = widget.memories[index + 1].file;
          preloadThumbnail(nextFile);
          preloadFile(nextFile);
        }
        final file = widget.memories[index].file;
        return FileWidget(
          file,
          autoPlay: false,
          tagPrefix: "memories",
          shouldDisableScroll: (value) {
            setState(() {
              _shouldDisableScroll = value;
            });
          },
          backgroundDecoration: BoxDecoration(
            color: Colors.transparent,
          ),
        );
      },
      itemCount: widget.memories.length,
      controller: _pageController,
      extents: 1,
      onPageChanged: (index) async {
        await MemoriesService.instance.markMemoryAsSeen(widget.memories[index]);
        setState(() {
          _index = index;
        });
      },
      physics: _shouldDisableScroll
          ? NeverScrollableScrollPhysics()
          : PageScrollPhysics(),
    );
  }
}
