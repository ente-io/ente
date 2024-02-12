import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/ui/settings/common_settings.dart';
import 'package:ente_auth/ui/settings/settings_section_title.dart';
import 'package:ente_auth/ui/settings/settings_text_item.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class DebugSectionWidget extends StatelessWidget {
  const DebugSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // This is a debug only section not shown to end users, so these strings are
    // not translated.
    return ExpandablePanel(
      header: const SettingsSectionTitle("Debug"),
      collapsed: Container(),
      expanded: _getSectionOptions(context),
      theme: getExpandableTheme(),
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            _showKeyAttributesDialog(context);
          },
          child: const SettingsTextItem(
            text: "Key attributes",
            icon: Icons.navigate_next,
          ),
        ),
      ],
    );
  }

  void _showKeyAttributesDialog(BuildContext context) {
    final l10n = context.l10n;
    final keyAttributes = Configuration.instance.getKeyAttributes()!;
    final AlertDialog alert = AlertDialog(
      title: const Text("key attributes"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Key",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(CryptoUtil.bin2base64(Configuration.instance.getKey()!)),
            const Padding(padding: EdgeInsets.all(12)),
            const Text(
              "Encrypted Key",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(keyAttributes.encryptedKey),
            const Padding(padding: EdgeInsets.all(12)),
            const Text(
              "Key Decryption Nonce",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(keyAttributes.keyDecryptionNonce),
            const Padding(padding: EdgeInsets.all(12)),
            const Text(
              "KEK Salt",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(keyAttributes.kekSalt),
            const Padding(padding: EdgeInsets.all(12)),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(l10n.ok),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
