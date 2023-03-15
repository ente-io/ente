import "package:flutter/material.dart";
import "package:flutter_datetime_picker/flutter_datetime_picker.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/models/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/utils/date_time_util.dart";
import "package:photos/utils/magic_util.dart";

class CreationTimeItem extends StatefulWidget {
  final File file;
  final int currentUserID;
  const CreationTimeItem(this.file, this.currentUserID, {super.key});

  @override
  State<CreationTimeItem> createState() => _CreationTimeItemState();
}

class _CreationTimeItemState extends State<CreationTimeItem> {
  @override
  Widget build(BuildContext context) {
    final dateTime =
        DateTime.fromMicrosecondsSinceEpoch(widget.file.creationTime!);
    return InfoItemWidget(
      key: const ValueKey("Creation time"),
      leadingIcon: Icons.calendar_today_outlined,
      title: getFullDate(
        DateTime.fromMicrosecondsSinceEpoch(widget.file.creationTime!),
      ),
      subtitleSection: Future.value([
        Text(
          getTimeIn12hrFormat(dateTime) + "  " + dateTime.timeZoneName,
          style: getEnteTextTheme(context).smallMuted,
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

  void _showDateTimePicker(File file) async {
    final dateResult = await DatePicker.showDatePicker(
      context,
      minTime: DateTime(1800, 1, 1),
      maxTime: DateTime.now(),
      currentTime: DateTime.fromMicrosecondsSinceEpoch(file.creationTime!),
      locale: LocaleType.en,
      theme: Theme.of(context).colorScheme.dateTimePickertheme,
    );
    if (dateResult == null) {
      return;
    }
    final dateWithTimeResult = await DatePicker.showTime12hPicker(
      context,
      showTitleActions: true,
      currentTime: dateResult,
      locale: LocaleType.en,
      theme: Theme.of(context).colorScheme.dateTimePickertheme,
    );
    if (dateWithTimeResult != null) {
      if (await editTime(
        context,
        List.of([widget.file]),
        dateWithTimeResult.microsecondsSinceEpoch,
      )) {
        widget.file.creationTime = dateWithTimeResult.microsecondsSinceEpoch;
        setState(() {});
      }
    }
  }
}
