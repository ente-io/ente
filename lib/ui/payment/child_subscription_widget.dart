import 'package:flutter/material.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/common_elements.dart';
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "only your family plan admin ($familyAdmin) can change the plan.",
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        button(
          "leave family",
          onPressed: () async {
            await _leaveFamilyPlan(context);
          },
          fontSize: 18,
        ),
      ],
    );
  }

  Future<void> _leaveFamilyPlan(BuildContext context) async {
    final choice = await showChoiceDialog(
      context,
      'leave family',
      'are you sure that you want to leave the family plan?',
      firstAction: 'no',
      secondAction: 'yes',
      firstActionColor: Theme.of(context).buttonColor,
      secondActionColor: Colors.white,
    );
    if (choice != DialogUserChoice.secondChoice) {
      return;
    }
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    try {
      await UserService.instance.leaveFamilyPlan();
      dialog.hide();
    } catch (e) {
      dialog.hide();
      showGenericErrorDialog(context);
    }
  }
}
