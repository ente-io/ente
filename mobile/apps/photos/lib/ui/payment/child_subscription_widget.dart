import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/user_details.dart';
import 'package:photos/services/family_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/components/buttons/button_widget_v2.dart';
import 'package:photos/ui/family/family_ui.dart';
import 'package:photos/utils/dialog_util.dart';

class ChildSubscriptionWidget extends StatelessWidget {
  const ChildSubscriptionWidget({
    super.key,
    required this.userDetails,
    required this.onLeaveFamily,
  });

  final UserDetails userDetails;
  final Future<void> Function(UserDetails updatedUserDetails) onLeaveFamily;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final String familyAdmin = userDetails.familyData!.members!
        .firstWhere((element) => element.isAdmin)
        .email;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).subscription,
            style: textTheme.h3Bold.copyWith(
              color: colorScheme.content,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).youAreOnAFamilyPlanSubtitle,
            style: textTheme.small.copyWith(
              color: colorScheme.contentLight,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: familyAdmin,
                  style: textTheme.small.copyWith(
                    color: colorScheme.greenBase,
                  ),
                ),
                TextSpan(
                  text:
                      AppLocalizations.of(context).familyAdminManagesPlanSuffix,
                  style: textTheme.small.copyWith(
                    color: colorScheme.contentLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              "assets/family_plan_leave.png",
              width: 182,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          ButtonWidgetV2(
            buttonType: ButtonTypeV2.critical,
            labelText: AppLocalizations.of(context).leaveFamilyPlan,
            onTap: () async => _leaveFamilyPlan(context),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text.rich(
              textAlign: TextAlign.center,
              TextSpan(
                children: [
                  TextSpan(
                    text: AppLocalizations.of(context).needHelpContact,
                    style: textTheme.small.copyWith(
                      color: colorScheme.contentLight,
                    ),
                  ),
                  TextSpan(
                    text: supportEmail,
                    style: textTheme.small.copyWith(
                      color: colorScheme.greenBase,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveFamilyPlan(BuildContext context) async {
    final confirmed = await showFamilyConfirmationSheet(
      context,
      title: AppLocalizations.of(context).leaveFamily,
      body: AppLocalizations.of(context).areYouSureThatYouWantToLeaveTheFamily,
      actionLabel: AppLocalizations.of(context).leave,
    );
    if (!confirmed) {
      return;
    }

    try {
      final updatedUserDetails = await FamilyService.instance.leaveFamily();
      await onLeaveFamily(updatedUserDetails);
    } catch (error, stackTrace) {
      Logger("ChildSubscriptionWidget")
          .severe("failed to leave family", error, stackTrace);
      if (!context.mounted) {
        return;
      }
      await showGenericErrorDialog(context: context, error: error);
    }
  }
}
