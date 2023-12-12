import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:photos/models/file/file.dart";
import "package:photos/ui/map/map_button.dart";
import "package:photos/ui/map/tile/layers.dart";

class UpdateLocationDataWidget extends StatefulWidget {
  final List<EnteFile> files;
  const UpdateLocationDataWidget(this.files, {super.key});

  @override
  State<UpdateLocationDataWidget> createState() =>
      _UpdateLocationDataWidgetState();
}

class _UpdateLocationDataWidgetState extends State<UpdateLocationDataWidget> {
  final MapController _mapController = MapController();
  LatLng? selectedLocation;
  ValueNotifier hasSelectedLocation = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    hasSelectedLocation.dispose();
    _mapController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            zoom: 3,
            maxZoom: 18.0,
            minZoom: 2.8,
            onTap: (tapPosition, latlng) {
              final zoom = selectedLocation == null
                  ? _mapController.zoom + 2.0
                  : _mapController.zoom;
              _mapController.move(latlng, zoom);

              selectedLocation = latlng;
              hasSelectedLocation.value = true;
            },
            onPositionChanged: (position, hasGesture) {
              if (selectedLocation != null) {
                selectedLocation = position.center;
              }
            },
          ),
          children: const [
            OSMFranceTileLayer(),
          ],
        ),
        Positioned(
          // bottom: widget.bottomSheetDraggableAreaHeight + 10,
          bottom: 30,

          right: 10,
          child: Column(
            children: [
              MapButton(
                // icon: Icons.add_location_alt_outlined,
                icon: Icons.check,

                onPressed: () {},
                heroTag: 'add-location',
              ),
              const SizedBox(height: 16),
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
