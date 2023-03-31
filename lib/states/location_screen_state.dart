import "package:flutter/material.dart";
import "package:photos/models/location_tag.dart";

class InheritedLocationScreenState extends InheritedWidget {
  final LocationTag locationTag;
  const InheritedLocationScreenState(
    this.locationTag, {
    super.key,
    required super.child,
  });

  static InheritedLocationScreenState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedLocationScreenState>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedLocationScreenState oldWidget) {
    return oldWidget.locationTag != locationTag;
  }
}
