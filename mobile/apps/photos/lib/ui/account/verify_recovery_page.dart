import 'package:bip39/bip39.dart' as bip39;
import 'package:dio/dio.dart';
import 'package:ente_crypto/ente_crypto.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/notification_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/account/user_service.dart';
import 'package:photos/services/local_authentication_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/account/recovery_key_page.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';

class VerifyRecoveryPage extends StatefulWidget {
  const VerifyRecoveryPage({super.key});

  @override
  State<VerifyRecoveryPage> createState() => _VerifyRecoveryPageState();
}

class _VerifyRecoveryPageState extends State<VerifyRecoveryPage> {
  final _recoveryKey = TextEditingController();
  final Logger _logger = Logger((_VerifyRecoveryPageState).toString());

  void _verifyRecoveryKey() async {
    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).verifyingRecoveryKey,
    );
    await dialog.show();
    try {
      final String inputKey = _recoveryKey.text.trim();
      final String recoveryKey = CryptoUtil.bin2hex(
        await UserService.instance.getOrCreateRecoveryKey(context),
      );
      final String recoveryKeyWords = bip39.entropyToMnemonic(recoveryKey);
      if (inputKey == recoveryKey || inputKey == recoveryKeyWords) {
        try {
          await flagService.setRecoveryKeyVerified(true);
        } catch (e) {
          await dialog.hide();
          if (e is DioException && e.type == DioExceptionType.connectionError) {
            await showErrorDialog(
              context,
              AppLocalizations.of(context).noInternetConnection,
              AppLocalizations.of(context)
                  .pleaseCheckYourInternetConnectionAndTryAgain,
            );
          } else {
            await showGenericErrorDialog(context: context, error: e);
          }
          return;
        }
        Bus.instance.fire(NotificationEvent());
        await dialog.hide();
        // todo: change this as per figma once the component is ready
        await showErrorDialog(
          context,
          AppLocalizations.of(context).recoveryKeyVerified,
          AppLocalizations.of(context).recoveryKeySuccessBody,
        );
        Navigator.of(context).pop();
      } else {
        throw Exception("recovery key didn't match");
      }
    } catch (e, s) {
      _logger.severe("failed to verify recovery key", e, s);
      await dialog.hide();
      final String errMessage = AppLocalizations.of(context).invalidRecoveryKey;
      final result = await showChoiceDialog(
        context,
        title: AppLocalizations.of(context).invalidKey,
        body: errMessage,
        firstButtonLabel: AppLocalizations.of(context).tryAgain,
        secondButtonLabel: AppLocalizations.of(context).viewRecoveryKey,
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
    if (hasAuthenticated) {
      String recoveryKey;
      try {
        recoveryKey = CryptoUtil.bin2hex(
          await UserService.instance.getOrCreateRecoveryKey(context),
        );
        // ignore: unawaited_futures
        routeToPage(
          context,
          RecoveryKeyPage(
            recoveryKey,
            AppLocalizations.of(context).ok,
            showAppBar: true,
            onDone: () {
              Navigator.of(context).pop();
            },
          ),
        );
      } catch (e) {
        await showGenericErrorDialog(context: context, error: e);
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
                          AppLocalizations.of(context).confirmRecoveryKey,
                          style: enteTheme.textTheme.h3Bold,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        AppLocalizations.of(context).recoveryKeyVerifyReason,
                        style: enteTheme.textTheme.small
                            .copyWith(color: enteTheme.colorScheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: getEnteColorScheme(context).fillFaint,
                          hintText:
                              AppLocalizations.of(context).enterYourRecoveryKey,
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
                                text: AppLocalizations.of(context).confirm,
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
