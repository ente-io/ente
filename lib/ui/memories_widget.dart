import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/services/memories_service.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/memory.dart';
import 'package:photos/ui/blurred_file_backdrop.dart';
import 'package:photos/ui/extents_page_view.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/ui/video_widget.dart';
import 'package:photos/ui/zoomable_image.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/share_util.dart';

class MemoriesWidget extends StatefulWidget {
  @override
  _MemoriesWidgetState createState() => _MemoriesWidgetState();
}

class _MemoriesWidgetState extends State<MemoriesWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    MemoriesService.instance.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Memory>>(
      future: MemoriesService.instance.getMemories(),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data.length == 0) {
          return Container();
        } else {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildMemories(snapshot.data),
          );
        }
      },
    );
  }

  Widget _buildMemories(List<Memory> memories) {
    final collatedMemories = _collateMemories(memories);
    final memoryWidgets = List<Widget>();
    for (final memories in collatedMemories) {
      memoryWidgets.add(MemoryWidget(memories: memories));
    }
    return Row(children: memoryWidgets);
  }

  List<List<Memory>> _collateMemories(List<Memory> memories) {
    final yearlyMemories = List<Memory>();
    final collatedMemories = List<List<Memory>>();
    for (int index = 0; index < memories.length; index++) {
      if (index > 0 &&
          !_areMemoriesFromSameYear(memories[index - 1], memories[index])) {
        final collatedYearlyMemories = List<Memory>();
        collatedYearlyMemories.addAll(yearlyMemories);
        collatedMemories.add(collatedYearlyMemories);
        yearlyMemories.clear();
      }
      yearlyMemories.add(memories[index]);
    }
    if (yearlyMemories.isNotEmpty) {
      collatedMemories.add(yearlyMemories);
    }
    return collatedMemories;
  }

  bool _areMemoriesFromSameYear(Memory first, Memory second) {
    var firstDate =
        DateTime.fromMicrosecondsSinceEpoch(first.file.creationTime);
    var secondDate =
        DateTime.fromMicrosecondsSinceEpoch(second.file.creationTime);
    return firstDate.year == secondDate.year;
  }
}

class MemoryWidget extends StatelessWidget {
  const MemoryWidget({
    Key key,
    @required this.memories,
  }) : super(key: key);

  final List<Memory> memories;

  @override
  Widget build(BuildContext context) {
    final index = _getNextMemoryIndex();
    final title = _getTitle(memories[index]);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return FullScreenMemory(title, memories, index);
            },
          ),
        );
      },
      child: Container(
        width: 100,
        height: 120,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
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
    final isSeen = memories[index].isSeen();
    return Container(
      decoration: BoxDecoration(
        border: isSeen
            ? Border()
            : Border.all(
                color: Theme.of(context).accentColor,
                width: isSeen ? 0 : 2,
              ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: ClipOval(
        child: Container(
          width: isSeen ? 76 : 72,
          height: isSeen ? 76 : 72,
          child: Hero(
            tag: "memories" + memories[index].file.tag(),
            child: ThumbnailWidget(memories[index].file),
          ),
        ),
      ),
    );
  }

  int _getNextMemoryIndex() {
    for (var index = 0; index < memories.length; index++) {
      if (!memories[index].isSeen()) {
        return index;
      }
      if (index > 0 &&
          memories[index - 1].seenTime() > memories[index].seenTime()) {
        return index;
      }
    }
    return 0;
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
              share(context, file);
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
          preloadLocalFileThumbnail(nextFile);
        }
        final file = widget.memories[index].file;
        return MemoryItem(file);
      },
      itemCount: widget.memories.length,
      controller: _pageController,
      extents: 1,
      onPageChanged: (index) async {
        await MemoriesService.instance.markMemoryAsSeen(widget.memories[index]);
        setState(() {
          _index = index;
        });
        return index;
      },
    );
  }
}

class MemoryItem extends StatelessWidget {
  final File file;
  const MemoryItem(this.file, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final view = file.fileType == FileType.image
        ? ZoomableImage(
            file,
            tagPrefix: "memories",
            backgroundDecoration: BoxDecoration(
              color: Colors.transparent,
            ),
          )
        : VideoWidget(
            file,
            tagPrefix: "memories",
            autoPlay: false,
          );
    return Stack(children: [
      // BlurredFileBackdrop(file),
      view,
    ]);
  }
}
