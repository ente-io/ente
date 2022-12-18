// @dart=2.9

import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/user_details.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/ui/common/dialogs.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:flutter/material.dart';

class ChildSubscriptionWidget extends StatelessWidget {
  const ChildSubscriptionWidget({
    Key key,
    @required this.userDetails,
  }) : super(key: key);

  final UserDetails userDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String familyAdmin = userDetails.familyData.members
        .firstWhere((element) => element.isAdmin)
        .email;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              l10n.inFamilyPlanMessage,
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: "Please contact ",
                  ),
                  TextSpan(
                    text: familyAdmin,
                    style:
                        const TextStyle(color: Color.fromRGBO(29, 185, 84, 1)),
                  ),
                  const TextSpan(
                    text: " to manage your subscription",
                  ),
                ],
                style: Theme.of(context).textTheme.bodyText1,
              ),
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
                l10n.leaveFamily,
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
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Please contact ",
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    TextSpan(
                      text: "support@ente.io",
                      style: Theme.of(context).textTheme.bodyText2.copyWith(
                            color: const Color.fromRGBO(29, 185, 84, 1),
                          ),
                    ),
                    TextSpan(
                      text: " for help",
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveFamilyPlan(BuildContext context) async {
    final l10n = context.l10n;
    final choice = await showChoiceDialog(
      context,
      l10n.leaveFamily,
      l10n.leaveFamilyMessage,
      firstAction: l10n.no,
      secondAction: l10n.yes,
      firstActionColor: Theme.of(context).colorScheme.alternativeColor,
      secondActionColor: Theme.of(context).colorScheme.onSurface,
    );
    if (choice != DialogUserChoice.secondChoice) {
      return;
    }
    final dialog = createProgressDialog(context, l10n.pleaseWaitTitle);
    await dialog.show();
    try {
      await UserService.instance.leaveFamilyPlan();
      dialog.hide();
      Navigator.of(context).pop('');
    } catch (e) {
      dialog.hide();
      showGenericErrorDialog(context);
    }
  }
}
