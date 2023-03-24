import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/utils/debouncer.dart";

class LocationTagDataStateProvider extends StatefulWidget {
  final List<double> coordinates;
  final Widget child;
  const LocationTagDataStateProvider(this.coordinates, this.child, {super.key});

  @override
  State<LocationTagDataStateProvider> createState() =>
      _LocationTagDataStateProviderState();
}

class _LocationTagDataStateProviderState
    extends State<LocationTagDataStateProvider> {
  int selectedIndex = defaultRadiusValueIndex;
  late List<double> coordinates;
  final Debouncer _debouncer = Debouncer(const Duration(milliseconds: 300));
  @override
  void initState() {
    coordinates = widget.coordinates;
    super.initState();
  }

  void _updateSelectedIndex(int index) {
    _debouncer.cancelDebounce();
    _debouncer.run(() async {
      if (mounted) {
        setState(() {
          selectedIndex = index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedLocationTagData(
      selectedIndex,
      coordinates,
      _updateSelectedIndex,
      child: widget.child,
    );
  }
}

class InheritedLocationTagData extends InheritedWidget {
  final int selectedIndex;
  final List<double> coordinates;
  final VoidCallbackParamInt updateSelectedIndex;
  const InheritedLocationTagData(
    this.selectedIndex,
    this.coordinates,
    this.updateSelectedIndex, {
    required super.child,
    super.key,
  });

  static InheritedLocationTagData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedLocationTagData>()!;
  }

  @override
  bool updateShouldNotify(InheritedLocationTagData oldWidget) {
    return oldWidget.selectedIndex != selectedIndex;
  }
}
