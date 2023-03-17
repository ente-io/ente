import "dart:async";

import "package:flutter/material.dart";
import "package:photos/ui/components/buttons/chip_button_widget.dart";
import "package:photos/ui/components/buttons/inline_button_widget.dart";
import "package:photos/ui/components/info_item_widget.dart";

class LocationTagsWidget extends StatefulWidget {
  final List<double> coordinates;
  const LocationTagsWidget(this.coordinates, {super.key});

  @override
  State<LocationTagsWidget> createState() => _LocationTagsWidgetState();
}

class _LocationTagsWidgetState extends State<LocationTagsWidget> {
  String title = "Add location";
  IconData leadingIcon = Icons.add_location_alt_outlined;
  bool hasChipButtons = false;
  late final Future<List<Widget>> locationTagChips;
  @override
  void initState() {
    locationTagChips = _getLocationTags();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOutExpo,
      switchOutCurve: Curves.easeInOutExpo,
      child: InfoItemWidget(
        key: ValueKey(title),
        leadingIcon: Icons.add_location_alt_outlined,
        title: title,
        subtitleSection: locationTagChips,
        hasChipButtons: hasChipButtons,
      ),
    );
  }

  Future<List<Widget>> _getLocationTags() async {
    final locationTags = [];
    // LocationService.instance.getLocationsByFileID(widget.file.generatedID!);
    if (locationTags.isEmpty) {
      return [
        InlineButtonWidget("Group nearby photos", () {}),
      ];
    }
    setState(() {
      title = "Location";
      leadingIcon = Icons.pin_drop_outlined;
      hasChipButtons = true;
    });
    return locationTags.map((e) => ChipButtonWidget(e)).toList();
  }
}
