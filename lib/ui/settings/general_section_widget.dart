import 'package:flutter/material.dart';
import 'package:photos/services/billing_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/advanced_settings_screen.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import "package:photos/ui/growth/referral_screen.dart";
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/utils/navigation_util.dart';

class GeneralSectionWidget extends StatelessWidget {
  const GeneralSectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: "General",
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.graphic_eq,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Family plans",
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
          captionedTextWidget: const CaptionedTextWidget(
            title: "Referrals",
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            routeToPage(
              context,
              const ReferralScreen(),
              forceCustomPageRoute: true,
            );
          },
        ),
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Advanced",
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
    BillingService.instance.launchFamilyPortal(context, userDetails);
  }

  void _onAdvancedTapped(BuildContext context) {
    routeToPage(
      context,
      const AdvancedSettingsScreen(),
    );
  }
}
