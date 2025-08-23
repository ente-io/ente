import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/user_details.dart';
import 'package:photos/states/user_details_state.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';

class SettingsTitleBarWidget extends StatelessWidget {
  const SettingsTitleBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final inheritedDetails = InheritedUserDetails.of(context);
    final userDetails = inheritedDetails?.userDetails;
    bool isCached = false;
    if (inheritedDetails != null) {
      isCached = inheritedDetails.isCached;
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.keyboard_double_arrow_left_outlined),
            ),
            userDetails is UserDetails && !isCached
                ? Text(
                    AppLocalizations.of(context).memoryCount(
                      count: userDetails.fileCount,
                      formattedCount:
                          NumberFormat().format(userDetails.fileCount),
                    ),
                    // "${NumberFormat().format(userDetails.fileCount)} memories",
                    style: getEnteTextTheme(context).largeBold,
                  )
                : const EnteLoadingWidget(),
          ],
        ),
      ),
    );
  }
}
