import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/ui/viewer/date/edit_date_sheet.dart";
import "package:photos/utils/standalone/date_time.dart";

class CreationTimeItem extends StatefulWidget {
  final EnteFile file;
  final int currentUserID;
  const CreationTimeItem(this.file, this.currentUserID, {super.key});

  @override
  State<CreationTimeItem> createState() => _CreationTimeItemState();
}

class _CreationTimeItemState extends State<CreationTimeItem> {
  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.fromMicrosecondsSinceEpoch(
      widget.file.creationTime!,
      isUtc: true,
    ).toLocal();
    return InfoItemWidget(
      key: const ValueKey("Creation time"),
      leadingIcon: Icons.calendar_today_outlined,
      title: DateFormat.yMMMEd(Localizations.localeOf(context).languageCode)
          .format(dateTime),
      subtitleSection: Future.value([
        Text(
          getTimeIn12hrFormat(dateTime) + "  " + dateTime.timeZoneName,
          style: getEnteTextTheme(context).miniMuted,
        ),
      ]),
      editOnTap: ((widget.file.ownerID == null ||
                  widget.file.ownerID == widget.currentUserID) &&
              widget.file.uploadedFileID != null)
          ? () {
              _showDateTimePicker(widget.file);
            }
          : null,
    );
  }

  void _showDateTimePicker(EnteFile file) async {
    final DateTime? newDate = await showEditDateSheet(
      context,
      [file],
      showHeader: false,
    );
    if (newDate != null) {
      widget.file.creationTime = newDate.microsecondsSinceEpoch;
      setState(() {});
    }
  }
}
