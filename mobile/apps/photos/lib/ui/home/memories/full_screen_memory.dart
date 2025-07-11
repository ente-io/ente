import "dart:async";
import "dart:io";
import "dart:math";
import "dart:ui";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/details_sheet_event.dart";
import "package:photos/events/reset_zoom_of_photo_view_event.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/smart_memories_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/home/memories/custom_listener.dart";
import "package:photos/ui/home/memories/memory_progress_indicator.dart";
import "package:photos/ui/viewer/file/file_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/file_details/favorite_widget.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/share_util.dart";

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

//TODO: Use better naming convention. "Memory" should be a whole memory and
//parts of the memory should be called "items".
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
  final VoidCallback? onNextMemory;
  final VoidCallback? onPreviousMemory;

  const FullScreenMemory(
    this.title,
    this.initialIndex, {
    this.onNextMemory,
    this.onPreviousMemory,
    super.key,
  });

  @override
  State<FullScreenMemory> createState() => _FullScreenMemoryState();
}

class _FullScreenMemoryState extends State<FullScreenMemory> {
  final _showTitle = ValueNotifier<bool>(true);
  AnimationController? _progressAnimationController;
  AnimationController? _zoomAnimationController;
  final ValueNotifier<Duration> durationNotifier =
      ValueNotifier(const Duration(seconds: 5));

  /// Used to check if any pointer is on the screen.
  final hasPointerOnScreenNotifier = ValueNotifier<bool>(false);
  bool hasFinalFileLoaded = false;
  bool isAtFirstOrLastFile = false;

  late final StreamSubscription<DetailsSheetEvent>
      _detailSheetEventSubscription;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _showTitle.value = false;
    });
    hasPointerOnScreenNotifier.addListener(
      _hasPointerListener,
    );

    _detailSheetEventSubscription =
        Bus.instance.on<DetailsSheetEvent>().listen((event) {
      final inheritedData = FullScreenMemoryData.of(context);
      if (inheritedData == null) return;
      final index = inheritedData.indexNotifier.value;
      final currentFile = inheritedData.memories[index].file;

      if (event.isSameFile(
        uploadedFileID: currentFile.uploadedFileID,
        localID: currentFile.localID,
      )) {
        _toggleAnimation(pause: event.opened);
      }
    });
  }

  @override
  void dispose() {
    _showTitle.dispose();
    durationNotifier.dispose();
    hasPointerOnScreenNotifier.removeListener(_hasPointerListener);
    _detailSheetEventSubscription.cancel();
    super.dispose();
  }

  /// Used to check if user has touched the screen and then to pause animation
  /// and once the pointer is removed from the screen, it resumes the animation
  /// It also resets the zoom of the photo view to default for better user
  /// experience after finger(s) is removed from the screen after zooming in by
  /// pinching.
  void _hasPointerListener() {
    if (hasPointerOnScreenNotifier.value) {
      _toggleAnimation(pause: true);
    } else {
      _toggleAnimation(pause: false);
      final inheritedData = FullScreenMemoryData.of(context)!;
      final currentFile =
          inheritedData.memories[inheritedData.indexNotifier.value].file;
      Bus.instance.fire(
        ResetZoomOfPhotoView(
          localID: currentFile.localID,
          uploadedFileID: currentFile.uploadedFileID,
        ),
      );
    }
  }

  void _toggleAnimation({required bool pause}) {
    if (pause) {
      _progressAnimationController?.stop();
      _zoomAnimationController?.stop();
    } else {
      if (hasFinalFileLoaded || isAtFirstOrLastFile) {
        _progressAnimationController?.forward();
        _zoomAnimationController?.forward();
      }
    }
  }

  void _resetAnimation() {
    _progressAnimationController
      ?..stop()
      ..reset();
    _zoomAnimationController
      ?..stop()
      ..reset();
  }

  void onFinalFileLoad(int duration) {
    hasFinalFileLoaded = true;
    isAtFirstOrLastFile = false;
    if (_progressAnimationController?.isAnimating == true) {
      _progressAnimationController!.stop();
    }
    durationNotifier.value = Duration(seconds: duration);
    _progressAnimationController
      ?..stop()
      ..reset()
      ..duration = durationNotifier.value
      ..forward();
    _zoomAnimationController
      ?..stop()
      ..reset()
      ..forward();
  }

  void _goToNext(FullScreenMemoryData inheritedData) {
    hasFinalFileLoaded = false;
    final currentIndex = inheritedData.indexNotifier.value;
    if (currentIndex < inheritedData.memories.length - 1) {
      inheritedData.indexNotifier.value += 1;
      _onPageChange(inheritedData, currentIndex + 1);
    } else if (widget.onNextMemory != null) {
      widget.onNextMemory!();
    } else {
      isAtFirstOrLastFile = true;
      _toggleAnimation(pause: false);
    }
  }

  void _goToPrevious(FullScreenMemoryData inheritedData) {
    hasFinalFileLoaded = false;
    final currentIndex = inheritedData.indexNotifier.value;
    if (currentIndex > 0) {
      inheritedData.indexNotifier.value -= 1;
      _onPageChange(inheritedData, currentIndex - 1);
    } else if (widget.onPreviousMemory != null) {
      widget.onPreviousMemory!();
    } else {
      isAtFirstOrLastFile = true;
      _resetAnimation();
      _toggleAnimation(pause: false);
    }
  }

  void _onPageChange(FullScreenMemoryData inheritedData, int index) {
    isAtFirstOrLastFile = false;
    unawaited(
      memoriesCacheService.markMemoryAsSeen(
        inheritedData.memories[index],
        false,
      ),
    );
    inheritedData.indexNotifier.value = index;
    _resetAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final inheritedData = FullScreenMemoryData.of(context)!;
    final showStepProgressIndicator = inheritedData.memories.length < 60;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4.0,
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: strokeFainterDark,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              backgroundColor: Colors.black,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                toolbarHeight: 64,
                primary: false,
                automaticallyImplyLeading: false,
                title: ValueListenableBuilder(
                  valueListenable: inheritedData.indexNotifier,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(4, 8, 8, 8),
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  builder: (context, value, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        showStepProgressIndicator
                            ? ValueListenableBuilder<Duration>(
                                valueListenable: durationNotifier,
                                builder: (context, duration, _) {
                                  return MemoryProgressIndicator(
                                    totalSteps: inheritedData.memories.length,
                                    currentIndex: value,
                                    selectedColor: Colors.white,
                                    unselectedColor:
                                        Colors.white.withValues(alpha: 0.4),
                                    duration: duration,
                                    animationController: (controller) {
                                      _progressAnimationController = controller;
                                    },
                                    onComplete: () {
                                      _goToNext(inheritedData);
                                    },
                                  );
                                },
                              )
                            : const SizedBox.shrink(),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            child!,
                            Text(
                              SmartMemoriesService.getDateFormatted(
                                creationTime: inheritedData
                                    .memories[value].file.creationTime!,
                                context: context,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(75, 0, 0, 0),
                        Color.fromARGB(37, 0, 0, 0),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: [0, 0.45, 0.8, 1],
                    ),
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  const _MemoryBlur(),
                  ValueListenableBuilder<int>(
                    valueListenable: inheritedData.indexNotifier,
                    builder: (context, index, _) {
                      if (index < inheritedData.memories.length - 1) {
                        final nextFile = inheritedData.memories[index + 1].file;
                        preloadThumbnail(nextFile);
                        preloadFile(nextFile);
                      }
                      final currentMemory = inheritedData.memories[index];
                      final isVideo =
                          currentMemory.file.fileType == FileType.video;
                      final currentFile = currentMemory.file;

                      return MemoriesPointerGestureListener(
                        onTap: (PointerEvent event) {
                          final screenWidth = MediaQuery.sizeOf(context).width;
                          final goToPreviousTapAreaWidth = screenWidth * 0.20;
                          if (event.localPosition.dx <
                              goToPreviousTapAreaWidth) {
                            _goToPrevious(inheritedData);
                          } else {
                            _goToNext(inheritedData);
                          }
                        },
                        hasPointerNotifier: hasPointerOnScreenNotifier,
                        child: MemoriesZoomWidget(
                          key: ValueKey(
                            currentFile.uploadedFileID ?? currentFile.localID,
                          ),
                          scaleController: (controller) {
                            _zoomAnimationController = controller;
                          },
                          zoomIn: index % 2 == 0,
                          isVideo: isVideo,
                          child: FileWidget(
                            currentFile,
                            autoPlay: false,
                            tagPrefix: "memories",
                            backgroundDecoration:
                                const BoxDecoration(color: Colors.transparent),
                            isFromMemories: true,
                            playbackCallback: (isPlaying) {
                              _toggleAnimation(pause: !isPlaying);
                            },
                            onFinalFileLoad: ({required int memoryDuration}) {
                              onFinalFileLoad(memoryDuration);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  BottomGradient(showTitle: _showTitle),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder(
                        valueListenable: _showTitle,
                        builder: (context, value, _) {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: value
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      32,
                                      4,
                                      32,
                                      12,
                                    ),
                                    child: Hero(
                                      tag: widget.title,
                                      child: Text(
                                        widget.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontFamily: "Montserrat",
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  )
                                : showStepProgressIndicator
                                    ? const SizedBox.shrink()
                                    : const MemoryCounter(),
                          );
                        },
                      ),
                      const BottomIcons(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BottomIcons extends StatelessWidget {
  const BottomIcons({super.key});

  @override
  Widget build(BuildContext context) {
    final inheritedData = FullScreenMemoryData.of(context)!;
    final fullScreenState =
        context.findAncestorStateOfType<_FullScreenMemoryState>();

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
            onPressed: () async {
              fullScreenState?._toggleAnimation(pause: true);
              await showDetailsSheet(context, currentFile);
              fullScreenState?._toggleAnimation(pause: false);
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
                fullScreenState?._toggleAnimation(pause: true);
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
                fullScreenState?._toggleAnimation(pause: false);
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
            onPressed: () async {
              fullScreenState?._toggleAnimation(pause: true);
              await share(context, [currentFile]);
              fullScreenState?._toggleAnimation(pause: false);
            },
          ),
        );

        return Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rowChildren,
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
  final ValueNotifier<bool> showTitle;
  const BottomGradient({super.key, required this.showTitle});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder(
        valueListenable: showTitle,
        builder: (context, value, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 875),
            curve: Curves.easeOutQuart,
            height: value ? 240 : 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color.fromARGB(97, 0, 0, 0),
                  Color.fromARGB(42, 0, 0, 0),
                  Colors.transparent,
                ],
                stops: [0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MemoryBlur extends StatelessWidget {
  const _MemoryBlur();

  @override
  Widget build(BuildContext context) {
    final inheritedData = FullScreenMemoryData.of(context)!;
    return ValueListenableBuilder(
      valueListenable: inheritedData.indexNotifier,
      builder: (context, value, _) {
        final currentFile = inheritedData.memories[value].file;
        if (currentFile.fileType == FileType.video) {
          return const SizedBox.shrink();
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 750),
          switchInCurve: Curves.easeOutExpo,
          switchOutCurve: Curves.easeInExpo,
          child: ImageFiltered(
            key: ValueKey(inheritedData.indexNotifier.value),
            imageFilter: ImageFilter.blur(
              sigmaX: 100,
              sigmaY: 100,
            ),
            child: ThumbnailWidget(
              currentFile,
              shouldShowSyncStatus: false,
              shouldShowFavoriteIcon: false,
              shouldShowVideoOverlayIcon: false,
            ),
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
      animationBehavior: AnimationBehavior.preserve,
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
        : ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              child: widget.child,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.translate(
                    offset: Offset(
                      _panAnimation.value.dx * 100,
                      _panAnimation.value.dy * 100,
                    ),
                    child: child,
                  ),
                );
              },
            ),
          );
  }
}
