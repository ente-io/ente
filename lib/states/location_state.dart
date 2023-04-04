import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/utils/debouncer.dart";

class LocationTagStateProvider extends StatefulWidget {
  //This is used when we want to edit a locaiton tag
  final LocationTag? locationTag;
  //This is used when we want to create a new location tag. We can't use
  //LocationTag becuase aSquare and bSquare will be null.
  final Location? centerPoint;
  final Widget child;
  const LocationTagStateProvider(
    this.child, {
    this.centerPoint,
    this.locationTag,
    super.key,
  });

  @override
  State<LocationTagStateProvider> createState() =>
      _LocationTagStateProviderState();
}

class _LocationTagStateProviderState extends State<LocationTagStateProvider> {
  late int selectedRaduisIndex = defaultRadiusValueIndex;
  late Location centerPoint;
  final Debouncer _selectedRadiusDebouncer =
      Debouncer(const Duration(milliseconds: 300));
  @override
  void initState() {
    assert(widget.centerPoint != null || widget.locationTag != null);
    centerPoint = widget.locationTag?.centerPoint ?? widget.centerPoint!;
    selectedRaduisIndex =
        widget.locationTag?.radiusIndex ?? defaultRadiusValueIndex;
    super.initState();
  }

  void _updateSelectedIndex(int index) {
    _selectedRadiusDebouncer.cancelDebounce();
    _selectedRadiusDebouncer.run(() async {
      if (mounted) {
        setState(() {
          selectedRaduisIndex = index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedLocationTagData(
      selectedRaduisIndex,
      centerPoint,
      _updateSelectedIndex,
      widget.locationTag,
      child: widget.child,
    );
  }
}

class InheritedLocationTagData extends InheritedWidget {
  final int selectedRadiusIndex;
  final Location centerPoint;
  //locationTag is null when we are creating a new location tag in a add location sheet
  final LocationTag? locationTag;
  final VoidCallbackParamInt updateSelectedIndex;
  const InheritedLocationTagData(
    this.selectedRadiusIndex,
    this.centerPoint,
    this.updateSelectedIndex,
    this.locationTag, {
    required super.child,
    super.key,
  });

  static InheritedLocationTagData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedLocationTagData>()!;
  }

  @override
  bool updateShouldNotify(InheritedLocationTagData oldWidget) {
    return oldWidget.selectedRadiusIndex != selectedRadiusIndex ||
        oldWidget.centerPoint != centerPoint ||
        oldWidget.locationTag != locationTag;
  }
}
