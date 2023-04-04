import 'dart:convert';

import "package:dropdown_button2/dropdown_button2.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/models/delete_account.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';
import "package:photos/utils/toast_util.dart";

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({
    Key? key,
  }) : super(key: key);

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _hasConfirmedDeletion = false;
  final _feedbackTextCtrl = TextEditingController();
  final String _defaultSelection = 'Select reason';
  late String _dropdownValue = _defaultSelection;
  late final List<String> _deletionReason = [
    _defaultSelection,
    'It’s missing a key feature that I need',
    'The app or a certain feature does not \nbehave as I think it should',
    'I found another service that I like better',
    'My reason isn’t listed',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                "What is the main reason you are deleting your account?",
                style: getEnteTextTheme(context).body,
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.fillFaint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton2<String>(
                  alignment: AlignmentDirectional.topStart,
                  value: _dropdownValue,
                  onChanged: (String? newValue) {
                    setState(() {
                      _dropdownValue = newValue!;
                    });
                  },
                  underline: const SizedBox(),
                  items: _deletionReason
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      enabled: value != _defaultSelection,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: value != _defaultSelection
                            ? getEnteTextTheme(context).small
                            : getEnteTextTheme(context).smallMuted,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "We are sorry to see you go. Please share your feedback to "
                "help us improve.",
                style: getEnteTextTheme(context).body,
              ),
              const SizedBox(height: 4),
              TextFormField(
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: colorScheme.strokeFaint, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: colorScheme.strokeFaint, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  hintText: "Feedback",
                  contentPadding: const EdgeInsets.all(12),
                ),
                controller: _feedbackTextCtrl,
                autofocus: false,
                autocorrect: false,
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: null,
                onChanged: (_) {
                  setState(() {});
                },
              ),
              _shouldAskForFeedback()
                  ? SizedBox(
                      height: 42,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Kindly help us with this information",
                          style: getEnteTextTheme(context)
                              .smallBold
                              .copyWith(color: colorScheme.warning700),
                        ),
                      ),
                    )
                  : const SizedBox(height: 42),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasConfirmedDeletion = !_hasConfirmedDeletion;
                  });
                },
                child: Row(
                  children: [
                    Checkbox(
                      value: _hasConfirmedDeletion,
                      side: CheckboxTheme.of(context).side,
                      onChanged: (value) {
                        setState(() {
                          _hasConfirmedDeletion = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        "Yes, I want to permanently delete this account and "
                        "all its data.",
                        style: getEnteTextTheme(context).bodyMuted,
                        textAlign: TextAlign.left,
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ButtonWidget(
                      buttonType: ButtonType.critical,
                      labelText: "Confirm Account Deletion",
                      isDisabled: _shouldBlockDeletion(),
                      onTap: () async {
                        await _initiateDelete(context);
                      },
                      shouldSurfaceExecutionStates: true,
                    ),
                    const SizedBox(height: 8),
                    ButtonWidget(
                      buttonType: ButtonType.secondary,
                      labelText: "Cancel",
                      onTap: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                    const SafeArea(
                      child: SizedBox(
                        height: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldBlockDeletion() {
    return !_hasConfirmedDeletion ||
        _dropdownValue == _defaultSelection ||
        _shouldAskForFeedback();
  }

  bool _shouldAskForFeedback() {
    return _feedbackTextCtrl.text.trim().isEmpty;
  }

  Future<void> _initiateDelete(BuildContext context) async {
    final choice = await showChoiceDialog(
      context,
      title: "Confirm Account Deletion",
      body: "You are about to permanently delete your account and all its data."
          "\nThis action is irreversible.",
      firstButtonLabel: "Delete Account Permanently",
      firstButtonType: ButtonType.critical,
      firstButtonOnTap: () async {
        final deleteChallengeResponse =
            await UserService.instance.getDeleteChallenge(context);
        if (deleteChallengeResponse == null) {
          return;
        }
        if (deleteChallengeResponse.allowDelete) {
          await _delete(context, deleteChallengeResponse);
        } else {
          await _requestEmailForDeletion(context);
        }
      },
      isDismissible: false,
    );
    if (choice!.action == ButtonAction.error) {
      await showGenericErrorDialog(context: context);
    }
  }

  Future<void> _delete(
    BuildContext context,
    DeleteChallengeResponse response,
  ) async {
    try {
      final decryptChallenge = CryptoUtil.openSealSync(
        CryptoUtil.base642bin(response.encryptedChallenge),
        CryptoUtil.base642bin(
          Configuration.instance.getKeyAttributes()!.publicKey,
        ),
        Configuration.instance.getSecretKey()!,
      );
      final challengeResponseStr = utf8.decode(decryptChallenge);
      await UserService.instance.deleteAccount(
        context,
        challengeResponseStr,
        reasonCategory: _dropdownValue,
        feedback: _feedbackTextCtrl.text.trim(),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
      showShortToast(context, "Your account has been deleted");
    } catch (e, s) {
      Logger("DeleteAccount").severe("failed to delete", e, s);
      showGenericErrorDialog(context: context);
    }
  }

  Future<void> _requestEmailForDeletion(BuildContext context) async {
    final AlertDialog alert = AlertDialog(
      title: const Text(
        "Delete account",
        style: TextStyle(
          color: Colors.red,
        ),
      ),
      content: RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: "Please send an email to ",
            ),
            TextSpan(
              text: "account-deletion@ente.io",
              style: TextStyle(
                color: Colors.orange[300],
              ),
            ),
            const TextSpan(
              text:
                  " from your registered email address.\n\nYour request will be processed within 72 hours.",
            ),
          ],
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.5,
            fontSize: 16,
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text(
            "Send email",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            await sendEmail(
              context,
              to: 'account-deletion@ente.io',
              subject: '[Delete account]',
            );
          },
        ),
        TextButton(
          child: Text(
            "Ok",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
