import 'dart:io';

import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/local_backup_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_result.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  Future<String?> _showCustomPasswordDialog() async {
    final l10n = context.l10n;
    final textController = TextEditingController();
    // state variable to track password visibility
    bool isPasswordHidden = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.setPasswordTitle, style: getEnteTextTheme(context).largeBold),
              content: TextField(
                controller: textController,
                autofocus: true,
                obscureText: isPasswordHidden,
                decoration: InputDecoration(
                  hintText: l10n.enterPassword,
                  hintStyle: getEnteTextTheme(context).mini,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordHidden = !isPasswordHidden;
                      });
                    },
                  ),
                ),
                onChanged: (text) => setState(() {}),
              ),
              actions: [
                Row(
                  children: [

                    Expanded(
                      child: ButtonWidget(
                        buttonType: ButtonType.secondary,
                        labelText: l10n.cancel,
                        onTap: () async => Navigator.of(context).pop(null),
                      ),
                    ),

                    const SizedBox(width: 8), 

                    Expanded(
                      child: ButtonWidget(
                        buttonType: ButtonType.primary,
                        labelText: l10n.saveAction,
                        isDisabled: textController.text.isEmpty,
                        onTap: () async => Navigator.of(context).pop(textController.text),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<ButtonResult?> _showLocationChoiceDialog({required String displayPath}) async {
    final l10n = context.l10n;

    final dialogBody =
        '${l10n.backupLocationChoiceDescription}\n\nSelected: ${_simplifyPath(displayPath)}';

    final result = await showDialogWidget(
      title: l10n.chooseBackupLocation,
      context: context,
      body: dialogBody, 
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.primary,
          labelText: l10n.saveBackup,
          isInAlert: true,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.first,
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          labelText: l10n.changeLocation, 
          isInAlert: true,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.second,
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          labelText: l10n.cancel,
          isInAlert: true,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.cancel,
        ),
      ],
    );

    return result;
  }

  Future<bool> _handleLocationSetup() async {

    String currentPath = _backupPath ?? await _getDefaultBackupPath();

    while (true) {
      final result = await _showLocationChoiceDialog(displayPath: currentPath);

      if (result?.action == ButtonAction.first) {
        final prefs = await SharedPreferences.getInstance();
        try {
          await Directory(currentPath).create(recursive: true);
          await prefs.setString('autoBackupPath', currentPath);
          setState(() {
            _backupPath = currentPath;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.initialBackupCreated)),
          );
          return true; 
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.noDefaultBackupFolder)),
          );
          return false; 
        }
      }

      else if (result?.action == ButtonAction.second) {
        final newPath = await FilePicker.platform.getDirectoryPath();
        if (newPath != null) {
          currentPath = newPath;
        }
        
      }
      
      else {
        return false;
      }
    }
  }

  Future<String> _getDefaultBackupPath() async {
    if (Platform.isAndroid) {
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        String storagePath = externalDir.path.split('/Android')[0];
        return '$storagePath/Download/EnteAuthBackups';
      }
    }

    Directory? dir = await getDownloadsDirectory();
    dir ??= await getApplicationDocumentsDirectory();
    return '${dir.path}/EnteAuthBackups';
  }

  String _simplifyPath(String fullPath) {   //takes a file path string and shortens it if it matches the common Android root path.
    const rootToRemove = '/storage/emulated/0/';
    if (fullPath.startsWith(rootToRemove)) {
      return fullPath.substring(rootToRemove.length);
    }
    return fullPath;
  }

  // opens directory picker
  Future<bool> _pickAndSaveBackupLocation({String? successMessage}) async {
    final prefs = await SharedPreferences.getInstance();
    final l10n = context.l10n;

    String? directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null) {

      await prefs.setString('autoBackupPath', directoryPath);
      
      // we only set the state and create the backup if a path was chosen
      setState(() {
        _backupPath = directoryPath;
      });
      await LocalBackupService.instance.triggerAutomaticBackup();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage ?? l10n.locationUpdatedAndBackupCreated),  
        ),
      );
      return true; 
    }
    return false; //user cancelled the file picker
  }

   Future<void> _showSetPasswordDialog() async {
    final String? password = await _showCustomPasswordDialog();
    if (password == null) {
      setState(() {
        _isBackupEnabled = false;
      });
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.passwordTooShort),
        ),
      );
      setState(() {
        _isBackupEnabled = false;
      });
      return;
    }

    const storage = FlutterSecureStorage();
    await storage.write(key: 'autoBackupPassword', value: password);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final bool setupCompleted = await _handleLocationSetup();
      if (!mounted) return;

      if (setupCompleted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAutoBackupEnabled', true);
        setState(() {
          _isBackupEnabled = true;
        });
        await LocalBackupService.instance.triggerAutomaticBackup();
      } else {
        setState(() {
          _isBackupEnabled = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.localBackupSettingsTitle), //text shown on appbar
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l10n.enableAutomaticBackups,  //toggle text
                      style: getEnteTextTheme(context).largeBold,
                    ),
                  ),
                  Switch.adaptive(
                    value: _isBackupEnabled,
                    activeColor: Theme.of(context)
                        .colorScheme
                        .enteTheme
                        .colorScheme
                        .primary400,
                    activeTrackColor: Theme.of(context)
                        .colorScheme
                        .enteTheme
                        .colorScheme
                        .primary300,
                    inactiveTrackColor: Theme.of(context)
                        .colorScheme
                        .enteTheme
                        .colorScheme
                        .fillMuted,
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
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  l10n.backupDescription, //text below toggle
                  style: getEnteTextTheme(context).mini,
                ),
              ),
              const SizedBox(height: 20),
              Opacity(
                opacity: _isBackupEnabled ? 1.0 : 0.4,
                child: IgnorePointer(
                  ignoring: !_isBackupEnabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.currentLocation, //shows current backup location
                            style: getEnteTextTheme(context).body,
                          ),
                          const SizedBox(height: 4),
                          if (_backupPath != null)
                            Text(
                              _simplifyPath(_backupPath!),
                              style: getEnteTextTheme(context).small,
                            )
                          else
                            FutureBuilder<String>(
                              future: _getDefaultBackupPath(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text(
                                     l10n.loadDefaultLocation, 
                                    style: getEnteTextTheme(context)
                                        .small
                                        .copyWith(color: Colors.grey),
                                  );
                                } else if (snapshot.hasError) {
                                  return Text(
                                    l10n.couldNotDetermineLocation, 
                                    style: getEnteTextTheme(context)
                                        .small
                                        .copyWith(color: Colors.red),
                                  );
                                } else {
                                  return Text(
                                    _simplifyPath(snapshot.data ?? ''),
                                    style: getEnteTextTheme(context)
                                        .small
                                        .copyWith(color: Colors.grey),
                                  );
                                }
                              },
                            ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _pickAndSaveBackupLocation(),
                              child: Text(l10n.changeCurrentLocation),
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
                                  l10n.securityNotice,  //security notice title
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
                              l10n.backupSecurityNotice,  //security notice description
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