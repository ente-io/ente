import "dart:async";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";

import "package:photos/core/event_bus.dart";
import "package:photos/events/location_tag_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/location_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/services/user_remote_flag_service.dart";
import "package:photos/states/location_screen_state.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/chip_button_widget.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/ui/map/enable_map.dart";
import "package:photos/ui/map/image_marker.dart";
import "package:photos/ui/map/map_screen.dart";
import "package:photos/ui/map/map_view.dart";
import "package:photos/ui/map/tile/layers.dart";

import 'package:photos/ui/viewer/location/add_location_sheet.dart';
import "package:photos/ui/viewer/location/location_screen.dart";
import "package:photos/utils/navigation_util.dart";

class LocationTagsWidget extends StatefulWidget {
  final EnteFile file;
  const LocationTagsWidget(this.file, {super.key});

  @override
  State<LocationTagsWidget> createState() => _LocationTagsWidgetState();
}

class _LocationTagsWidgetState extends State<LocationTagsWidget> {
  String? title;
  IconData? leadingIcon;
  bool? hasChipButtons;
  late Future<List<Widget>> locationTagChips;
  late StreamSubscription<LocationTagUpdatedEvent> _locTagUpdateListener;
  VoidCallback? onTap;
  final _mapController = MapController();
  late bool _hasEnabledMap;
  @override
  void initState() {
    locationTagChips = _getLocationTags();
    _locTagUpdateListener =
        Bus.instance.on<LocationTagUpdatedEvent>().listen((event) {
      locationTagChips = _getLocationTags();
    });
    _hasEnabledMap = UserRemoteFlagService.instance
        .getCachedBoolValue(UserRemoteFlagService.mapEnabled);
    super.initState();
  }

  @override
  void dispose() {
    _locTagUpdateListener.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOutExpo,
      switchOutCurve: Curves.easeInOutExpo,
      child: InfoItemWidget(
        key: ValueKey(title),
        leadingIcon: leadingIcon ?? Icons.pin_drop_outlined,
        title: title,
        subtitleSection: locationTagChips,
        hasChipButtons: hasChipButtons ?? true,
        onTap: onTap,
        endSection: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: SizedBox(
              height: 120,
              child: _hasEnabledMap
                  ? Stack(
                      clipBehavior: Clip.none,
                      key: ValueKey(_hasEnabledMap),
                      children: [
                        MapView(
                          updateVisibleImages: () {},
                          imageMarkers: [
                            ImageMarker(
                              imageFile: widget.file,
                              latitude: widget.file.location!.latitude!,
                              longitude: widget.file.location!.longitude!,
                            ),
                          ],
                          controller: _mapController,
                          center: LatLng(
                            widget.file.location!.latitude!,
                            widget.file.location!.longitude!,
                          ),
                          minZoom: 9,
                          maxZoom: 9,
                          initialZoom: 9,
                          debounceDuration: 0,
                          bottomSheetDraggableAreaHeight: 0,
                          showControls: false,
                          interactiveFlags: InteractiveFlag.none,
                          mapAttributionOptions: MapAttributionOptions(
                            permanentHeight: 16,
                            popupBorderRadius: BorderRadius.circular(4),
                            iconSize: 16,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MapScreen(
                                  filesFutureFn:
                                      SearchService.instance.getAllFiles,
                                  center: LatLng(
                                    widget.file.location!.latitude!,
                                    widget.file.location!.longitude!,
                                  ),
                                  initialZoom: 9 + 1.5,
                                ),
                              ),
                            );
                          },
                          markerSize: const Size(45, 45),
                        ),
                        IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: getEnteColorScheme(context).strokeFaint,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      key: ValueKey(_hasEnabledMap),
                      clipBehavior: Clip.none,
                      children: [
                        MapView(
                          updateVisibleImages: () {},
                          imageMarkers: const [],
                          controller: _mapController,
                          center: const LatLng(
                            13.041599,
                            77.594566,
                          ),
                          minZoom: 9,
                          maxZoom: 9,
                          initialZoom: 9,
                          debounceDuration: 0,
                          bottomSheetDraggableAreaHeight: 0,
                          showControls: false,
                          interactiveFlags: InteractiveFlag.none,
                          mapAttributionOptions: const MapAttributionOptions(
                            iconSize: 0,
                          ),
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 2.8,
                            sigmaY: 2.8,
                          ),
                          child: Container(
                            color: getEnteColorScheme(context)
                                .backgroundElevated
                                .withOpacity(0.5),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: getEnteColorScheme(context).strokeFaint,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            unawaited(
                              requestForMapEnable(context).then((value) {
                                if (value) {
                                  setState(() {
                                    _hasEnabledMap = true;
                                  });
                                }
                              }),
                            );
                          },
                          child: Center(
                            child: Text(
                              "Enable Maps",
                              style: getEnteTextTheme(context).small,
                            ),
                          ),
                        ),
                      ],
                    ),

              /// to be used when state issues are fixed when location is updated
              // editOnTap: widget.file.ownerID == Configuration.instance.getUserID()!
              //     ? () {
              //         showBarModalBottomSheet(
              //           shape: const RoundedRectangleBorder(
              //             borderRadius: BorderRadius.vertical(
              //               top: Radius.circular(5),
              //             ),
              //           ),
              //           backgroundColor:
              //               getEnteColorScheme(context).backgroundElevated,
              //           barrierColor: backdropFaintDark,
              //           context: context,
              //           builder: (context) {
              //             return UpdateLocationDataWidget([widget.file]);
              //           },
              //         );
              //       }
              //     : null,
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Widget>> _getLocationTags() async {
    final locationTags = await LocationService.instance
        .enclosingLocationTags(widget.file.location!);
    if (locationTags.isEmpty) {
      if (mounted) {
        setState(() {
          title = S.of(context).addLocation;
          leadingIcon = Icons.add_location_alt_outlined;
          hasChipButtons = false;
          onTap = () => showAddLocationSheet(
                context,
                widget.file.location!,
              );
        });
      }
      return [
        Text(
          S.of(context).groupNearbyPhotos,
          style: getEnteTextTheme(context).miniBoldMuted,
        ),
      ];
    } else {
      if (mounted) {
        setState(() {
          title = S.of(context).location;
          leadingIcon = Icons.pin_drop_outlined;
          hasChipButtons = true;
          onTap = null;
        });
      }
      final result = locationTags
          .map(
            (locationTagEntity) => ChipButtonWidget(
              locationTagEntity.item.name,
              onTap: () {
                routeToPage(
                  context,
                  LocationScreenStateProvider(
                    locationTagEntity,
                    const LocationScreen(),
                  ),
                );
              },
            ),
          )
          .toList();
      result.add(
        ChipButtonWidget(
          null,
          leadingIcon: Icons.add_outlined,
          onTap: () => showAddLocationSheet(context, widget.file.location!),
        ),
      );
      return result;
    }
  }
}
