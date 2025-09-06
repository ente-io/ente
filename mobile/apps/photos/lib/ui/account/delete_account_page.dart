import "dart:async";
import 'dart:convert';

import "package:dropdown_button2/dropdown_button2.dart";
import 'package:ente_crypto/ente_crypto.dart';
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/api/user/delete_account.dart';
import 'package:photos/services/account/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/ui/notification/toast.dart";
import 'package:photos/utils/dialog_util.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({
    super.key,
  });

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _hasConfirmedDeletion = false;
  final _feedbackTextCtrl = TextEditingController();
  late String _defaultSelection = AppLocalizations.of(context).selectReason;
  String? _dropdownValue;
  late final List<String> _deletionReason = [
    _defaultSelection,
    AppLocalizations.of(context).deleteReason1,
    AppLocalizations.of(context).deleteReason2,
    AppLocalizations.of(context).deleteReason3,
    AppLocalizations.of(context).deleteReason4,
  ];

  @override
  Widget build(BuildContext context) {
    _defaultSelection = AppLocalizations.of(context).selectReason;
    _dropdownValue ??= _defaultSelection;
    final double dropDownTextSize = MediaQuery.of(context).size.width - 120;

    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocalizations.of(context).deleteAccount),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  AppLocalizations.of(context).askDeleteReason,
                  style: getEnteTextTheme(context).body,
                ),
              ),
              const SizedBox(height: 8),
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
                      child: SizedBox(
                        width: dropDownTextSize,
                        child: Text(
                          value,
                          style: getEnteTextTheme(context).smallMuted,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  AppLocalizations.of(context).deleteAccountFeedbackPrompt,
                  style: getEnteTextTheme(context).body,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                style: getEnteTextTheme(context).smallMuted,
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
                  hintText: AppLocalizations.of(context).feedback,
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
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: 4.0,
                        right: 8,
                        left: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppLocalizations.of(context)
                              .kindlyHelpUsWithThisInformation,
                          style: getEnteTextTheme(context)
                              .smallBold
                              .copyWith(color: colorScheme.warning700),
                        ),
                      ),
                    )
                  : const SizedBox(height: 21),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasConfirmedDeletion = !_hasConfirmedDeletion;
                  });
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          AppLocalizations.of(context).confirmDeletePrompt,
                          style: getEnteTextTheme(context).bodyMuted,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ButtonWidget(
                      buttonType: ButtonType.critical,
                      labelText:
                          AppLocalizations.of(context).confirmAccountDeletion,
                      isDisabled: _shouldBlockDeletion(),
                      onTap: () async {
                        await _initiateDelete(context);
                      },
                      shouldSurfaceExecutionStates: true,
                    ),
                    const SizedBox(height: 8),
                    ButtonWidget(
                      buttonType: ButtonType.secondary,
                      labelText: AppLocalizations.of(context).cancel,
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
      title: AppLocalizations.of(context).confirmAccountDeletion,
      body: AppLocalizations.of(context).deleteConfirmDialogBody,
      firstButtonLabel:
          AppLocalizations.of(context).deleteAccountPermanentlyButton,
      firstButtonType: ButtonType.critical,
      firstButtonOnTap: () async {
        final deleteChallengeResponse =
            await UserService.instance.getDeleteChallenge(context);
        if (deleteChallengeResponse == null) {
          return;
        }
        if (deleteChallengeResponse.allowDelete) {
          await _delete(context, deleteChallengeResponse);
        }
      },
      isDismissible: false,
    );
    if (choice!.action == ButtonAction.error) {
      await showGenericErrorDialog(context: context, error: choice.exception);
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
        reasonCategory: _dropdownValue!,
        feedback: _feedbackTextCtrl.text.trim(),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
      showShortToast(
        context,
        AppLocalizations.of(context).yourAccountHasBeenDeleted,
      );
    } catch (e, s) {
      Logger("DeleteAccount").severe("failed to delete", e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }
}
