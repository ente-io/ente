import "dart:async";

import "package:flutter/widgets.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_constants.dart";
import "package:photos/services/search_service.dart";
import "package:visibility_detector/visibility_detector.dart";

class VisibleFaceSourcePrefetch extends StatefulWidget {
  final List<GenericSearchResult> results;
  final int index;
  final int prefetchCount;
  final int leadingBuffer;
  final Widget child;

  const VisibleFaceSourcePrefetch({
    required this.results,
    required this.index,
    required this.child,
    this.prefetchCount = 24,
    this.leadingBuffer = 0,
    super.key,
  });

  @override
  State<VisibleFaceSourcePrefetch> createState() =>
      _VisibleFaceSourcePrefetchState();
}

class _VisibleFaceSourcePrefetchState extends State<VisibleFaceSourcePrefetch> {
  bool _hasPrefetchedForCurrentItem = false;

  @override
  void didUpdateWidget(covariant VisibleFaceSourcePrefetch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        !identical(oldWidget.results, widget.results)) {
      _hasPrefetchedForCurrentItem = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey(
        "face_source_prefetch_${_visibilityTargetKey()}_${widget.index}",
      ),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= 0.01) {
          _maybePrefetchWindow();
        }
      },
      child: widget.child,
    );
  }

  void _maybePrefetchWindow() {
    if (_hasPrefetchedForCurrentItem) {
      return;
    }
    _hasPrefetchedForCurrentItem = true;
    unawaited(
      SearchService.instance.prefetchFaceSourcesInWindow(
        widget.results,
        startIndex: widget.index,
        count: widget.prefetchCount,
        leadingBuffer: widget.leadingBuffer,
      ),
    );
  }

  String _visibilityTargetKey() {
    if (widget.index < 0 || widget.index >= widget.results.length) {
      return widget.index.toString();
    }
    final result = widget.results[widget.index];
    final personID = result.params[kPersonParamID] as String?;
    final clusterID = result.params[kClusterParamId] as String?;
    return personID ?? clusterID ?? widget.index.toString();
  }
}
