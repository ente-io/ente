import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/utils/dialog_util.dart';

class TwoFactorRecoveryPage extends StatefulWidget {
  final String sessionID;
  final String encryptedSecret;
  final String secretDecryptionNonce;

  TwoFactorRecoveryPage(
      this.sessionID, this.encryptedSecret, this.secretDecryptionNonce,
      {Key key})
      : super(key: key);

  @override
  _TwoFactorRecoveryPageState createState() => _TwoFactorRecoveryPageState();
}

class _TwoFactorRecoveryPageState extends State<TwoFactorRecoveryPage> {
  final _recoveryKey = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "recover account",
          style: TextStyle(
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
                hintText: "enter your recovery key",
                contentPadding: EdgeInsets.all(20),
              ),
              style: TextStyle(
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
          Padding(padding: EdgeInsets.all(24)),
          Container(
            padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
            width: double.infinity,
            height: 64,
            child: button(
              "recover",
              fontSize: 18,
              onPressed: _recoveryKey.text.isNotEmpty
                  ? () async {
                      await UserService.instance.removeTwoFactor(
                          context,
                          widget.sessionID,
                          _recoveryKey.text,
                          widget.encryptedSecret,
                          widget.secretDecryptionNonce);
                    }
                  : null,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              showErrorDialog(
                context,
                "contact support",
                "please drop an email to support@ente.io from your registered email address",
              );
            },
            child: Container(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  "no recovery key?",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
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
