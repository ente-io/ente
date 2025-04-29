import 'package:bip39/bip39.dart' as bip39;
import 'package:dio/dio.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/services/user_remote_flag_service.dart';
import 'package:ente_auth/ui/account/recovery_key_page.dart';
import 'package:ente_auth/ui/common/gradient_button.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/navigation_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class VerifyRecoveryPage extends StatefulWidget {
  const VerifyRecoveryPage({super.key});

  @override
  State<VerifyRecoveryPage> createState() => _VerifyRecoveryPageState();
}

class _VerifyRecoveryPageState extends State<VerifyRecoveryPage> {
  final _recoveryKey = TextEditingController();
  final Logger _logger = Logger((_VerifyRecoveryPageState).toString());

  void _verifyRecoveryKey() async {
    final dialog =
        createProgressDialog(context, context.l10n.verifyingRecoveryKey);
    await dialog.show();
    try {
      final String inputKey = _recoveryKey.text.trim();
      final String recoveryKey =
          CryptoUtil.bin2hex(Configuration.instance.getRecoveryKey());
      final String recoveryKeyWords = bip39.entropyToMnemonic(recoveryKey);
      if (inputKey == recoveryKey || inputKey == recoveryKeyWords) {
        try {
          await UserRemoteFlagService.instance.markRecoveryVerificationAsDone();
        } catch (e) {
          await dialog.hide();
          if (e is DioException && e.type == DioExceptionType.unknown) {
            await showErrorDialog(
              context,
              "No internet connection",
              "Please check your internet connection and try again.",
            );
          } else {
            await showGenericErrorDialog(
              context: context,
              error: e,
            );
          }
          return;
        }

        await dialog.hide();
        // todo: change this as per figma once the component is ready
        await showErrorDialog(
          context,
          context.l10n.recoveryKeyVerified,
          context.l10n.recoveryKeySuccessBody,
        );
        Navigator.of(context).pop();
      } else {
        throw Exception("recovery key didn't match");
      }
    } catch (e, s) {
      _logger.severe("failed to verify recovery key", e, s);
      await dialog.hide();
      final String errMessage = context.l10n.invalidRecoveryKey;
      final result = await showChoiceDialog(
        context,
        title: context.l10n.invalidKey,
        body: errMessage,
        firstButtonLabel: context.l10n.tryAgain,
        secondButtonLabel: context.l10n.viewRecoveryKey,
        secondButtonAction: ButtonAction.second,
      );
      if (result!.action == ButtonAction.second) {
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
    await PlatformUtil.refocusWindows();

    if (hasAuthenticated) {
      String recoveryKey;
      try {
        recoveryKey =
            CryptoUtil.bin2hex(Configuration.instance.getRecoveryKey());
        await routeToPage(
          context,
          RecoveryKeyPage(
            recoveryKey,
            context.l10n.ok,
            showAppBar: true,
            onDone: () {
              Navigator.of(context).pop();
            },
          ),
        );
      } catch (e) {
        // ignore: unawaited_futures
        showGenericErrorDialog(
          context: context,
          error: e,
        );
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
                          context.l10n.confirmRecoveryKey,
                          style: enteTheme.textTheme.h3Bold,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.recoveryKeyVerifyReason,
                        style: enteTheme.textTheme.small
                            .copyWith(color: enteTheme.colorScheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          hintText: context.l10n.enterYourRecoveryKey,
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
                                text: context.l10n.confirm,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
