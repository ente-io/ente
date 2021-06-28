import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/backup_folder_selection_widget.dart';
import 'package:photos/ui/settings/settings_section_title.dart';
import 'package:photos/ui/settings/settings_text_item.dart';

class BackupSectionWidget extends StatefulWidget {
  BackupSectionWidget({Key key}) : super(key: key);

  @override
  BackupSectionWidgetState createState() => BackupSectionWidgetState();
}

class BackupSectionWidgetState extends State<BackupSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          SettingsSectionTitle("backup"),
          Padding(
            padding: EdgeInsets.all(4),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: const BackupFolderSelectionWidget("backup"),
                    backgroundColor: Color.fromRGBO(8, 18, 18, 1),
                    insetPadding: const EdgeInsets.all(24),
                    contentPadding: const EdgeInsets.all(24),
                  );
                },
                barrierColor: Colors.black.withOpacity(0.85),
              );
            },
            child: SettingsTextItem(
                text: "backed up folders", icon: Icons.navigate_next),
          ),
          Platform.isIOS
              ? Padding(padding: EdgeInsets.all(2))
              : Padding(padding: EdgeInsets.all(2)),
          Divider(height: 4),
          Platform.isIOS
              ? Padding(padding: EdgeInsets.all(2))
              : Padding(padding: EdgeInsets.all(4)),
          Container(
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("backup over mobile data"),
                Switch(
                  value: Configuration.instance.shouldBackupOverMobileData(),
                  onChanged: (value) async {
                    Configuration.instance.setBackupOverMobileData(value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
