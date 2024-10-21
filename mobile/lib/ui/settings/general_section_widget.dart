import "dart:async";

import 'package:flutter/material.dart';
import "package:photos/app.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/expandable_menu_item_widget.dart";
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import "package:photos/ui/growth/referral_screen.dart";
import 'package:photos/ui/settings/advanced_settings_screen.dart';
import 'package:photos/ui/settings/common_settings.dart';
import "package:photos/ui/settings/language_picker.dart";
import "package:photos/ui/settings/notification_settings_screen.dart";
import 'package:photos/utils/navigation_util.dart';

class GeneralSectionWidget extends StatelessWidget {
  const GeneralSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: S.of(context).general,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.graphic_eq,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).referrals,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            // ignore: unawaited_futures
            routeToPage(
              context,
              const ReferralScreen(),
              forceCustomPageRoute: true,
            );
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).familyPlans,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          showOnlyLoadingState: true,
          onTap: () async {
            await _onFamilyPlansTapped(context);
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget:
              CaptionedTextWidget(title: S.of(context).language),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            final locale = await getLocale();
            await routeToPage(
              context,
              LanguageSelectorPage(
                appSupportedLocales,
                (locale) async {
                  await setLocale(locale);
                  EnteApp.setLocale(context, locale);
                  unawaited(S.load(locale));
                },
                locale,
              ),
            );
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).notifications,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            _onNotificationsTapped(context);
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).advanced,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            _onAdvancedTapped(context);
          },
        ),
        sectionOptionSpacing,
      ],
    );
  }

  Future<void> _onFamilyPlansTapped(BuildContext context) async {
    final userDetails =
        await UserService.instance.getUserDetailsV2(memoryCount: false);
    // ignore: unawaited_futures
    billingService.launchFamilyPortal(context, userDetails);
  }

  void _onNotificationsTapped(BuildContext context) {
    routeToPage(
      context,
      const NotificationSettingsScreen(),
    );
  }

  void _onAdvancedTapped(BuildContext context) {
    routeToPage(
      context,
      const AdvancedSettingsScreen(),
    );
  }
}
