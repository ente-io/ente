import "dart:async";

import 'package:flutter/material.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/memories_setting_changed.dart";
import 'package:photos/models/memory.dart';
import 'package:photos/services/memories_service.dart';
import "package:photos/ui/home/memories/memory_cover_widget.dart";
import "package:photos/ui/home/memories/memory_cover_widget_new.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

class MemoriesWidget extends StatefulWidget {
  const MemoriesWidget({Key? key}) : super(key: key);

  @override
  State<MemoriesWidget> createState() => _MemoriesWidgetState();
}

class _MemoriesWidgetState extends State<MemoriesWidget> {
  final double _widthOfItem = 85;
  late ScrollController _controller;
  late StreamSubscription<MemoriesSettingChanged> _subscription;

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
    final widthOfScreen = MediaQuery.sizeOf(context).width;
    final collatedMemories = _collateMemories(memories);
    final List<Widget> memoryWidgets = [];
    for (final memories in collatedMemories) {
      memoryWidgets.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: MemoryCovertWidget(memories: memories),
        ),
      );
    }
    return SizedBox(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: _controller,
        itemCount: memoryWidgets.length,
        itemBuilder: (context, itemIndex) {
          final offsetOfItem = _widthOfItem * itemIndex;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final diff =
                  (_controller.offset - offsetOfItem) + widthOfScreen / 7;
              final scale = 1 - (diff / widthOfScreen).abs() / 3;
              //Adding this row is a workaround for making height of memory cover
              //render as 125 * scale. Without this, height of rendered memory
              //cover will be 125.
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Row(
                  children: [
                    MemoryCoverWidgetNew(
                      memories: memories,
                      thumbnailWidget: child!,
                      scale: scale,
                    ),
                  ],
                ),
              );
            },
            child: ThumbnailWidget(
              memories[0].file,
              shouldShowArchiveStatus: false,
            ),
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
