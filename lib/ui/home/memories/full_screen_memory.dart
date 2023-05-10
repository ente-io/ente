import "dart:io";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:photos/models/memory.dart";
import "package:photos/services/memories_service.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/extents_page_view.dart";
import "package:photos/ui/viewer/file/file_widget.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/share_util.dart";
import "package:step_progress_indicator/step_progress_indicator.dart";

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
                  DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                      .format(
                    DateTime.fromMicrosecondsSinceEpoch(
                      file.creationTime!,
                    ),
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
      child: SafeArea(
        child: Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 72),
          child: _showCounter
              ? Text(
                  '${_index + 1}/${widget.memories.length}',
                  style: darkTextTheme.bodyMuted,
                )
              : AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    widget.title,
                    style: darkTextTheme.h2,
                  ),
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
                showDetailsSheet(context, file);
              },
            ),
            IconButton(
              icon: Icon(
                Platform.isAndroid
                    ? Icons.delete_outline
                    : CupertinoIcons.delete,
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
