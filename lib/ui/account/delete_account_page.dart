import 'package:flutter/material.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher.dart';

class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Delete account"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/family_plan_leave.png",
                height: 256,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              Center(
                child: Text(
                  "We'll be sorry to see you go. Are you facing some issue?",
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              RichText(
                // textAlign: TextAlign.center,
                text: TextSpan(
                  children: const [
                    TextSpan(text: "Please write to us at "),
                    TextSpan(
                      text: "feedback@ente.io",
                      style: TextStyle(color: Color.fromRGBO(29, 185, 84, 1)),
                    ),
                    TextSpan(
                      text: ", maybe there is a way we can help.",
                    ),
                  ],
                  style: Theme.of(context).textTheme.subtitle2,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              GradientButton(
                text: "Yes, send feedback",
                paddingValue: 4,
                iconData: Icons.check,
                onTap: () async {
                  await launchUrl(
                    Uri(
                      scheme: "mailto",
                      path: 'feedback@ente.io',
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
              ),
              InkWell(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(
                        color: Colors.redAccent,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 10,
                      ),
                      backgroundColor: Colors.white,
                    ),
                    label: const Text(
                      "No, delete account",
                      style: TextStyle(
                        color: Colors.redAccent, // same for both themes
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () async => {await _confirmDelete(context)},
                    icon: const Icon(
                      Icons.no_accounts,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final choice = await showChoiceDialog(
      context,
      'Are you sure you want to delete your account?',
      'Your uploaded data will be scheduled for deletion, and your account '
          'will be permanently deleted. \n This action is not reversible.',
      firstAction: 'Cancel',
      secondAction: 'Delete',
      firstActionColor: Theme.of(context).buttonColor,
      secondActionColor: Theme.of(context).colorScheme.onSurface,
    );
    if (choice != DialogUserChoice.secondChoice) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop('dialog');
    showToast(context, "here we call delete");
    // await UserService.instance.delete(context);
  }
}
