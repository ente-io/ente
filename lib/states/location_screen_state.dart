import "package:flutter/material.dart";
import "package:photos/models/local_entity_data.dart";
import 'package:photos/models/location_tag/location_tag.dart';

class InheritedLocationScreenState extends InheritedWidget {
  final LocalEntity<LocationTag> locationTagEntity;
  const InheritedLocationScreenState(
    this.locationTagEntity, {
    super.key,
    required super.child,
  });

  static final memoryCountNotifier = ValueNotifier<int?>(null);

  static InheritedLocationScreenState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedLocationScreenState>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedLocationScreenState oldWidget) {
    return oldWidget.locationTagEntity != locationTagEntity;
  }
}
