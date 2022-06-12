import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/utils/dialog_util.dart';

class ChildSubscriptionWidget extends StatelessWidget {
  const ChildSubscriptionWidget({
    Key key,
    @required this.userDetails,
  }) : super(key: key);

  final UserDetails userDetails;

  @override
  Widget build(BuildContext context) {
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
              "You are on a family plan!",
              style:
                  Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Please contact ",
                  ),
                  TextSpan(
                    text: familyAdmin,
                    style: TextStyle(color: Color.fromRGBO(29, 185, 84, 1)),
                  ),
                  TextSpan(
                    text: " to manage your family subscription",
                  ),
                ],
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontSize: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          Image.asset(
            "assets/family sharing.png",
            height: 256,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
          ),
          InkWell(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 100),
                side: BorderSide(
                  width: 2,
                  color: Color.fromRGBO(255, 52, 52, 1),
                ),
              ),
              child: Text(
                "leave family",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color.fromRGBO(255, 52, 52, 1),
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
                  children: const [
                    TextSpan(
                      text: "Please contact ",
                    ),
                    TextSpan(
                      text: "support@ente.io",
                      style: TextStyle(color: Color.fromRGBO(29, 185, 84, 1)),
                    ),
                    TextSpan(
                      text: " for help",
                    ),
                  ],
                  style: Theme.of(context).textTheme.overline,
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
      'Leave family',
      'Are you sure that you want to leave the family plan?',
      firstAction: 'No',
      secondAction: 'Yes',
      firstActionColor: Theme.of(context).buttonColor,
      secondActionColor: Theme.of(context).colorScheme.onSurface,
    );
    if (choice != DialogUserChoice.secondChoice) {
      return;
    }
    final dialog = createProgressDialog(context, "Please wait...");
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
