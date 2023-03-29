import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/utils/debouncer.dart";

class AddLocationTagStateProvider extends StatefulWidget {
  final List<double> coordinates;
  final Widget child;
  const AddLocationTagStateProvider(this.coordinates, this.child, {super.key});

  @override
  State<AddLocationTagStateProvider> createState() =>
      _AddLocationTagStateProviderState();
}

class _AddLocationTagStateProviderState
    extends State<AddLocationTagStateProvider> {
  int selectedRaduisIndex = defaultRadiusValueIndex;
  late List<double> coordinates;
  final Debouncer _selectedRadiusDebouncer =
      Debouncer(const Duration(milliseconds: 300));
  @override
  void initState() {
    coordinates = widget.coordinates;
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
    return InheritedAddLocationTagData(
      selectedRaduisIndex,
      coordinates,
      _updateSelectedIndex,
      child: widget.child,
    );
  }
}

class InheritedAddLocationTagData extends InheritedWidget {
  final int selectedRadiusIndex;
  final List<double> coordinates;
  final VoidCallbackParamInt updateSelectedIndex;
  const InheritedAddLocationTagData(
    this.selectedRadiusIndex,
    this.coordinates,
    this.updateSelectedIndex, {
    required super.child,
    super.key,
  });

  static InheritedAddLocationTagData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedAddLocationTagData>()!;
  }

  @override
  bool updateShouldNotify(InheritedAddLocationTagData oldWidget) {
    return oldWidget.selectedRadiusIndex != selectedRadiusIndex;
  }
}
