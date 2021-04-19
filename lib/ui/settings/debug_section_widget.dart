import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';

class DebugSectionWidget extends StatelessWidget {
  const DebugSectionWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(children: [
        Padding(padding: EdgeInsets.all(12)),
        SettingsSectionTitle("debug"),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            _showKeyAttributesDialog(context);
          },
          child: SettingsTextItem(
              text: "key attributes", icon: Icons.navigate_next),
        ),
      ]),
    );
  }

  void _showKeyAttributesDialog(BuildContext context) {
    final keyAttributes = Configuration.instance.getKeyAttributes();
    AlertDialog alert = AlertDialog(
      title: Text("key attributes"),
      content: SingleChildScrollView(
        child: Column(children: [
          Text("Key", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(Sodium.bin2base64(Configuration.instance.getKey())),
          Padding(padding: EdgeInsets.all(12)),
          Text("Encrypted Key", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.encryptedKey),
          Padding(padding: EdgeInsets.all(12)),
          Text("Key Decryption Nonce",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.keyDecryptionNonce),
          Padding(padding: EdgeInsets.all(12)),
          Text("KEK Salt", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(keyAttributes.kekSalt),
          Padding(padding: EdgeInsets.all(12)),
        ]),
      ),
      actions: [
        FlatButton(
          child: Text("OK"),
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
