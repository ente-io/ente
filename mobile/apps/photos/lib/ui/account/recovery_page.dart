import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/account/password_entry_page.dart';
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/utils/dialog_util.dart';

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final _recoveryKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isFormValid = _recoveryKeyController.text.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.backgroundColour,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.backgroundColour,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: colorScheme.content,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          AppLocalizations.of(context).recoverAccount,
          style: textTheme.largeBold,
        ),
        centerTitle: true,
      ),
      body: _getBody(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ButtonWidgetV2(
          key: const ValueKey("recoveryButton"),
          buttonType: ButtonTypeV2.primary,
          labelText: AppLocalizations.of(context).logInLabel,
          isDisabled: !isFormValid,
          onTap: isFormValid ? _onRecoverPressed : null,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _getBody() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 12),
          TextInputWidgetV2(
            label: AppLocalizations.of(context).recoveryKey,
            hintText: AppLocalizations.of(context).enterYourRecoveryKey,
            textEditingController: _recoveryKeyController,
            maxLines: null,
            minLines: 5,
            autoCorrect: false,
            onChange: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ButtonWidgetV2(
              buttonType: ButtonTypeV2.link,
              labelText: AppLocalizations.of(context).noRecoveryKey,
              buttonSize: ButtonSizeV2.small,
              onTap: () async {
                // ignore: unawaited_futures
                showErrorDialog(
                  context,
                  AppLocalizations.of(context).sorry,
                  AppLocalizations.of(context).noRecoveryKeyNoDecryption,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRecoverPressed() async {
    FocusScope.of(context).unfocus();
    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).decrypting,
    );
    await dialog.show();
    try {
      await Configuration.instance.recover(_recoveryKeyController.text.trim());
      await dialog.hide();
      showShortToast(
        context,
        AppLocalizations.of(context).recoverySuccessful,
      );
      // ignore: unawaited_futures
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return const PopScope(
              canPop: false,
              child: PasswordEntryPage(
                mode: PasswordEntryMode.reset,
              ),
            );
          },
        ),
      );
    } catch (e) {
      await dialog.hide();
      String errMessage = AppLocalizations.of(context).incorrectRecoveryKeyBody;
      if (e is AssertionError) {
        errMessage = '$errMessage : ${e.message}';
      }
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        AppLocalizations.of(context).incorrectRecoveryKeyTitle,
        errMessage,
      );
    }
  }
}
