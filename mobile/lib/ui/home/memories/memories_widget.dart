import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/memories_setting_changed.dart";
import 'package:photos/models/memories/memory.dart';
import "package:photos/models/memories/smart_memory.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/memories_service.dart';
import "package:photos/ui/common/loading_widget.dart";
import 'package:photos/ui/home/memories/memory_cover_widget.dart';

class MemoriesWidget extends StatefulWidget {
  const MemoriesWidget({super.key});

  @override
  State<MemoriesWidget> createState() => _MemoriesWidgetState();
}

class _MemoriesWidgetState extends State<MemoriesWidget> {
  late ScrollController _controller;
  late StreamSubscription<MemoriesSettingChanged> _subscription;
  late double _maxHeight;
  late double _maxWidth;

  @override
  void initState() {
    super.initState();
    _subscription = Bus.instance.on<MemoriesSettingChanged>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    _controller = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.sizeOf(context).width;
    //factor will be 2 for most phones in portrait mode
    final factor = (screenWidth / 220).ceil();
    _maxWidth = screenWidth / (factor * 2);
    _maxHeight = _maxWidth / MemoryCoverWidget.aspectRatio;
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MemoriesService.instance.showMemories) {
      return const SizedBox.shrink();
    }
    if (memoriesCacheService.enableSmartMemories) {
      return _smartMemories();
    }
    return _oldMemories();
  }

  Widget _smartMemories() {
    return FutureBuilder<List<SmartMemory>>(
      future: memoriesCacheService.getMemories(
        null,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isEmpty) {
          return _oldMemories();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            height: _maxHeight + 12 + 10,
            child: const EnteLoadingWidget(),
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 12,
              ),
              _buildSmartMemories(snapshot.data!),
              const SizedBox(height: 10),
            ],
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCirc,
              );
        }
      },
    );
  }

  Widget _oldMemories() {
    return FutureBuilder<List<Memory>>(
      future: MemoriesService.instance.getMemories(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            height: _maxHeight + 12 + 10,
            child: const EnteLoadingWidget(),
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 12,
              ),
              _buildMemories(snapshot.data!),
              const SizedBox(height: 10),
            ],
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCirc,
              );
        }
      },
    );
  }

  Widget _buildSmartMemories(List<SmartMemory> memories) {
    final collatedMemories =
        memories.map((e) => (e.memories, e.title)).toList();

    return SizedBox(
      height: _maxHeight + MemoryCoverWidget.outerStrokeWidth * 2,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        scrollDirection: Axis.horizontal,
        controller: _controller,
        itemCount: collatedMemories.length,
        itemBuilder: (context, itemIndex) {
          final maxScaleOffsetX =
              _maxWidth + MemoryCoverWidget.horizontalPadding * 2;
          final offsetOfItem =
              (_maxWidth + MemoryCoverWidget.horizontalPadding * 2) * itemIndex;
          return MemoryCoverWidget(
            memories: collatedMemories[itemIndex].$1,
            controller: _controller,
            offsetOfItem: offsetOfItem,
            maxHeight: _maxHeight,
            maxWidth: _maxWidth,
            maxScaleOffsetX: maxScaleOffsetX,
            title: collatedMemories[itemIndex].$2,
          );
        },
      ),
    );
  }

  Widget _buildMemories(List<Memory> memories) {
    final collatedMemories = _collateMemories(memories);

    return SizedBox(
      height: _maxHeight + MemoryCoverWidget.outerStrokeWidth * 2,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        scrollDirection: Axis.horizontal,
        controller: _controller,
        itemCount: collatedMemories.length,
        itemBuilder: (context, itemIndex) {
          final maxScaleOffsetX =
              _maxWidth + MemoryCoverWidget.horizontalPadding * 2;
          final offsetOfItem =
              (_maxWidth + MemoryCoverWidget.horizontalPadding * 2) * itemIndex;
          return MemoryCoverWidget(
            memories: collatedMemories[itemIndex],
            controller: _controller,
            offsetOfItem: offsetOfItem,
            maxHeight: _maxHeight,
            maxWidth: _maxWidth,
            maxScaleOffsetX: maxScaleOffsetX,
          );
        },
      ),
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
