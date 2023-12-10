import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:photos/ui/map/map_button.dart";
import "package:photos/ui/map/tile/layers.dart";

class AddLocationDataWidget extends StatefulWidget {
  const AddLocationDataWidget({super.key});

  @override
  State<AddLocationDataWidget> createState() => _AddLocationDataWidgetState();
}

class _AddLocationDataWidgetState extends State<AddLocationDataWidget> {
  final MapController _mapController = MapController();
  ValueNotifier<LatLng?> selectedLocation = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    selectedLocation.dispose();

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
              final zoom = selectedLocation.value == null
                  ? _mapController.zoom + 2.0
                  : _mapController.zoom;
              _mapController.move(latlng, zoom);

              selectedLocation.value = latlng;
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
          // bottom: widget.bottomSheetDraggableAreaHeight + 10,
          bottom: 30,

          right: 10,
          child: Column(
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
          valueListenable: selectedLocation,
          builder: (context, value, _) {
            return value != null
                ? const Positioned(
                    bottom: 20,
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Icon(
                      Icons.location_pin,
                      color: Color.fromARGB(255, 250, 34, 19),
                      size: 40,
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
        ValueListenableBuilder(
          valueListenable: selectedLocation,
          builder: (context, value, _) {
            return value != null
                ? Positioned(
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        Text(
                          selectedLocation.value.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
