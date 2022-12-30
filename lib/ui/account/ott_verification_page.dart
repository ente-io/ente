

import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common/dynamic_fab.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class OTTVerificationPage extends StatefulWidget {
  final String email;
  final bool isChangeEmail;
  final bool isCreateAccountScreen;

  const OTTVerificationPage(
    this.email, {
    this.isChangeEmail = false,
    this.isCreateAccountScreen = false,
    Key? key,
  }) : super(key: key);

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
        isKeypadOpen: isKeypadOpen,
        isFormValid: !(_verificationCodeController.text == null ||
            _verificationCodeController.text.isEmpty),
        buttonText: 'Verify',
        onPressedFunction: () {
          if (widget.isChangeEmail) {
            UserService.instance.changeEmail(
              context,
              widget.email,
              _verificationCodeController.text,
            );
          } else {
            UserService.instance
                .verifyEmail(context, _verificationCodeController.text);
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
                'Verify email',
                style: Theme.of(context).textTheme.headline4,
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
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(fontSize: 14),
                              children: [
                                const TextSpan(text: "We've sent a mail to "),
                                TextSpan(
                                  text: widget.email,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .greenAlternative,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Text(
                          'Please check your inbox (and spam) to complete verification',
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: 1,
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: TextFormField(
                style: Theme.of(context).textTheme.subtitle1,
                decoration: InputDecoration(
                  filled: true,
                  hintText: 'Tap to enter code',
                  contentPadding: const EdgeInsets.all(15),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(6),
                  ),
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
                      );
                    },
                    child: Text(
                      "Resend email",
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  )
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
