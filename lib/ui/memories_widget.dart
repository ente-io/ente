import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:photos/memories_service.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/memory.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/ui/video_widget.dart';
import 'package:photos/ui/zoomable_image.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/share_util.dart';

class MemoriesWidget extends StatefulWidget {
  @override
  _MemoriesWidgetState createState() => _MemoriesWidgetState();
}

class _MemoriesWidgetState extends State<MemoriesWidget> {
  @override
  void initState() {
    MemoriesService.instance.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Memory>>(
      future: MemoriesService.instance.getMemories(),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data.length == 0) {
          return Container();
        } else {
          return _buildMemories(snapshot.data);
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
    final index = _getUnseenMemoryIndex();
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
              _buildMemoryItem(index),
              Padding(padding: EdgeInsets.all(2)),
              Hero(
                tag: title,
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(title),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container _buildMemoryItem(int index) {
    final isSeen = memories[index].isSeen();
    return Container(
      decoration: BoxDecoration(
        border: isSeen
            ? Border()
            : Border.all(
                color: Colors.amber,
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

  int _getUnseenMemoryIndex() {
    for (var index = 0; index < memories.length; index++) {
      if (!memories[index].isSeen()) {
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
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(children: [
          _buildSwiper(),
          Hero(
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
          ),
        ]),
      ),
    );
  }

  Swiper _buildSwiper() {
    return Swiper(
      itemBuilder: (BuildContext context, int index) {
        final file = widget.memories[index].file;
        return Stack(children: [
          file.fileType == FileType.image
              ? ZoomableImage(
                  file,
                  tagPrefix: "memories",
                )
              : VideoWidget(
                  file,
                  tagPrefix: "memories",
                  autoPlay: true,
                ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getFormattedDate(
                      DateTime.fromMicrosecondsSinceEpoch(file.creationTime)),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    share(context, file);
                  },
                ),
              ],
            ),
          )
        ]);
      },
      index: _index,
      itemCount: widget.memories.length,
      pagination: SwiperPagination(
          alignment: Alignment.bottomCenter,
          margin: EdgeInsets.all(36),
          builder: FractionPaginationBuilder(
            activeColor: Colors.white,
            color: Colors.grey,
          )),
      loop: false,
      control: SwiperControl(),
      onIndexChanged: (index) async {
        await MemoriesService.instance.markMemoryAsSeen(widget.memories[index]);
        _index = index;
      },
    );
  }
}
