import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/account/two_factor.dart";
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/utils/dialog_util.dart';

class TwoFactorRecoveryPage extends StatefulWidget {
  final String sessionID;
  final String encryptedSecret;
  final String secretDecryptionNonce;
  final TwoFactorType type;

  const TwoFactorRecoveryPage(
    this.type,
    this.sessionID,
    this.encryptedSecret,
    this.secretDecryptionNonce, {
    super.key,
  });

  @override
  State<TwoFactorRecoveryPage> createState() => _TwoFactorRecoveryPageState();
}

class _TwoFactorRecoveryPageState extends State<TwoFactorRecoveryPage> {
  final _recoveryKey = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).recoverAccount,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: S.of(context).enterYourRecoveryKey,
                contentPadding: const EdgeInsets.all(20),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              controller: _recoveryKey,
              autofocus: false,
              autocorrect: false,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),
          const Padding(padding: EdgeInsets.all(24)),
          Container(
            padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
            width: double.infinity,
            height: 64,
            child: OutlinedButton(
              onPressed: _recoveryKey.text.isNotEmpty
                  ? () async {
                      await UserService.instance.removeTwoFactor(
                        context,
                        widget.type,
                        widget.sessionID,
                        _recoveryKey.text,
                        widget.encryptedSecret,
                        widget.secretDecryptionNonce,
                      );
                    }
                  : null,
              child: Text(S.of(context).recover),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              showErrorDialog(
                context,
                S.of(context).contactSupport,
                S.of(context).dropSupportEmail("support@ente.io"),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  S.of(context).noRecoveryKey,
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 12,
                    color:
                        getEnteColorScheme(context).textBase.withOpacity(0.9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
