import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file.dart";
import "package:photos/services/location_service.dart";
import "package:photos/states/location_state.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/location/pick_center_point_widget.dart";

class EditCenterPointTileWidget extends StatelessWidget {
  const EditCenterPointTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          color: colorScheme.fillFaint,
          child: Icon(
            Icons.location_on_outlined,
            color: colorScheme.strokeFaint,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4.5, 16, 4.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).centerPoint,
                  style: textTheme.body,
                ),
                const SizedBox(height: 4),
                Text(
                  LocationService.instance.convertLocationToDMS(
                    InheritedLocationTagData.of(context)
                        .locationTagEntity!
                        .item
                        .centerPoint,
                  ),
                  style: textTheme.miniMuted,
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () async {
            final File? centerPointFile = await showPickCenterPointSheet(
              context,
              InheritedLocationTagData.of(context).locationTagEntity!,
            );
            if (centerPointFile != null) {
              InheritedLocationTagData.of(context)
                  .updateCenterPoint(centerPointFile.location!);
            }
          },
          icon: const Icon(Icons.edit),
          color: getEnteColorScheme(context).strokeMuted,
        ),
      ],
    );
  }
}
