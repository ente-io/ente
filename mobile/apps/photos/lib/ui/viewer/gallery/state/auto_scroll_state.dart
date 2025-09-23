import "package:flutter/material.dart";

enum AutoScrollZone { appbar, overlaybar }

class AutoScrollState extends InheritedWidget {
  final ValueNotifier<AutoScrollZone?> activeZone;
  final ValueNotifier<double> scrollIntensity;
  final ValueNotifier<Offset?> pointerPosition;

  AutoScrollState({
    super.key,
    required super.child,
  })  : activeZone = ValueNotifier<AutoScrollZone?>(null),
        scrollIntensity = ValueNotifier<double>(0.0),
        pointerPosition = ValueNotifier<Offset?>(null);

  void updateZone(AutoScrollZone? zone) {
    activeZone.value = zone;
  }

  void updateIntensity(double intensity) {
    scrollIntensity.value = intensity.clamp(0.0, 1.0);
  }

  void updatePointerPosition(Offset? position) {
    pointerPosition.value = position;
  }

  void reset() {
    activeZone.value = null;
    scrollIntensity.value = 0.0;
    pointerPosition.value = null;
  }

  static AutoScrollState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AutoScrollState>();
  }

  static AutoScrollState of(BuildContext context) {
    final AutoScrollState? result = maybeOf(context);
    assert(result != null, 'No AutoScrollState found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AutoScrollState oldWidget) {
    return false;
  }

  void dispose() {
    activeZone.dispose();
    scrollIntensity.dispose();
    pointerPosition.dispose();
  }
}
