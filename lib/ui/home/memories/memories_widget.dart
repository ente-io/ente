import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter/rendering.dart";
import "package:infinite_carousel/infinite_carousel.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/memories_setting_changed.dart";
import 'package:photos/models/memory.dart';
import 'package:photos/services/memories_service.dart';
import "package:photos/ui/home/memories/memory_cover_widget.dart";

class MemoriesWidget extends StatefulWidget {
  const MemoriesWidget({Key? key}) : super(key: key);

  @override
  State<MemoriesWidget> createState() => _MemoriesWidgetState();
}

class _MemoriesWidgetState extends State<MemoriesWidget> {
  final double _itemExtent = 120;
  late InfiniteScrollController _controller;
  late StreamSubscription<MemoriesSettingChanged> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Bus.instance.on<MemoriesSettingChanged>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    _controller = InfiniteScrollController();
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
    final collatedMemories = _collateMemories(memories);
    final List<Widget> memoryWidgets = [];
    for (final memories in collatedMemories) {
      memoryWidgets.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: Colors.yellow,
            child: MemoryCovertWidget(memories: memories),
          ),
        ),
      );
    }
    return SizedBox(
      height: 150,
      child: InfiniteCarousel.builder(
        loop: false,
        controller: _controller,
        itemCount: memoryWidgets.length,
        itemExtent: _itemExtent,
        itemBuilder: (context, itemIndex, realIndex) {
          final currentOffset = _itemExtent * realIndex;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final diff = (_controller.offset - currentOffset);
              const maxPadding = 10.0;
              final carouselRatio = _itemExtent / maxPadding;

              return Padding(
                padding: EdgeInsets.only(
                  top: (diff / carouselRatio).abs(),
                  bottom: (diff / carouselRatio).abs(),
                ),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.bottomCenter,
                children: [
                  Image.asset(
                    "assets/onboarding_safe.png",
                    fit: BoxFit.cover,
                  ),
                  const Positioned(
                    bottom: 8,
                    child: Text("1 year ago"),
                  ),
                ],
              ),
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
