import "dart:async";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/models/gallery/gallery_sections.dart";
import "package:photos/ui/viewer/gallery/scrollbar/scroll_bar_with_use_notifier.dart";
import "package:photos/utils/misc_util.dart";

class CustomScrollBar2 extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final GalleryGroups galleryGroups;
  const CustomScrollBar2({
    super.key,
    required this.child,
    required this.scrollController,
    required this.galleryGroups,
  });

  @override
  State<CustomScrollBar2> createState() => _CustomScrollBar2State();
}

/*
Create a new variable that stores Position to title mapping which will be used
to show scrollbar divisions. 

List of scrollbar divisions can be obtained from galleryGroups.scrollbarDivisions.
And the scroll positions of each division can be obtained from 
galleryGroups.groupIdToScrollOffsetMap[groupID] where groupID.

Can ignore adding the top offset of the header for accuracy. 

Get the height of the scrollbar and create a normalized position for each
division and populate position to title mapping. 
*/

class _CustomScrollBar2State extends State<CustomScrollBar2> {
  final _logger = Logger("CustomScrollBar2");
  final _key = GlobalKey();
  final inUseNotifier = ValueNotifier<bool>(false);
  List<({double position, String title})>? positionToTitleMap;
  static const _bottomPadding = 92.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _computePositionToTitleMap();
    });
  }

  @override
  void didUpdateWidget(covariant CustomScrollBar2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    _computePositionToTitleMap();
  }

  @override
  void dispose() {
    inUseNotifier.dispose();
    super.dispose();
  }

  Future<void> _computePositionToTitleMap() async {
    _logger.info("computing postition to title map");
    final result = <({double position, String title})>[];
    final heightOfScrollTrack = await _getHeightOfScrollTrack();
    final maxScrollExtent = widget.scrollController.position.maxScrollExtent;

    for (ScrollbarDivision scrollbarDivision
        in widget.galleryGroups.scrollbarDivisions) {
      final scrollOffsetOfGroup = widget
          .galleryGroups.groupIdToScrollOffsetMap[scrollbarDivision.groupID]!;

      final groupScrollOffsetToUse = scrollOffsetOfGroup - heightOfScrollTrack;
      if (groupScrollOffsetToUse < 0) {
        result.add((position: 0, title: scrollbarDivision.title));
      } else {
        final normalizedPosition =
            (groupScrollOffsetToUse / maxScrollExtent) * heightOfScrollTrack;
        result.add(
          (position: normalizedPosition, title: scrollbarDivision.title),
        );
      }
    }
    final filteredResult = <({double position, String title})>[];

    // Remove first scrollbar division since it doesn't add value in terms of UX
    result.removeAt(0);

    // Filter out positions that are too close to each other
    if (result.isNotEmpty) {
      filteredResult.add(result.first);
      for (int i = 1; i < result.length; i++) {
        if ((result[i].position - filteredResult.last.position).abs() >= 60) {
          filteredResult.add(result[i]);
        }
      }
    }

    setState(() {
      positionToTitleMap = filteredResult;
    });
  }

  Future<double> _getHeightOfScrollTrack() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    assert(renderBox != null, "RenderBox is null");
    // Retry for : https://github.com/flutter/flutter/issues/25827
    return MiscUtil()
        .getNonZeroDoubleWithRetry(
          () => renderBox!.size.height,
          id: "getHeightOfScrollTrack",
        )
        .then((value) => value - _bottomPadding);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        // This media query is used to adjust the bottom padding of the scrollbar
        MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(bottom: _bottomPadding),
          ),
          child: ScrollbarWithUseNotifer(
            key: _key,
            controller: widget.scrollController,
            interactive: true,
            inUseNotifier: inUseNotifier,
            child: widget.child,
          ),
        ),
        positionToTitleMap == null
            ? const SizedBox.shrink()
            : ValueListenableBuilder<bool>(
                valueListenable: inUseNotifier,
                builder: (context, inUse, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: !inUse
                        ? const SizedBox.shrink()
                        : Stack(
                            children: positionToTitleMap!.map((record) {
                              return Positioned(
                                top: record.position,
                                right: 24,
                                child: Container(
                                  color: Colors.teal,
                                  child: Center(
                                    child: Text(
                                      record.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  );
                },
              ),
      ],
    );
  }
}

class ScrollbarDivision {
  final String groupID;
  final String title;

  ScrollbarDivision({
    required this.groupID,
    required this.title,
  });
}
