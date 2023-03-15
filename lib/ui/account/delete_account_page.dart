import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/delete_account.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';

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
  final _focusNode = FocusNode();
  final String _defaultSelection = 'Select reason';
  late String dropdownValue = _defaultSelection;
  late List<String> deletionReason = [
    _defaultSelection,
    'It’s missing a key feature that I need',
    'I found another service that I like better',
    'I use a different account',
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
                padding: const EdgeInsets.only(left: 16, right: 6),
                decoration: BoxDecoration(
                  color: colorScheme.fillFaint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  alignment: AlignmentDirectional.topStart,
                  value: dropdownValue,
                  icon: Icon(
                    Icons.expand_more_outlined,
                    color: colorScheme.strokeMuted,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      dropdownValue = newValue!;
                    });
                  },
                  underline: const SizedBox(),
                  items: deletionReason
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
                "We are sorry to see you go. Please explain why you are "
                "leaving to help us improve.",
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
                focusNode: _focusNode,
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: null,
                onChanged: (_) {
                  setState(() {});
                },
              ),
              (_focusNode.hasFocus || _hasConfirmedDeletion) &&
                      _feedbackTextCtrl.text.trim().length < 10
                  ? SizedBox(
                      height: 42,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "This field requires a minimum of 10 "
                          "characters",
                          style: getEnteTextTheme(context)
                              .smallBold
                              .copyWith(color: colorScheme.warning700),
                        ),
                      ),
                    )
                  : const SizedBox(height: 42),
              Row(
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
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ButtonWidget(
                      buttonType: ButtonType.critical,
                      labelText: "Confirm Account Deletion",
                      isDisabled: !_hasConfirmedDeletion ||
                          _defaultSelection == dropdownValue ||
                          _feedbackTextCtrl.text.trim().length < 10,
                      onTap: () async => {await _initiateDelete(context)},
                      shouldSurfaceExecutionStates: false,
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

  Future<void> _initiateDelete(BuildContext context) async {
    final deleteChallengeResponse =
        await UserService.instance.getDeleteChallenge(context);
    if (deleteChallengeResponse == null) {
      return;
    }
    if (deleteChallengeResponse.allowDelete) {
      await _confirmAndDelete(context, deleteChallengeResponse);
    } else {
      await _requestEmailForDeletion(context);
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    DeleteChallengeResponse response,
  ) async {
    final choice = await showChoiceDialog(
      context,
      title: 'Are you sure you want to delete your account?',
      body:
          'Your uploaded data will be scheduled for deletion, and your account'
          ' will be permanently deleted. \n\nThis action is not reversible.',
      firstButtonLabel: "Delete my account",
      isCritical: true,
      firstButtonOnTap: () async {
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
          reasonCategory: dropdownValue,
          feedback: _feedbackTextCtrl.text.trim(),
        );
      },
    );
    if (choice!.action == ButtonAction.error) {
      showGenericErrorDialog(context: context);
    }
    if (choice.action != ButtonAction.first) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
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
