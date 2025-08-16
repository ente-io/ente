import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/local_backup_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  // opens directory picker
  Future<void> _pickAndSaveBackupLocation() async {
  String? directoryPath = await FilePicker.platform.getDirectoryPath();

  if (directoryPath != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('autoBackupPath', directoryPath);
    setState(() {
      _backupPath = directoryPath;
    });

    await LocalBackupService.instance.triggerAutomaticBackup();   //whenever backup path is set, we trigger
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.locationUpdatedAndBackupCreated),),
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
          const SnackBar(content: Text('Password must be at least 8 characters long.')),
        );
        return;
      }
      
      // to store the backup password securely
      const storage = FlutterSecureStorage();
      await storage.write(key: 'autoBackupPassword', value: password);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup password saved successfully!')),
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
      body: Padding(
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
                Switch(
                  value: _isBackupEnabled,
                  activeColor: Colors.white,
                  onChanged: (value) async {
                    final l10n = context.l10n;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isAutoBackupEnabled', value);
                    setState(() {
                      _isBackupEnabled = value;
                    });

                    if (value == true) { //if toggle was on: trigger backup
                      if (_backupPath != null) {  //ensuring path was set
                       await LocalBackupService.instance.triggerAutomaticBackup();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.initialBackupCreated),),
                        );
                      } 
                      else {
                        // we ask user to set a backup location
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                              Text(l10n.pleaseChooseBackupLocation),),
                        );
                      }
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
                        Text(
                          _backupPath ?? l10n.notSetPleaseChooseLocation,
                          style: getEnteTextTheme(context).small.copyWith(
                                color: _backupPath != null
                                    ? null
                                    : Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _pickAndSaveBackupLocation,
                            child: Text(l10n.chooseLocation),
                          ),
                        ),

                        const SizedBox(height: 10),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
        ),
        onPressed: _showSetPasswordDialog,
        child: const Text('Set Backup Password'),
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
    );
  }
}