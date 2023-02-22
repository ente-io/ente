import "dart:io";

import "package:flutter/cupertino.dart";
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/memory.dart';
import 'package:photos/services/memories_service.dart';
import "package:photos/ui/actions/file/file_actions.dart";
import 'package:photos/ui/viewer/file/file_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class MemoriesWidget extends StatelessWidget {
  const MemoriesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Memory>>(
      future: MemoriesService.instance.getMemories(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMemories(snapshot.data!),
              const Divider(),
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
    final firstDate =
        DateTime.fromMicrosecondsSinceEpoch(first.file.creationTime!);
    final secondDate =
        DateTime.fromMicrosecondsSinceEpoch(second.file.creationTime!);
    return firstDate.year == secondDate.year;
  }
}

class MemoryWidget extends StatefulWidget {
  const MemoryWidget({
    Key? key,
    required this.memories,
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
          context,
          FullScreenMemory(title, widget.memories, index),
          forceCustomPageRoute: true,
        );
        setState(() {});
      },
      child: SizedBox(
        width: 92,
        height: 100,
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
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1!
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
            ? const Border()
            : Border.all(
                color: Theme.of(context).colorScheme.greenAlternative,
                width: isSeen ? 0 : 2,
              ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: ClipOval(
        child: SizedBox(
          width: isSeen ? 60 : 56,
          height: isSeen ? 60 : 56,
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

  const FullScreenMemory(this.title, this.memories, this.index, {Key? key})
      : super(key: key);

  @override
  State<FullScreenMemory> createState() => _FullScreenMemoryState();
}

class _FullScreenMemoryState extends State<FullScreenMemory> {
  int _index = 0;
  double _opacity = 1;
  // shows memory counter as index+1/totalFiles for large number of memories
  // when the top step indicator isn't visible.
  bool _showCounter = false;
  bool _showStepIndicator = true;
  PageController? _pageController;
  bool _shouldDisableScroll = false;
  final GlobalKey shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    _showStepIndicator = widget.memories.length <= 60;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _opacity = 0;
          _showCounter = !_showStepIndicator;
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
        toolbarHeight: 84,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _showStepIndicator
                ? StepProgressIndicator(
                    totalSteps: widget.memories.length,
                    currentStep: _index + 1,
                    size: 2,
                    selectedColor: Colors.white, //same for both themes
                    unselectedColor: Colors.white.withOpacity(0.4),
                  )
                : const SizedBox.shrink(),
            const SizedBox(
              height: 18,
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white, //same for both themes
                    ),
                  ),
                ),
                Text(
                  getFormattedDate(
                    DateTime.fromMicrosecondsSinceEpoch(file.creationTime!),
                  ),
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontSize: 14,
                        color: Colors.white,
                      ), //same for both themes
                ),
              ],
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.5),
                Colors.transparent,
              ],
              stops: const [0, 0.6, 1],
            ),
          ),
        ),
        backgroundColor: const Color(0x00000000),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _buildSwiper(),
            bottomGradient(),
            _buildInfoText(),
            _buildBottomIcons(),
          ],
        ),
      ),
    );
  }

  void onFileDeleted() {
    if (widget.memories.length == 1) {
      Navigator.pop(context);
    } else {
      setState(() {
        if (_index != 0) {
          _pageController?.jumpToPage(_index - 1);
        }
        widget.memories.removeAt(_index);
        if (_index != 0) {
          _index--;
        }
      });
    }
  }

  Hero _buildInfoText() {
    return Hero(
      tag: widget.title,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
        child: _showCounter
            ? Text(
                '${_index + 1}/${widget.memories.length}',
                style: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .copyWith(color: Colors.white.withOpacity(0.4)),
              )
            : AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .headline4!
                      .copyWith(color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildBottomIcons() {
    final file = widget.memories[_index].file;
    return SafeArea(
      child: Container(
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.fromLTRB(26, 0, 26, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Platform.isAndroid ? Icons.info_outline : CupertinoIcons.info,
                color: Colors.white, //same for both themes
              ),
              onPressed: () {
                showInfoSheet(context, file);
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white, //same for both themes
              ),
              onPressed: () async {
                await showSingleFileDeleteSheet(
                  context,
                  file,
                  onFileRemoved: (file) => {onFileDeleted()},
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.adaptive.share,
                color: Colors.white, //same for both themes
              ),
              onPressed: () {
                share(context, [file]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomGradient() {
    return Container(
      height: 124,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.5), //same for both themes
            Colors.transparent,
          ],
          stops: const [0, 0.8],
        ),
      ),
    );
  }

  Widget _buildSwiper() {
    _pageController = PageController(initialPage: _index);
    return PageView.builder(
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
          backgroundDecoration: const BoxDecoration(
            color: Colors.transparent,
          ),
        );
      },
      itemCount: widget.memories.length,
      controller: _pageController,
      onPageChanged: (index) async {
        await MemoriesService.instance.markMemoryAsSeen(widget.memories[index]);
        if (mounted) {
          setState(() {
            _index = index;
          });
        }
      },
      physics: _shouldDisableScroll
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
    );
  }
}
