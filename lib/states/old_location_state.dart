import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/utils/debouncer.dart";

class OldLocationTagStateProvider extends StatefulWidget {
  final Widget child;
  const OldLocationTagStateProvider(this.child, {super.key});

  @override
  State<OldLocationTagStateProvider> createState() =>
      _OldLocationTagStateProviderState();
}

class _OldLocationTagStateProviderState
    extends State<OldLocationTagStateProvider> {
  int selectedRaduisIndex = defaultRadiusValueIndex;
  final Debouncer _selectedRadiusDebouncer =
      Debouncer(const Duration(milliseconds: 300));

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
    return InheritedOldLocationTagData(
      selectedRaduisIndex,
      _updateSelectedIndex,
      child: widget.child,
    );
  }
}

class InheritedOldLocationTagData extends InheritedWidget {
  final int selectedRadiusIndex;
  final VoidCallbackParamInt updateSelectedIndex;
  const InheritedOldLocationTagData(
    this.selectedRadiusIndex,
    this.updateSelectedIndex, {
    required super.child,
    super.key,
  });

  static InheritedOldLocationTagData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedOldLocationTagData>()!;
  }

  @override
  bool updateShouldNotify(InheritedOldLocationTagData oldWidget) {
    return oldWidget.selectedRadiusIndex != selectedRadiusIndex;
  }
}
