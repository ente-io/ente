import "package:flutter/material.dart";
import "package:flutter/services.dart";

enum FullScreenRequestReason {
  userInteraction,
  playbackStateChange,
}

typedef FullScreenRequestCallback = void Function(
  bool shouldEnable,
  FullScreenRequestReason reason,
);

class InheritedDetailPageState extends InheritedWidget {
  final ValueNotifier<bool> enableFullScreenNotifier;
  // Cannot be const because we accept a ValueNotifier instance at runtime
  // ignore: prefer_const_constructors_in_immutables
  InheritedDetailPageState({
    super.key,
    required super.child,
    required this.enableFullScreenNotifier,
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
      oldWidget.enableFullScreenNotifier != enableFullScreenNotifier;
}
