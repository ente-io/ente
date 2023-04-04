import "dart:math";

import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import "package:photos/models/location_tag/location_tag.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/bottom_of_title_bar_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";

showPickCenterPointSheet(
  BuildContext context,
  LocationTag locationTag,
  VoidCallback onLocationEdited,
) {
  showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return PickCenterPointWidget(locationTag, onLocationEdited);
    },
    shape: const RoundedRectangleBorder(
      side: BorderSide(width: 0),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(5),
      ),
    ),
    topControl: const SizedBox.shrink(),
    backgroundColor: getEnteColorScheme(context).backgroundElevated,
    barrierColor: backdropFaintDark,
  );
}

class PickCenterPointWidget extends StatelessWidget {
  final LocationTag locationTag;
  final VoidCallback onLocationEdited;

  const PickCenterPointWidget(
    this.locationTag,
    this.onLocationEdited, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: min(428, MediaQuery.of(context).size.width),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        BottomOfTitleBarWidget(
                          title: const TitleBarTitleWidget(
                            title: "Pick center point",
                          ),
                          caption: locationTag.name,
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Container(
                      //inner stroke of 1pt + 15 pts of top padding = 16 pts
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: getEnteColorScheme(context).strokeFaint,
                          ),
                        ),
                      ),
                      child: const ButtonWidget(
                        buttonType: ButtonType.secondary,
                        buttonAction: ButtonAction.cancel,
                        isInAlert: true,
                        labelText: "Cancel",
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
