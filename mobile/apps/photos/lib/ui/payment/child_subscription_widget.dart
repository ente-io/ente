import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/user_details.dart';
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/buttons/button_widget_v2.dart';
import 'package:photos/utils/dialog_util.dart';

class ChildSubscriptionWidget extends StatelessWidget {
  const ChildSubscriptionWidget({
    super.key,
    required this.userDetails,
  });

  final UserDetails userDetails;

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
    final choice = await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).leaveFamily,
      body: AppLocalizations.of(context).areYouSureThatYouWantToLeaveTheFamily,
      firstButtonLabel: AppLocalizations.of(context).leave,
      firstButtonOnTap: () async {
        try {
          await UserService.instance.leaveFamilyPlan();
        } catch (e) {
          Logger("ChildSubscriptionWidget").severe("failed to leave family");
          rethrow;
        }
      },
    );
    if (choice == null) {
      return;
    }
    if (choice.action == ButtonAction.error) {
      await showGenericErrorDialog(context: context, error: choice.exception);
    }
  }
}
