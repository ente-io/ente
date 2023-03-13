import "package:flutter/material.dart";
import "package:photos/models/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/utils/date_time_util.dart";

class BackedUpDateItemWidget extends StatelessWidget {
  final File file;
  const BackedUpDateItemWidget(this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    final dateTimeForUpdationTime =
        DateTime.fromMicrosecondsSinceEpoch(file.updationTime!);
    return InfoItemWidget(
      key: const ValueKey("Backedup date"),
      leadingIcon: Icons.backup_outlined,
      title: getFullDate(
        DateTime.fromMicrosecondsSinceEpoch(file.updationTime!),
      ),
      subtitleSection: Future.value([
        Text(
          getTimeIn12hrFormat(dateTimeForUpdationTime) +
              "  " +
              dateTimeForUpdationTime.timeZoneName,
          style: getEnteTextTheme(context).smallMuted,
        ),
      ]),
    );
  }
}
