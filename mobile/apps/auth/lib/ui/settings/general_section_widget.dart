import 'dart:io';

import 'package:ente_auth/app/view/app.dart';
import 'package:ente_auth/events/icons_changed_event.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/locale.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/captioned_text_widget.dart';
import 'package:ente_auth/ui/components/expandable_menu_item_widget.dart';
import 'package:ente_auth/ui/components/menu_item_widget.dart';
import 'package:ente_auth/ui/components/toggle_switch_widget.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/ui/settings/language_picker.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_events/event_bus.dart';
import 'package:ente_logging/logging.dart';
import 'package:flutter/material.dart';

class AdvancedSectionWidget extends StatefulWidget {
  const AdvancedSectionWidget({super.key});

  @override
  State<AdvancedSectionWidget> createState() => _AdvancedSectionWidgetState();
}

class _AdvancedSectionWidgetState extends State<AdvancedSectionWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpandableMenuItemWidget(
      title: l10n.general,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.graphic_eq,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.language,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            final locale = (await getLocale())!;
            // ignore: unawaited_futures
            routeToPage(
              context,
              LanguageSelectorPage(
                appSupportedLocales,
                (locale) async {
                  await setLocale(locale);
                  App.setLocale(context, locale);
                },
                locale,
              ),
            );
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.showLargeIcons,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => PreferenceService.instance.shouldShowLargeIcons(),
            onChanged: () async {
              await PreferenceService.instance.setShowLargeIcons(
                !PreferenceService.instance.shouldShowLargeIcons(),
              );
              setState(() {});
            },
          ),
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.compactMode,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => PreferenceService.instance.isCompactMode(),
            onChanged: () async {
              await PreferenceService.instance.setCompactMode(
                !PreferenceService.instance.isCompactMode(),
              );
              Bus.instance.fire(IconsChangedEvent());
              setState(() {});
            },
          ),
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.shouldHideCode,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => PreferenceService.instance.shouldHideCodes(),
            onChanged: () async {
              await PreferenceService.instance.setHideCodes(
                !PreferenceService.instance.shouldHideCodes(),
              );
              if (PreferenceService.instance.shouldHideCodes()) {
                showToast(context, context.l10n.doubleTapToViewHiddenCode);
              }
              setState(() {});
            },
          ),
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.focusOnSearchBar,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () =>
                PreferenceService.instance.shouldAutoFocusOnSearchBar(),
            onChanged: () async {
              await PreferenceService.instance.setAutoFocusOnSearchBar(
                !PreferenceService.instance.shouldAutoFocusOnSearchBar(),
              );
              setState(() {});
            },
          ),
        ),
        sectionOptionSpacing,
        if (Platform.isAndroid) ...[
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: l10n.minimizeAppOnCopy,
            ),
            trailingWidget: ToggleSwitchWidget(
              value: () => PreferenceService.instance.shouldMinimizeOnCopy(),
              onChanged: () async {
                await PreferenceService.instance.setShouldMinimizeOnCopy(
                  !PreferenceService.instance.shouldMinimizeOnCopy(),
                );
                setState(() {});
              },
            ),
          ),
          sectionOptionSpacing,
        ],
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: l10n.crashAndErrorReporting,
          ),
          trailingWidget: ToggleSwitchWidget(
            value: () => SuperLogging.shouldReportErrors(),
            onChanged: () async {
              await SuperLogging.setShouldReportErrors(
                !SuperLogging.shouldReportErrors(),
              );
              setState(() {});
            },
          ),
        ),
        sectionOptionSpacing,
      ],
    );
  }
}
