// import "package:flutter/material.dart";

// class CustomScrollBar extends StatefulWidget {
//   const CustomScrollBar({super.key});

//   @override
//   State<CustomScrollBar> createState() => _CustomScrollBarState();
// }

// class _CustomScrollBarState extends State<CustomScrollBar> {
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }
// }

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/models/gallery/gallery_sections.dart";
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import "package:photos/utils/misc_util.dart";

class PositionConstraints {
  final double top;
  final double bottom;
  PositionConstraints({
    required this.top,
    required this.bottom,
  });
}

class CustomScrollBar extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final GalleryGroups galleryGroups;
  const CustomScrollBar({
    super.key,
    required this.child,
    required this.scrollController,
    required this.galleryGroups,
  });

  @override
  State<CustomScrollBar> createState() => CustomScrollBarState();
}

class CustomScrollBarState extends State<CustomScrollBar> {
  final _key = GlobalKey();
  PositionConstraints? _positionConstraints;

  /// In the range of [0, 1]. 0 is the top of the track and 1 is the bottom
  /// of the track.
  double _scrollPosition = 0;

  final _heightOfScrollBar = 40.0;
  double? _heightOfVisualTrack;
  double? _heightOfLogicalTrack;
  String toolTipText = "";
  final _logger = Logger("CustomScrollBar");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _heightOfVisualTrack = await _getHeightOfVisualTrack();
      _heightOfLogicalTrack = _heightOfVisualTrack! - _heightOfScrollBar;
      _positionConstraints =
          PositionConstraints(top: 0, bottom: _heightOfLogicalTrack!);
    });

    widget.scrollController.addListener(_scrollControllerListener);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollControllerListener);

    super.dispose();
  }

  void _scrollControllerListener() {
    setState(() {
      _scrollPosition = widget.scrollController.position.pixels /
          widget.scrollController.position.maxScrollExtent *
          _heightOfLogicalTrack!;
      _getHeadingForScrollPosition(_scrollPosition).then((heading) {
        toolTipText = heading;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        RepaintBoundary(child: widget.child),
        RepaintBoundary(
          child: SizedBox(
            key: _key,
            height: double.infinity,
            width: 20,
          ),
        ),
        Positioned(
          top: _scrollPosition,
          child: RepaintBoundary(
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                //Use debouncer if needed
                final newPosition = _scrollPosition + details.delta.dy;
                if (newPosition >= _positionConstraints!.top &&
                    newPosition <= _positionConstraints!.bottom) {
                  widget.scrollController.jumpTo(
                    widget.scrollController.position.maxScrollExtent *
                        (newPosition / _heightOfLogicalTrack!),
                  );
                }
              },
              child: _ScrollBarWithToolTip(
                tooltipText: toolTipText,
                heightOfScrollBar: _heightOfScrollBar,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<String> _getHeadingForScrollPosition(
    double scrollPosition,
  ) async {
    final heightOfGallery = widget.galleryGroups.groupLayouts.last.maxOffset;

    final normalizedScrollPosition =
        (scrollPosition / _heightOfLogicalTrack!) * heightOfGallery;
    final scrollPostionHeadingPoints =
        widget.galleryGroups.scrollOffsetToGroupIdMap.keys.toList();
    assert(
      _isSortedAscending(scrollPostionHeadingPoints),
      "Scroll position is not sorted in ascending order",
    );

    assert(
      scrollPostionHeadingPoints.isNotEmpty,
      "Scroll position to heading map is empty. Cannot find heading for scroll position",
    );

    // Binary search to find the index of the largest key <= scrollPosition
    int low = 0;
    int high = scrollPostionHeadingPoints.length - 1;
    int floorIndex = 0; // Default to the first index

    // Handle the case where scrollPosition is smaller than the first key.
    // In this scenario, we associate it with the first heading.
    if (normalizedScrollPosition < scrollPostionHeadingPoints.first) {
      return widget.galleryGroups
          .scrollOffsetToGroupIdMap[scrollPostionHeadingPoints.first]!;
    }

    while (low <= high) {
      final mid = low + (high - low) ~/ 2;
      final midValue = scrollPostionHeadingPoints[mid];

      if (midValue <= normalizedScrollPosition) {
        // This key is less than or equal to the target scrollPosition.
        // It's a potential floor. Store its index and try searching higher
        // for a potentially closer floor value.
        floorIndex = mid;
        low = mid + 1;
      } else {
        // This key is greater than the target scrollPosition.
        // The floor must be in the lower half.
        high = mid - 1;
      }
    }

    // After the loop, floorIndex holds the index of the largest key
    // that is less than or equal to the scrollPosition.
    final currentGroupID = widget.galleryGroups
        .scrollOffsetToGroupIdMap[scrollPostionHeadingPoints[floorIndex]]!;
    return widget
        .galleryGroups.groupIdToheaderDataMap[currentGroupID]!.groupType
        .getTitle(
      context,
      widget.galleryGroups.groupIDToFilesMap[currentGroupID]!.first,
    );
  }

  Future<double> _getHeightOfVisualTrack() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    assert(renderBox != null, "RenderBox is null");
    // Retry for : https://github.com/flutter/flutter/issues/25827
    return MiscUtil().getNonZeroDoubleWithRetry(
      () => renderBox!.size.height,
      id: "getHeightOfVisualTrack",
    );
  }

  bool _isSortedAscending(List<double> list) {
    if (list.length <= 1) {
      return true;
    }
    for (int i = 0; i < list.length - 1; i++) {
      if (list[i] > list[i + 1]) {
        return false;
      }
    }
    return true;
  }
}

class _ScrollBarWithToolTip extends StatelessWidget {
  final String tooltipText;
  final double heightOfScrollBar;
  const _ScrollBarWithToolTip({
    required this.tooltipText,
    required this.heightOfScrollBar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: const Color(0xFF607D8B),
          child: Text(
            tooltipText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Container(
          color: const Color(0xFF000000),
          height: heightOfScrollBar,
          width: 20,
        ),
      ],
    );
  }
}
