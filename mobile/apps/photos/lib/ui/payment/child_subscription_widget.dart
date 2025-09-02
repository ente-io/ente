import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/user_details.dart';
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import "package:styled_text/styled_text.dart";

class ChildSubscriptionWidget extends StatelessWidget {
  const ChildSubscriptionWidget({
    super.key,
    required this.userDetails,
  });

  final UserDetails userDetails;

  @override
  Widget build(BuildContext context) {
    final String familyAdmin = userDetails.familyData!.members!
        .firstWhere((element) => element.isAdmin)
        .email;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              AppLocalizations.of(context).youAreOnAFamilyPlan,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StyledText(
              text: AppLocalizations.of(context)
                  .contactFamilyAdmin(familyAdminEmail: familyAdmin),
              style: Theme.of(context).textTheme.bodyLarge,
              tags: {
                'green': StyledTextTag(
                  style: TextStyle(
                    color: getEnteColorScheme(context).primary500,
                  ),
                ),
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
          Image.asset(
            "assets/family_plan_leave.png",
            height: 256,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 0),
          ),
          InkWell(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 100),
                backgroundColor: Colors.red[500],
              ),
              child: Text(
                AppLocalizations.of(context).leaveFamily,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white, // same for both themes
                ),
                textAlign: TextAlign.center,
              ),
              onPressed: () async => {await _leaveFamilyPlan(context)},
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: AppLocalizations.of(context)
                            .pleaseContactSupportAndWeWillBeHappyToHelp,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
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
    if (choice!.action == ButtonAction.error) {
      await showGenericErrorDialog(context: context, error: choice.exception);
    }
  }
}
