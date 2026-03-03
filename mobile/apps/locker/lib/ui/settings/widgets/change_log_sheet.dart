import "package:ente_ui/components/base_bottom_sheet.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/ui/components/gradient_button.dart";
import "package:locker/ui/settings/widgets/change_log_strings.dart";

class _ChangeLogEntry {
  final String title;
  final String description;

  const _ChangeLogEntry(this.title, this.description);
}

Future<void> showChangeLogSheet(BuildContext context) {
  final strings = ChangeLogStrings.forLocale(Localizations.localeOf(context));
  return showBaseBottomSheet<void>(
    context,
    title: strings.sheetTitle,
    showCloseButton: true,
    headerSpacing: 20,
    child: _ChangeLogSheetBody(strings: strings),
  );
}

class _ChangeLogSheetBody extends StatelessWidget {
  final ChangeLogStrings strings;

  const _ChangeLogSheetBody({required this.strings});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;
    final entries = <_ChangeLogEntry>[
      _ChangeLogEntry(strings.title1, strings.desc1),
      _ChangeLogEntry(strings.title2, strings.desc2),
      _ChangeLogEntry(strings.title3, strings.desc3),
    ]
        .where(
          (entry) =>
              entry.title.trim().isNotEmpty ||
              entry.description.trim().isNotEmpty,
        )
        .toList(growable: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.sheetSubtitle,
          style: textTheme.body.copyWith(color: colorScheme.textMuted),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _ChangeLogEntryTile(entry: entry);
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: entries.length,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: strings.continueLabel,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _ChangeLogEntryTile extends StatelessWidget {
  final _ChangeLogEntry entry;

  const _ChangeLogEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.fillFaint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title,
            style: textTheme.bodyBold.copyWith(color: colorScheme.textBase),
          ),
          const SizedBox(height: 6),
          Text(
            entry.description,
            style: textTheme.small.copyWith(color: colorScheme.textMuted),
          ),
        ],
      ),
    );
  }
}
