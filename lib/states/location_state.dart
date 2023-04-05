import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/location_tag_updated_event.dart";
import "package:photos/models/local_entity_data.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/utils/debouncer.dart";

class LocationTagStateProvider extends StatefulWidget {
  //This is used when we want to edit a locaiton tag
  final LocalEntity<LocationTag>? locationTagEntity;
  //This is used when we want to create a new location tag. We can't use
  //LocationTag becuase aSquare and bSquare will be null.
  final Location? centerPoint;
  final Widget child;
  const LocationTagStateProvider(
    this.child, {
    this.centerPoint,
    this.locationTagEntity,
    super.key,
  });

  @override
  State<LocationTagStateProvider> createState() =>
      _LocationTagStateProviderState();
}

class _LocationTagStateProviderState extends State<LocationTagStateProvider> {
  int _selectedRaduisIndex = defaultRadiusValueIndex;
  late Location? _centerPoint;
  late LocalEntity<LocationTag>? _locationTagEntity;
  final Debouncer _selectedRadiusDebouncer =
      Debouncer(const Duration(milliseconds: 300));
  late final StreamSubscription _locTagEntityListener;
  @override
  void initState() {
    _locationTagEntity = widget.locationTagEntity;
    _centerPoint = widget.centerPoint;
    assert(_centerPoint != null || _locationTagEntity != null);
    _centerPoint = _locationTagEntity?.item.centerPoint ?? _centerPoint!;
    _selectedRaduisIndex =
        _locationTagEntity?.item.radiusIndex ?? defaultRadiusValueIndex;
    _locTagEntityListener =
        Bus.instance.on<LocationTagUpdatedEvent>().listen((event) {
      _locationTagUpdateListener(event);
    });
    super.initState();
  }

  @override
  void dispose() {
    _locTagEntityListener.cancel();
    super.dispose();
  }

  void _locationTagUpdateListener(LocationTagUpdatedEvent event) {
    if (event.type == LocTagEventType.update) {
      if (event.updatedLocTagEntities!.first.id == _locationTagEntity!.id) {
        setState(() {
          final updatedLocTagEntity = event.updatedLocTagEntities!.first;
          _selectedRaduisIndex = updatedLocTagEntity.item.radiusIndex;
          _centerPoint = updatedLocTagEntity.item.centerPoint;
          _locationTagEntity = updatedLocTagEntity;
        });
      }
    }
  }

  void _updateSelectedIndex(int index) {
    _selectedRadiusDebouncer.cancelDebounce();
    _selectedRadiusDebouncer.run(() async {
      if (mounted) {
        setState(() {
          _selectedRaduisIndex = index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedLocationTagData(
      _selectedRaduisIndex,
      _centerPoint!,
      _updateSelectedIndex,
      _locationTagEntity,
      child: widget.child,
    );
  }
}

class InheritedLocationTagData extends InheritedWidget {
  final int selectedRadiusIndex;
  final Location centerPoint;
  //locationTag is null when we are creating a new location tag in a add location sheet
  final LocalEntity<LocationTag>? locationTagEntity;
  final VoidCallbackParamInt updateSelectedIndex;
  const InheritedLocationTagData(
    this.selectedRadiusIndex,
    this.centerPoint,
    this.updateSelectedIndex,
    this.locationTagEntity, {
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
        oldWidget.locationTagEntity != locationTagEntity;
  }
}
