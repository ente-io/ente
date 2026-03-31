import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/models/file/file.dart";

enum FullScreenRequestReason {
  userInteraction,
  playbackStateChange,
}

typedef FullScreenRequestCallback = void Function(
  bool shouldEnable,
  FullScreenRequestReason reason,
);

String? detailPageFileIdentifier(EnteFile file) {
  if (file.uploadedFileID != null) {
    return "uploaded_${file.uploadedFileID}";
  }
  if (file.localID != null) {
    return "local_${file.localID}";
  }
  if (file.generatedID != null) {
    return "generated_${file.generatedID}";
  }
  return null;
}

class InheritedDetailPageState extends InheritedWidget {
  final ValueNotifier<bool> enableFullScreenNotifier;
  final ValueNotifier<bool> isInSharedCollectionNotifier;

  /// Holds the stable identifier of the file currently showing thumbnail
  /// fallback. Only the file with matching ID should display the indicator.
  final ValueNotifier<String?> showingThumbnailFallbackNotifier;
  // Cannot be const because we accept a ValueNotifier instance at runtime
  // ignore: prefer_const_constructors_in_immutables
  InheritedDetailPageState({
    super.key,
    required super.child,
    required this.enableFullScreenNotifier,
    required this.isInSharedCollectionNotifier,
    required this.showingThumbnailFallbackNotifier,
  });

  static InheritedDetailPageState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedDetailPageState>()!;

  static InheritedDetailPageState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedDetailPageState>();

  void toggleFullScreenByUser() {
    _applyFullScreenState(!enableFullScreenNotifier.value);
  }

  void requestFullScreen({
    required bool shouldEnable,
    required FullScreenRequestReason reason,
  }) {
    if (!shouldEnable && reason != FullScreenRequestReason.userInteraction) {
      return;
    }
    if (enableFullScreenNotifier.value == shouldEnable) {
      return;
    }
    _applyFullScreenState(shouldEnable);
  }

  void _applyFullScreenState(bool shouldEnable) {
    if (enableFullScreenNotifier.value == shouldEnable) {
      return;
    }
    enableFullScreenNotifier.value = shouldEnable;
    if (shouldEnable) {
      Future.delayed(const Duration(milliseconds: 200), () {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [],
        );
      });
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  @override
  bool updateShouldNotify(InheritedDetailPageState oldWidget) =>
      oldWidget.enableFullScreenNotifier != enableFullScreenNotifier ||
      oldWidget.isInSharedCollectionNotifier != isInSharedCollectionNotifier ||
      oldWidget.showingThumbnailFallbackNotifier !=
          showingThumbnailFallbackNotifier ||
      oldWidget.isZoomedNotifier != isZoomedNotifier;
}
