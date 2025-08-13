import 'package:ente_auth/services/local_backup_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Location updated and initial backup created!'),),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Local Backup Settings"),
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
                  "Enable Automatic Backups",
                  style: getEnteTextTheme(context).largeBold,
                ),
                Switch(
                  value: _isBackupEnabled,
                  activeColor: Colors.white,
                  onChanged: (value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isAutoBackupEnabled', value);
                    setState(() {
                      _isBackupEnabled = value;
                    });

                    if (value == true) { //if toggle was on: trigger backup
                      if (_backupPath != null) {  //ensuring path was set
                       await LocalBackupService.instance.triggerAutomaticBackup();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Initial backup created!'),),
                        );
                      } 
                      else {
                        // we ask user to set a backup location
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please choose a backup location.'),),
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
                      "Backup Location",
                      style: getEnteTextTheme(context).largeBold,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select a folder to save backups. Backups run automatically when entries are added, deleted, or edited.",
                      style: getEnteTextTheme(context).small,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Location:',
                          style: getEnteTextTheme(context).body,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _backupPath ?? 'Not set. Please choose a location.',
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
                            child: const Text('Choose Location'),
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
                                "Security Notice",
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
                            "we can give any security warnings here- like say: make sure you choose a safe location etc??",
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