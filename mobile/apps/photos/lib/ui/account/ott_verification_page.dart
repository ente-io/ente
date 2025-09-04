import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/common/dynamic_fab.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import "package:styled_text/styled_text.dart";

class OTTVerificationPage extends StatefulWidget {
  final String email;
  final bool isChangeEmail;
  final bool isCreateAccountScreen;
  final bool isResetPasswordScreen;

  const OTTVerificationPage(
    this.email, {
    this.isChangeEmail = false,
    this.isCreateAccountScreen = false,
    this.isResetPasswordScreen = false,
    super.key,
  });

  @override
  State<OTTVerificationPage> createState() => _OTTVerificationPageState();
}

class _OTTVerificationPageState extends State<OTTVerificationPage> {
  final _verificationCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;

    FloatingActionButtonLocation? fabLocation() {
      if (isKeypadOpen) {
        return null;
      } else {
        return FloatingActionButtonLocation.centerFloat;
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: widget.isCreateAccountScreen
            ? Material(
                type: MaterialType.transparency,
                child: StepProgressIndicator(
                  totalSteps: 4,
                  currentStep: 2,
                  selectedColor: Theme.of(context).colorScheme.greenAlternative,
                  roundedEdges: const Radius.circular(10),
                  unselectedColor:
                      Theme.of(context).colorScheme.stepProgressUnselectedColor,
                ),
              )
            : null,
      ),
      body: _getBody(),
      floatingActionButton: DynamicFAB(
        key: const ValueKey("verifyOttButton"),
        isKeypadOpen: isKeypadOpen,
        isFormValid: _verificationCodeController.text.isNotEmpty,
        buttonText: AppLocalizations.of(context).verify,
        onPressedFunction: () {
          if (widget.isChangeEmail) {
            UserService.instance.changeEmail(
              context,
              widget.email,
              _verificationCodeController.text,
            );
          } else {
            UserService.instance.verifyEmail(
              context,
              _verificationCodeController.text,
              isResettingPasswordScreen: widget.isResetPasswordScreen,
            );
          }
          FocusScope.of(context).unfocus();
        },
      ),
      floatingActionButtonLocation: fabLocation(),
      floatingActionButtonAnimator: NoScalingAnimation(),
    );
  }

  Widget _getBody() {
    return ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
              child: Text(
                AppLocalizations.of(context).verifyEmail,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                          child: StyledText(
                            text: AppLocalizations.of(context)
                                .weHaveSendEmailTo(email: widget.email),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(fontSize: 14),
                            tags: {
                              'green': StyledTextTag(
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .greenAlternative,
                                ),
                              ),
                            },
                          ),
                        ),
                        widget.isResetPasswordScreen
                            ? Text(
                                AppLocalizations.of(context).toResetVerifyEmail,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontSize: 14),
                              )
                            : Text(
                                AppLocalizations.of(context)
                                    .checkInboxAndSpamFolder,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontSize: 14),
                              ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: 1,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: TextFormField(
                key: const ValueKey("ottVerificationInputField"),
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  filled: true,
                  hintText: AppLocalizations.of(context).tapToEnterCode,
                  contentPadding: const EdgeInsets.all(15),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  fillColor: getEnteColorScheme(context).fillFaint,
                ),
                controller: _verificationCodeController,
                autofocus: false,
                autocorrect: false,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
            Divider(
              thickness: 1,
              color: getEnteColorScheme(context).strokeFaint,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      UserService.instance.sendOtt(
                        context,
                        widget.email,
                        isCreateAccountScreen: widget.isCreateAccountScreen,
                        isResetPasswordScreen: widget.isResetPasswordScreen,
                        isChangeEmail: widget.isChangeEmail,
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context).resendEmail,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    // );
  }
}
