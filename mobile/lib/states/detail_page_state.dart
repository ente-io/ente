import "package:flutter/material.dart";
import "package:flutter/services.dart";

class InheritedDetailPageState extends InheritedWidget {
  final enableFullScreenNotifier = ValueNotifier(false);
  InheritedDetailPageState({
    super.key,
    required super.child,
  });

  static InheritedDetailPageState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedDetailPageState>()!;

  static InheritedDetailPageState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedDetailPageState>();

  void toggleFullScreen({bool? shouldEnable}) {
    if (shouldEnable != null) {
      if (enableFullScreenNotifier.value == shouldEnable) return;
    }
    enableFullScreenNotifier.value = !enableFullScreenNotifier.value;
    if (enableFullScreenNotifier.value) {
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
