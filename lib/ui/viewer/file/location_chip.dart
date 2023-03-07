import "package:flutter/material.dart";
import "package:photos/services/location_service.dart";

Widget locationChipList(int id, BuildContext context) {
  final locationService = LocationService.instance;
  final list = locationService.getLocationsByFileID(id);
  return Wrap(
    spacing: 6.0,
    runSpacing: 6.0,
    children: [
      ...list.map((e) => _buildChip(e, context)).toList(),
      _addLocation(context)
    ],
  );
}

Widget _buildChip(String label, BuildContext context) {
  return Chip(
    labelPadding: const EdgeInsets.all(2.0),
    label: Text(
      label,
      style: TextStyle(
        color: Theme.of(context).hintColor,
      ),
    ),
    backgroundColor: Theme.of(context).cardColor,
    elevation: 6.0,
    padding: const EdgeInsets.all(8.0),
  );
}

Widget _addLocation(BuildContext context) {
  return IconButton(
    onPressed: () {},
    icon: const Icon(Icons.add),
  );
}
