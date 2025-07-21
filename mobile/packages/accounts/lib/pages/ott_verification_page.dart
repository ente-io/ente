import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:ente_ui/components/buttons/dynamic_fab.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:styled_text/styled_text.dart';

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

  Future<void> onPressed() async {
    if (widget.isChangeEmail) {
      await UserService.instance.changeEmail(
        context,
        widget.email,
        _verificationCodeController.text,
      );
    } else {
      await UserService.instance.verifyEmail(
        context,
        _verificationCodeController.text,
        isResettingPasswordScreen: widget.isResetPasswordScreen,
      );
    }
    FocusScope.of(context).unfocus();
  }

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
                  selectedColor: getEnteColorScheme(context).alternativeColor,
                  roundedEdges: const Radius.circular(10),
                  unselectedColor:
                      getEnteColorScheme(context).stepProgressUnselectedColor,
                ),
              )
            : null,
      ),
      body: _getBody(),
      floatingActionButton: DynamicFAB(
        isKeypadOpen: isKeypadOpen,
        isFormValid: _verificationCodeController.text.isNotEmpty,
        buttonText: context.strings.verify,
        onPressedFunction: onPressed,
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
                context.strings.verifyEmail,
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
                            text:
                                context.strings.weHaveSendEmailTo(widget.email),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(fontSize: 14),
                            tags: {
                              'green': StyledTextTag(
                                style: TextStyle(
                                  color: getEnteColorScheme(context)
                                      .alternativeColor,
                                ),
                              ),
                            },
                          ),
                        ),
                        widget.isResetPasswordScreen
                            ? Text(
                                context.strings.toResetVerifyEmail,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontSize: 14),
                              )
                            : Text(
                                context.strings.checkInboxAndSpamFolder,
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
                style: Theme.of(context).textTheme.titleMedium,
                onFieldSubmitted: _verificationCodeController.text.isNotEmpty
                    ? (_) => onPressed()
                    : null,
                decoration: InputDecoration(
                  filled: true,
                  hintText: context.strings.tapToEnterCode,
                  contentPadding: const EdgeInsets.all(15),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                controller: _verificationCodeController,
                autofocus: true,
                autocorrect: false,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
            const Divider(
              thickness: 1,
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
                        isChangeEmail: widget.isChangeEmail,
                        isResetPasswordScreen: widget.isResetPasswordScreen,
                      );
                    },
                    child: Text(
                      context.strings.resendEmail,
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
