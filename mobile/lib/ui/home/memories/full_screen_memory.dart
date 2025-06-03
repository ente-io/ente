import "dart:async";
import "dart:io";
import "dart:math";
import "dart:ui";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/smart_memories_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/home/memories/memory_progress_indicator.dart";
import "package:photos/ui/viewer/file/file_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/file_details/favorite_widget.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/share_util.dart";
// import "package:step_progress_indicator/step_progress_indicator.dart";

//There are two states of variables that FullScreenMemory depends on:
//1. The list of memories
//2. The current index of the page view

//1
//Only when items are deleted will list of memories change and this requires the
//whole screen to be rebuild. So the InheritedWidget is updated using the Updater
//widget which will then lead to a rebuild of all widgets that call
//InheritedWidget.of(context).

//2
//There are widgets that doesn't come inside the PageView that needs to rebuild
//with new state when page index is changed. So the index is stored in a
//ValueNotifier inside the InheritedWidget and the widgets that need to change
//are wrapped in a ValueListenableBuilder.

class FullScreenMemoryDataUpdater extends StatefulWidget {
  final List<Memory> memories;
  final int initialIndex;
  final Widget child;
  const FullScreenMemoryDataUpdater({
    required this.memories,
    required this.initialIndex,
    required this.child,
    super.key,
  });

  @override
  State<FullScreenMemoryDataUpdater> createState() =>
      _FullScreenMemoryDataUpdaterState();
}

class _FullScreenMemoryDataUpdaterState
    extends State<FullScreenMemoryDataUpdater> {
  late ValueNotifier<int> indexNotifier;

  @override
  void initState() {
    super.initState();
    indexNotifier = ValueNotifier(widget.initialIndex);
    memoriesCacheService.markMemoryAsSeen(
      widget.memories[widget.initialIndex],
      widget.memories.length == widget.initialIndex + 1,
    );
  }

  @override
  void dispose() {
    indexNotifier.dispose();
    super.dispose();
  }

  void removeCurrentMemory() {
    widget.memories.removeAt(indexNotifier.value);
    if (widget.memories.isNotEmpty) {
      setState(() {
        if (widget.memories.length == indexNotifier.value) {
          indexNotifier.value -= 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullScreenMemoryData(
      memories: widget.memories,
      indexNotifier: indexNotifier,
      removeCurrentMemory: removeCurrentMemory,
      child: widget.child,
    );
  }
}

class FullScreenMemoryData extends InheritedWidget {
  final List<Memory> memories;
  final ValueNotifier<int> indexNotifier;
  final VoidCallback removeCurrentMemory;

  const FullScreenMemoryData({
    required this.memories,
    required this.indexNotifier,
    required this.removeCurrentMemory,
    required super.child,
    super.key,
  });

  static FullScreenMemoryData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FullScreenMemoryData>();
  }

  @override
  bool updateShouldNotify(FullScreenMemoryData oldWidget) {
    // Checking oldWidget.memories.length != memories.length here doesn't work
    //because the old widget and new widget reference the same memories list.
    return true;
  }
}

class FullScreenMemory extends StatefulWidget {
  final String title;
  final int initialIndex;
  const FullScreenMemory(
    this.title,
    this.initialIndex, {
    super.key,
  });

  @override
  State<FullScreenMemory> createState() => _FullScreenMemoryState();
}

class _FullScreenMemoryState extends State<FullScreenMemory> {
  PageController? _pageController;
  final _showTitle = ValueNotifier<bool>(true);
  AnimationController? _progressAnimationController;
  AnimationController? _kenBurnsAnimationController;
  final ValueNotifier<Duration> durationNotifier =
      ValueNotifier(const Duration(seconds: 5));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTitle.value = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _showTitle.dispose();
    durationNotifier.dispose();
    super.dispose();
  }

  void _toggleAnimation(bool pause) {
    if (_progressAnimationController != null) {
      if (pause) {
        _progressAnimationController!.stop();
      } else {
        _progressAnimationController!.forward();
      }
    }
    if (_kenBurnsAnimationController != null) {
      if (pause) {
        _kenBurnsAnimationController!.stop();
      } else {
        _kenBurnsAnimationController!.forward();
      }
    }
  }

  void _resetAnimation() {
    if (_progressAnimationController != null) {
      _progressAnimationController!.reset();
    }
    if (_kenBurnsAnimationController != null) {
      _kenBurnsAnimationController!.reset();
    }
  }

  void onFileLoad(
    bool isLoaded,
    int duration, {
    bool isVideo = false,
  }) {
    if (isLoaded) {
      durationNotifier.value = Duration(seconds: duration);

      _progressAnimationController?.reset();
      _progressAnimationController?.duration = durationNotifier.value;
      _progressAnimationController?.forward();

      _kenBurnsAnimationController?.reset();
      _kenBurnsAnimationController?.forward();
    } else {
      _progressAnimationController?.stop();
      _kenBurnsAnimationController?.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inheritedData = FullScreenMemoryData.of(context)!;
    final showStepProgressIndicator = inheritedData.memories.length < 60;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 84,
        automaticallyImplyLeading: false,
        title: ValueListenableBuilder(
          valueListenable: inheritedData.indexNotifier,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Icon(
                Icons.close,
                color: Colors.white, //same for both themes
              ),
            ),
          ),
          builder: (context, value, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                showStepProgressIndicator
                    ? ValueListenableBuilder<Duration>(
                        valueListenable: durationNotifier,
                        builder: (context, duration, _) {
                          return NewProgressIndicator(
                            totalSteps: inheritedData.memories.length,
                            currentIndex: value,
                            selectedColor: Colors.white,
                            unselectedColor: Colors.white.withOpacity(0.4),
                            duration: duration,
                            animationController: (controller) {
                              _progressAnimationController = controller;
                            },
                            onComplete: () {
                              final currentIndex =
                                  inheritedData.indexNotifier.value;
                              if (currentIndex <
                                  inheritedData.memories.length - 1) {
                                _pageController!.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.ease,
                                );
                              }
                            },
                          );
                        },
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    child!,
                    Text(
                      SmartMemoriesService.getDateFormatted(
                        creationTime:
                            inheritedData.memories[value].file.creationTime!,
                        context: context,
                      ),
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontSize: 14,
                            color: Colors.white,
                          ), //same for both themes
                    ),
                  ],
                ),
              ],
            );
          },
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
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          const MemoryBackDrop(),
          PageView.builder(
            controller: _pageController ??= PageController(
              initialPage: widget.initialIndex,
            ),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              if (index < inheritedData.memories.length - 1) {
                final nextFile = inheritedData.memories[index + 1].file;
                preloadThumbnail(nextFile);
                preloadFile(nextFile);
              }
              final currentFile = inheritedData.memories[index].file;
              final isVideo = currentFile.fileType == FileType.video;
              return GestureDetector(
                onTapDown: (TapDownDetails details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final edgeWidth = screenWidth * 0.20;
                  if (details.localPosition.dx < edgeWidth) {
                    if (index > 0) {
                      _pageController!.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.ease,
                      );
                      _resetAnimation();
                    }
                  } else if (details.localPosition.dx >
                      screenWidth - edgeWidth) {
                    if (index < (inheritedData.memories.length - 1)) {
                      _pageController!.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.ease,
                      );
                    }
                    _resetAnimation();
                  }
                },
                onLongPress: () {
                  isVideo ? null : _toggleAnimation(true);
                },
                onLongPressUp: () {
                  isVideo ? null : _toggleAnimation(false);
                },
                child: MemoriesZoomWidget(
                  scaleController: (controller) {
                    _kenBurnsAnimationController = controller;
                  },
                  zoomIn: index % 2 == 0,
                  isVideo: isVideo,
                  child: FileWidget(
                    inheritedData.memories[index].file,
                    autoPlay: false,
                    tagPrefix: "memories",
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    isFromMemories: true,
                    playbackCallback: (isPlaying) {
                      isPlaying
                          ? _toggleAnimation(false)
                          : _toggleAnimation(true);
                    },
                    onFileLoad: (isLoaded, duration) {
                      onFileLoad(
                        isLoaded,
                        duration,
                        isVideo: isVideo,
                      );
                    },
                  ),
                ),
              );
            },
            onPageChanged: (index) async {
              unawaited(
                memoriesCacheService.markMemoryAsSeen(
                  inheritedData.memories[index],
                  inheritedData.memories.length == index + 1,
                ),
              );
              inheritedData.indexNotifier.value = index;
            },
            itemCount: inheritedData.memories.length,
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: ValueListenableBuilder(
                builder: (context, value, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: value
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            child: Hero(
                              tag: widget.title,
                              child: Text(
                                widget.title,
                                style: getEnteTextTheme(context)
                                    .largeBold
                                    .copyWith(
                                      color:
                                          Colors.white, //same for both themes
                                    ),
                              ),
                            ),
                          )
                        : showStepProgressIndicator
                            ? const SizedBox.shrink()
                            : const MemoryCounter(),
                  );
                },
                valueListenable: _showTitle,
              ),
            ),
          ),
          const BottomGradient(),
          const BottomIcons(),
        ],
      ),
    );
  }
}

class BottomIcons extends StatelessWidget {
  const BottomIcons({super.key});

  @override
  Widget build(BuildContext context) {
    final inheritedData = FullScreenMemoryData.of(context)!;

    return ValueListenableBuilder(
      valueListenable: inheritedData.indexNotifier,
      builder: (context, value, _) {
        final currentFile = inheritedData.memories[value].file;
        final List<Widget> rowChildren = [
          IconButton(
            icon: Icon(
              Platform.isAndroid ? Icons.info_outline : CupertinoIcons.info,
              color: Colors.white, //same for both themes
            ),
            onPressed: () {
              showDetailsSheet(context, currentFile);
            },
          ),
        ];

        if (currentFile.ownerID == null ||
            (Configuration.instance.getUserID() ?? 0) == currentFile.ownerID) {
          rowChildren.addAll([
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
                  inheritedData
                      .memories[inheritedData.indexNotifier.value].file,
                  onFileRemoved: (file) => {
                    inheritedData.removeCurrentMemory.call(),
                    if (inheritedData.memories.isEmpty)
                      {
                        Navigator.of(context).pop(),
                      },
                  },
                );
              },
            ),
            SizedBox(
              height: 32,
              child: FavoriteWidget(currentFile),
            ),
          ]);
        }
        rowChildren.add(
          IconButton(
            icon: Icon(
              Icons.adaptive.share,
              color: Colors.white, //same for both themes
            ),
            onPressed: () {
              share(context, [currentFile]);
            },
          ),
        );

        return SafeArea(
          top: false,
          child: Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: rowChildren,
            ),
          ),
        );
      },
    );
  }
}

class MemoryCounter extends StatelessWidget {
  const MemoryCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final inheritedData = FullScreenMemoryData.of(context)!;
    return ValueListenableBuilder(
      valueListenable: inheritedData.indexNotifier,
      builder: (context, value, _) {
        return Text(
          "${value + 1}/${inheritedData.memories.length}",
          style: darkTextTheme.bodyMuted,
        );
      },
    );
  }
}

class BottomGradient extends StatelessWidget {
  const BottomGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
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
      ),
    );
  }
}

class MemoryBackDrop extends StatelessWidget {
  const MemoryBackDrop({super.key});

  @override
  Widget build(BuildContext context) {
    final inheritedData = FullScreenMemoryData.of(context)!;
    return ValueListenableBuilder(
      valueListenable: inheritedData.indexNotifier,
      builder: (context, value, _) {
        final currentFile = inheritedData.memories[value].file;
        if (currentFile.fileType == FileType.video ||
            currentFile.fileType == FileType.livePhoto) {
          return const SizedBox.shrink();
        }
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
              ThumbnailWidget(
                currentFile,
                shouldShowSyncStatus: false,
                shouldShowFavoriteIcon: false,
              ),
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 100,
                  sigmaY: 100,
                ),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MemoriesZoomWidget extends StatefulWidget {
  final Widget child;
  final bool isVideo;
  final void Function(AnimationController)? scaleController;
  final bool zoomIn;

  const MemoriesZoomWidget({
    super.key,
    required this.child,
    required this.isVideo,
    required this.zoomIn,
    this.scaleController,
  });

  @override
  State<MemoriesZoomWidget> createState() => _MemoriesZoomWidgetState();
}

class _MemoriesZoomWidgetState extends State<MemoriesZoomWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _panAnimation;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 5,
      ),
    );

    final startScale = widget.zoomIn ? 1.05 : 1.15;
    final endScale = widget.zoomIn ? 1.15 : 1.05;

    final startX = (random.nextDouble() - 0.5) * 0.1;
    final startY = (random.nextDouble() - 0.5) * 0.1;
    final endX = (random.nextDouble() - 0.5) * 0.1;
    final endY = (random.nextDouble() - 0.5) * 0.1;

    _scaleAnimation = Tween<double>(
      begin: startScale,
      end: endScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _panAnimation = Tween<Offset>(
      begin: Offset(startX, startY),
      end: Offset(endX, endY),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.scaleController != null) {
      widget.scaleController!(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isVideo
        ? widget.child
        : AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipRect(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.translate(
                    offset: Offset(
                      _panAnimation.value.dx * 100,
                      _panAnimation.value.dy * 100,
                    ),
                    child: widget.child,
                  ),
                ),
              );
            },
          );
  }
}
