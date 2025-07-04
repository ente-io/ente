import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/utils/standalone/date_time.dart";

class BackedUpTimeItemWidget extends StatelessWidget {
  final EnteFile file;
  const BackedUpTimeItemWidget(this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    final dateTimeForUpdationTime =
        DateTime.fromMicrosecondsSinceEpoch(file.updationTime!);
    return InfoItemWidget(
      key: const ValueKey("Backedup date"),
      leadingIcon: Icons.backup_outlined,
      title: DateFormat.yMMMEd(Localizations.localeOf(context).languageCode)
          .format(dateTimeForUpdationTime),
      subtitleSection: Future.value([
        Text(
          getTimeIn12hrFormat(dateTimeForUpdationTime) +
              "  " +
              dateTimeForUpdationTime.timeZoneName,
          style: getEnteTextTheme(context).miniMuted,
        ),
      ]),
    );
  }
}
