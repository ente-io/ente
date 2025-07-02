import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/memories_changed_event.dart";
import "package:photos/events/memories_setting_changed.dart";
import "package:photos/events/memory_seen_event.dart";
import 'package:photos/models/memories/memory.dart';
import "package:photos/models/memories/smart_memory.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/common/loading_widget.dart";
import 'package:photos/ui/home/memories/memory_cover_widget.dart';

class MemoriesWidget extends StatefulWidget {
  const MemoriesWidget({super.key});

  @override
  State<MemoriesWidget> createState() => _MemoriesWidgetState();
}

class _MemoriesWidgetState extends State<MemoriesWidget> {
  late StreamSubscription<MemoriesSettingChanged> _memoriesSettingSubscription;
  late StreamSubscription<MemoriesChangedEvent> _memoriesChangedSubscription;
  late StreamSubscription<MemorySeenEvent> _memorySeenSubscription;
  late double _memoryheight;
  late double _memoryWidth;

  @override
  void initState() {
    super.initState();
    _memoriesSettingSubscription =
        Bus.instance.on<MemoriesSettingChanged>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    _memoriesChangedSubscription =
        Bus.instance.on<MemoriesChangedEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    _memorySeenSubscription =
        Bus.instance.on<MemorySeenEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.sizeOf(context).width;
    //factor will be 2 for most phones in portrait mode
    final factor = (screenWidth / 220).ceil();
    _memoryWidth = screenWidth / (factor * 2);
    _memoryheight = _memoryWidth / MemoryCoverWidget.aspectRatio;
  }

  @override
  void dispose() {
    _memoriesSettingSubscription.cancel();
    _memoriesChangedSubscription.cancel();
    _memorySeenSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!memoriesCacheService.showAnyMemories) {
      return const SizedBox.shrink();
    }
    return _memories();
  }

  Widget _memories() {
    return FutureBuilder<List<SmartMemory>>(
      future: memoriesCacheService.getMemories(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            height: _memoryheight + 12 + 10,
            child: const EnteLoadingWidget(),
          );
        } else {
          if (snapshot.data!.isEmpty) return const SizedBox.shrink();
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

  Widget _buildMemories(List<SmartMemory> memories) {
    final List<(List<Memory>, String)> collatedMemories = [];
    final List<SmartMemory> seenMemories = [];
    for (final memory in memories) {
      final seen = memory.memories.every((element) => element.isSeen());
      if (seen) {
        seenMemories.add(memory);
      } else {
        collatedMemories.add((memory.memories, memory.title));
      }
    }
    collatedMemories.addAll(seenMemories.map((e) => (e.memories, e.title)));

    return SizedBox(
      height: _memoryheight + MemoryCoverWidget.outerStrokeWidth * 2,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        scrollDirection: Axis.horizontal,
        itemCount: collatedMemories.length,
        itemBuilder: (context, itemIndex) {
          return MemoryCoverWidget(
            memories: collatedMemories[itemIndex].$1,
            allMemories: collatedMemories.map((e) => e.$1).toList(),
            height: _memoryheight,
            width: _memoryWidth,
            title: collatedMemories[itemIndex].$2,
            allTitle: collatedMemories.map((e) => e.$2).toList(),
            currentMemoryIndex: itemIndex,
          );
        },
      ),
    );
  }
}
