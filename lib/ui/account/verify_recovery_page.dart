import 'dart:ui';

import 'package:bip39/bip39.dart' as bip39;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/notification_event.dart';
import 'package:photos/services/local_authentication_service.dart';
import 'package:photos/services/user_remote_flag_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/account/recovery_key_page.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';

class VerifyRecoveryPage extends StatefulWidget {
  const VerifyRecoveryPage({Key? key}) : super(key: key);

  @override
  State<VerifyRecoveryPage> createState() => _VerifyRecoveryPageState();
}

class _VerifyRecoveryPageState extends State<VerifyRecoveryPage> {
  final _recoveryKey = TextEditingController();
  final Logger _logger = Logger((_VerifyRecoveryPageState).toString());

  void _verifyRecoveryKey() async {
    final dialog = createProgressDialog(context, "Verifying recovery key...");
    await dialog.show();
    try {
      final String inputKey = _recoveryKey.text.trim();
      final String recoveryKey = Sodium.bin2hex(
        await UserService.instance.getOrCreateRecoveryKey(context),
      );
      final String recoveryKeyWords = bip39.entropyToMnemonic(recoveryKey);
      if (inputKey == recoveryKey || inputKey == recoveryKeyWords) {
        try {
          await UserRemoteFlagService.instance.markRecoveryVerificationAsDone();
        } catch (e) {
          await dialog.hide();
          if (e is DioError && e.type == DioErrorType.other) {
            await showErrorDialog(
              context,
              "No internet connection",
              "Please check your internet connection and try again.",
            );
          } else {
            await showGenericErrorDialog(context: context);
          }
          return;
        }
        Bus.instance.fire(NotificationEvent());
        await dialog.hide();
        // todo: change this as per figma once the component is ready
        await showErrorDialog(
          context,
          "Recovery key verified",
          "Great! Your recovery key is valid. Thank you for verifying.\n"
              "\nPlease"
              " remember to keep your recovery key safely backed up.",
        );
        Navigator.of(context).pop();
      } else {
        throw Exception("recovery key didn't match");
      }
    } catch (e, s) {
      _logger.severe("failed to verify recovery key", e, s);
      await dialog.hide();
      const String errMessage =
          "The recovery key you entered is not valid. Please make sure it "
          "contains 24 words, and check the spelling of each.\n\nIf you "
          "entered an older recovery code, make sure it is 64 characters long, and check each of them.";
      final result = await showChoiceDialog(
        context,
        title: "Invalid key",
        body: errMessage,
        firstButtonLabel: "Try again",
        secondButtonLabel: "View recovery key",
        secondButtonAction: ButtonAction.second,
      );
      if (result == ButtonAction.second) {
        await _onViewRecoveryKeyClick();
      }
    }
  }

  Future<void> _onViewRecoveryKeyClick() async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      "Please authenticate to view your recovery key",
    );
    if (hasAuthenticated) {
      String recoveryKey;
      try {
        recoveryKey = Sodium.bin2hex(
          await UserService.instance.getOrCreateRecoveryKey(context),
        );
        routeToPage(
          context,
          RecoveryKeyPage(
            recoveryKey,
            "OK",
            showAppBar: true,
            onDone: () {
              Navigator.of(context).pop();
            },
          ),
        );
      } catch (e) {
        showGenericErrorDialog(context: context);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enteTheme = Theme.of(context).colorScheme.enteTheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).iconTheme.color,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Confirm recovery key',
                          style: enteTheme.textTheme.h3Bold,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Your recovery key is the only way to recover your photos if you forget your password. You can find your recovery key in Settings > Account.\n\nPlease enter your recovery key here to verify that you have saved it correctly.",
                        style: enteTheme.textTheme.small
                            .copyWith(color: enteTheme.colorScheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          hintText: "Enter your recovery key",
                          contentPadding: const EdgeInsets.all(20),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        controller: _recoveryKey,
                        autofocus: false,
                        autocorrect: false,
                        keyboardType: TextInputType.multiline,
                        minLines: 4,
                        maxLines: null,
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GradientButton(
                                onTap: _verifyRecoveryKey,
                                text: "Confirm",
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20)
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
