import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/location_tag_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/location_service.dart";
import "package:photos/states/location_screen_state.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/chip_button_widget.dart";
import "package:photos/ui/components/info_item_widget.dart";
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
  @override
  void initState() {
    locationTagChips = _getLocationTags();
    _locTagUpdateListener =
        Bus.instance.on<LocationTagUpdatedEvent>().listen((event) {
      locationTagChips = _getLocationTags();
    });
    super.initState();
  }

  @override
  void dispose() {
    _locTagUpdateListener.cancel();
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
