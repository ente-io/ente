import "package:ente_utils/navigation_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/app.dart";
import "package:locker/core/locale.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/ui/components/expandable_menu_item_widget.dart";
import "package:locker/ui/settings/language_selector_page.dart";

class GeneralSectionWidget extends StatelessWidget {
  const GeneralSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.general,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: HugeIcons.strokeRoundedSettings01,
    );
  }

  Column _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        ExpandableChildItem(
          title: l10n.language,
          trailingIcon: Icons.chevron_right,
          onTap: () async {
            final locale = await getLocale();
            // ignore: unawaited_futures
            routeToPage(
              context,
              LanguageSelectorPage(
                appSupportedLocales,
                (newLocale) async {
                  await setLocale(newLocale);
                  App.setLocale(context, newLocale);
                },
                locale ?? const Locale('en'),
              ),
            );
          },
        ),
      ],
    );
  }
}
