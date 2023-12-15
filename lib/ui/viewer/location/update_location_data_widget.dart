import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/location/location.dart";
import "package:photos/services/files_service.dart";
import "package:photos/services/location_service.dart";
import "package:photos/theme/effects.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/map/map_button.dart";
import "package:photos/ui/map/tile/layers.dart";
import "package:photos/utils/toast_util.dart";

class UpdateLocationDataWidget extends StatefulWidget {
  final List<EnteFile> files;
  const UpdateLocationDataWidget(this.files, {super.key});

  @override
  State<UpdateLocationDataWidget> createState() =>
      _UpdateLocationDataWidgetState();
}

class _UpdateLocationDataWidgetState extends State<UpdateLocationDataWidget> {
  final MapController _mapController = MapController();
  ValueNotifier hasSelectedLocation = ValueNotifier(false);
  final selectedLocation = ValueNotifier<LatLng?>(null);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    hasSelectedLocation.dispose();
    selectedLocation.dispose();
    _mapController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            zoom: 3,
            maxZoom: 18.0,
            minZoom: 2.8,
            onTap: (tapPosition, latlng) {
              final zoom = selectedLocation.value == null
                  ? _mapController.zoom + 2.0
                  : _mapController.zoom;
              _mapController.move(latlng, zoom);

              selectedLocation.value = latlng;
              hasSelectedLocation.value = true;
            },
            onPositionChanged: (position, hasGesture) {
              if (selectedLocation.value != null) {
                selectedLocation.value = position.center;
              }
            },
          ),
          children: const [
            OSMFranceTileLayer(),
          ],
        ),
        Positioned(
          top: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: getEnteColorScheme(context).backgroundElevated,
              boxShadow: shadowFloatFaintLight,
            ),
            child: ValueListenableBuilder(
              builder: (context, value, _) {
                final locationInDMS =
                    LocationService.instance.convertLocationToDMS(
                  Location(
                    latitude: value?.latitude,
                    longitude: value?.longitude,
                  ),
                );
                return locationInDMS != null
                    ? SizedBox(
                        width: 80 * MediaQuery.textScaleFactorOf(context),
                        child: Column(
                          children: [
                            Text(
                              locationInDMS[0],
                              style: textTheme.mini,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              locationInDMS[1],
                              style: textTheme.mini,
                            ),
                          ],
                        ),
                      )
                    : Text(
                        "Select a location",
                        style: textTheme.mini,
                      );
              },
              valueListenable: selectedLocation,
            ),
          ),
        ),
        Positioned(
          // bottom: widget.bottomSheetDraggableAreaHeight + 10,
          bottom: 48,

          right: 24,
          left: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MapButton(
                icon: Icons.add,
                onPressed: () {
                  _mapController.move(
                    _mapController.center,
                    _mapController.zoom + 1,
                  );
                },
                heroTag: 'zoom-in',
              ),
              const SizedBox(height: 8),
              MapButton(
                icon: Icons.remove,
                onPressed: () {
                  _mapController.move(
                    _mapController.center,
                    _mapController.zoom - 1,
                  );
                },
                heroTag: 'zoom-out',
              ),
              const SizedBox(height: 8),
              MapButton(
                icon: Icons.check,
                onPressed: () async {
                  if (selectedLocation.value == null) {
                    unawaited(
                      showShortToast(
                        context,
                        "Select a location first",
                      ),
                    );
                    return;
                  }
                  await FilesService.instance.bulkEditLocationData(
                    widget.files,
                    selectedLocation.value,
                    context,
                  );
                  Navigator.of(context).pop();
                },
                heroTag: 'add-location',
              ),
            ],
          ),
        ),
        ValueListenableBuilder(
          valueListenable: hasSelectedLocation,
          builder: (context, value, _) {
            return value
                ? const Positioned(
                    bottom: 16,
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Icon(
                      Icons.location_pin,
                      color: Color.fromARGB(255, 250, 34, 19),
                      size: 32,
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
