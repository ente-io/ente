import 'dart:io';

import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/local_backup_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalBackupSettingsPage extends StatefulWidget {
  const LocalBackupSettingsPage({super.key});

  @override
  State<LocalBackupSettingsPage> createState() =>
      _LocalBackupSettingsPageState();
}

class _LocalBackupSettingsPageState extends State<LocalBackupSettingsPage> {
  bool _isBackupEnabled = false;
  String? _backupPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // to load the saved settings from SharedPreferences when the page opens.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBackupEnabled = prefs.getBool('isAutoBackupEnabled') ?? false;
      _backupPath = prefs.getString('autoBackupPath');
    });
  }

  Future<String> _getDefaultBackupPath() async {
  Directory? dir;
  if (Platform.isAndroid) {
    dir = await getExternalStorageDirectory();
    //so default path would be /storage/emulated/0/Android/data/io.ente.auth/files/Downloads
    return '${dir!.path}/Downloads/EnteAuthBackups';
  } else {
    // Fallback for iOS and other platforms
    dir = await getDownloadsDirectory();
    return '${dir!.path}/EnteAuthBackups';
  }
}

  // opens directory picker
  Future<void> _pickAndSaveBackupLocation() async {
    //to fetch the current backup path
    final prefs = await SharedPreferences.getInstance();

    String? directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null) {
      await prefs.setString('autoBackupPath', directoryPath);
      setState(() {
        _backupPath = directoryPath;
      });

      await LocalBackupService.instance.triggerAutomaticBackup();
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.locationUpdatedAndBackupCreated),
        ),
      );
    }
  }

Future<void> _showSetPasswordDialog() async {
  final l10n = context.l10n;
  await showTextInputDialog(
    context,
    title: l10n.setPasswordTitle,
    submitButtonLabel: l10n.saveAction,
    hintText: l10n.enterPassword,
    isPasswordInput: true,
    onSubmit: (String password) async {
  if (password.length < 8) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.passwordTooShort),
    ),
  );
  return;
}
  const storage = FlutterSecureStorage();
  await storage.write(key: 'autoBackupPassword', value: password);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isAutoBackupEnabled', true);

  String? finalBackupPath = _backupPath;

  if (finalBackupPath == null) {
    try {
      finalBackupPath = await _getDefaultBackupPath();
      await Directory(finalBackupPath).create(recursive: true);
      await prefs.setString('autoBackupPath', finalBackupPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(l10n.noDefaultBackupFolder),
  ),
);

      await prefs.setBool('isAutoBackupEnabled', false);
      return;
    }
  }

  setState(() {
    _isBackupEnabled = true;
    _backupPath = finalBackupPath;
  });

  await LocalBackupService.instance.triggerAutomaticBackup();
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(l10n.initialBackupCreated)),
);
},
  );
}

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.localBackupSettingsTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.enableAutomaticBackups,
                  style: getEnteTextTheme(context).largeBold,
                ),
                Switch.adaptive(
  value: _isBackupEnabled,
  activeColor: Theme.of(context).colorScheme.enteTheme.colorScheme.primary400,
  activeTrackColor: Theme.of(context).colorScheme.enteTheme.colorScheme.primary300,
  inactiveTrackColor: Theme.of(context).colorScheme.enteTheme.colorScheme.fillMuted,
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  onChanged: (value) async {
  final prefs = await SharedPreferences.getInstance();

  if (value == true) {
    //when toggle is ON, show password dialog
    await _showSetPasswordDialog();
  } else {
    await prefs.setBool('isAutoBackupEnabled', false);
    setState(() {
      _isBackupEnabled = false;
    });
  }
},
),
              ],
            ),
            const SizedBox(height: 20),
            Opacity(
              opacity: _isBackupEnabled ? 1.0 : 0.4,
              child: IgnorePointer(
                ignoring: !_isBackupEnabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.backupLocation,
                      style: getEnteTextTheme(context).largeBold,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.backupLocationDescription,
                      style: getEnteTextTheme(context).small,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.currentLocation,
                          style: getEnteTextTheme(context).body,
                        ),
                        const SizedBox(height: 4),
if (_backupPath != null)
  Text(
    _backupPath!,
    style: getEnteTextTheme(context).small,
  )
else
  FutureBuilder<String>(
    future: _getDefaultBackupPath(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Text(
          "Loading default location...",
          style: getEnteTextTheme(context).small.copyWith(color: Colors.grey),
        );
      } else if (snapshot.hasError) {
        return Text(
          "Could not determine location.",
          style: getEnteTextTheme(context).small.copyWith(color: Colors.red),
        );

      } else {
        return Text(
          snapshot.data ?? '',
          style: getEnteTextTheme(context).small.copyWith(color: Colors.grey),
        );
      }
    },
  ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _pickAndSaveBackupLocation,
                            child: Text(l10n.changeLocation),
                          ),
                        ),


                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withAlpha(77),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.security_outlined,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.securityNotice,
                                style: getEnteTextTheme(context)
                                    .smallBold
                                    .copyWith(
                                      color: Colors.orange,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.backupSecurityNotice,
                            style: getEnteTextTheme(context).mini.copyWith(
                                  color: Colors.orange.shade700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}