import "package:flutter/material.dart";
import "package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart";
import "package:intl/intl.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/l10n/l10n.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/utils/date_time_util.dart";
import "package:photos/utils/magic_util.dart";

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
    final dateTime =
        DateTime.fromMicrosecondsSinceEpoch(widget.file.creationTime!);
    return InfoItemWidget(
      key: const ValueKey("Creation time"),
      leadingIcon: Icons.calendar_today_outlined,
      title: DateFormat.yMMMEd(Localizations.localeOf(context).languageCode)
          .format(
        DateTime.fromMicrosecondsSinceEpoch(widget.file.creationTime!),
      ),
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
    final Locale locale = await getLocale();
    final localeType = getFromLocalString(locale);
    final dateResult = await DatePickerBdaya.showDatePicker(
      context,
      minTime: DateTime(1800, 1, 1),
      maxTime: DateTime.now(),
      currentTime: DateTime.fromMicrosecondsSinceEpoch(file.creationTime!),
      locale: localeType,
      theme: Theme.of(context).colorScheme.dateTimePickertheme,
    );
    if (dateResult == null) {
      return;
    }

    late DateTime? dateWithTimeResult;
    if (_showAmPmTimePicker(locale)) {
      dateWithTimeResult = await DatePickerBdaya.showTime12hPicker(
        context,
        showTitleActions: true,
        currentTime: dateResult,
        locale: localeType,
        theme: Theme.of(context).colorScheme.dateTimePickertheme,
      );
    } else {
      dateWithTimeResult = await DatePickerBdaya.showTimePicker(
        context,
        showTitleActions: true,
        currentTime: dateResult,
        locale: localeType,
        theme: Theme.of(context).colorScheme.dateTimePickertheme,
      );
    }
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

  bool _showAmPmTimePicker(Locale locale) {
    return locale.languageCode == "en" ||
        locale.languageCode == "es" ||
        locale.languageCode == "pt";
  }

  LocaleType getFromLocalString(Locale locale) {
    switch (locale.languageCode) {
      case "en":
        return LocaleType.en;
      case "es":
        return LocaleType.es;
      case "de":
        return LocaleType.de;
      case "fr":
        return LocaleType.fr;
      case "it":
        return LocaleType.it;
      case "nl":
        return LocaleType.nl;
      case "pt":
        return LocaleType.pt;
      case "ru":
        return LocaleType.ru;
      case "tr":
        return LocaleType.tr;
      case "zh":
        return LocaleType.zh;
      default:
        return LocaleType.en;
    }
  }
}
