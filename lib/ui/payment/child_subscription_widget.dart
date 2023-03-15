import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/utils/dialog_util.dart';

class ChildSubscriptionWidget extends StatelessWidget {
  const ChildSubscriptionWidget({
    Key? key,
    required this.userDetails,
  }) : super(key: key);

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
              "You are on a family plan!",
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
              child: const Text(
                "Leave Family",
                style: TextStyle(
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
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(
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
    final choice = await showChoiceDialog(
      context,
      title: "Leave family",
      body: "Are you sure that you want to leave the family plan?",
      firstButtonLabel: "Leave",
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
      await showGenericErrorDialog(context: context);
    }
  }
}
