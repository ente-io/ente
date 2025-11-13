import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/local_backup_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_result.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _passwordDialogHint = 'Your backup will be encrypted with this password.';

typedef LocalBackupVariantBuilder = Widget Function(
  BuildContext context,
  LocalBackupExperienceController controller,
);

class LocalBackupExperience extends StatefulWidget {
  const LocalBackupExperience({super.key, required this.builder});

  final LocalBackupVariantBuilder builder;

  @override
  State<LocalBackupExperience> createState() => _LocalBackupExperienceState();
}

class LocalBackupExperienceController {
  const LocalBackupExperienceController._(this._state);

  final _LocalBackupExperienceState _state;

  bool get hasLoaded => _state._hasLoaded;
  bool get isBusy => _state._isBusy;
  bool get shouldShowBusyOverlay => _state._shouldShowBusyOverlay;
  bool get isBackupEnabled => _state._isBackupEnabled;
  String? get backupPath => _state._backupPath;

  Future<void> toggleBackup(bool shouldEnable) =>
      _state._handleToggle(shouldEnable);

  Future<bool> changeLocation({String? successMessage}) =>
      _state._pickAndSaveBackupLocation(successMessage: successMessage);

  Future<bool> openLocationSetup() => _state._handleLocationSetup();

  Future<void> runManualBackup({bool showSnackBar = true}) =>
      _state._runManualBackup(showSnackBar: showSnackBar);

  Future<bool> updatePassword() => _state._promptPassword(
        forcePrompt: true,
        disableOnCancel: false,
        isUpdateFlow: true,
      );

  Future<bool> hasPasswordConfigured() => _state._hasStoredPassword();

  Future<String> resolveDefaultPath() => _state._getDefaultBackupPath();

  String simplifyPath(String fullPath) => _state._simplifyPath(fullPath);

  void showSnackBar(String message) => _state._showSnackBar(message);

  Future<void> refreshState() => _state._loadSettings();
}

class _LocalBackupExperienceState extends State<LocalBackupExperience> {
  static const _passwordKey = 'autoBackupPassword';
  static const _locationConfiguredKey = 'hasConfiguredBackupLocation';

  bool _isBackupEnabled = false;
  String? _backupPath;
  bool _hasConfiguredLocation = false;
  bool _isBusy = false;
  bool _shouldShowBusyOverlay = true;
  bool _hasLoaded = false;
  Future<String>? _defaultPathFuture;

  late final LocalBackupExperienceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LocalBackupExperienceController._(this);
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPath = prefs.getString('autoBackupPath');
    final locationConfigured =
        prefs.getBool(_locationConfiguredKey) ?? storedPath != null;
    if (!mounted) return;
    setState(() {
      _isBackupEnabled = prefs.getBool('isAutoBackupEnabled') ?? false;
      _backupPath = storedPath;
      _hasConfiguredLocation = locationConfigured;
      _hasLoaded = true;
    });
  }

  Future<void> _handleToggle(bool shouldEnable) async {
    await _withBusyGuard(
      () async {
        if (shouldEnable) {
          final success = await _startEnableFlow();
          if (!success) {
            return;
          }
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isAutoBackupEnabled', false);
          if (!mounted) return;
          setState(() {
            _isBackupEnabled = false;
          });
        }
      },
      showOverlay: false,
    );
  }

  Future<bool> _startEnableFlow() async {
    bool passwordConfigured = await _hasStoredPassword();
    if (!passwordConfigured) {
      passwordConfigured = await _promptPassword(
        forcePrompt: true,
        disableOnCancel: true,
        isUpdateFlow: false,
      );
    }
    if (!passwordConfigured) {
      return false;
    }

    bool locationReady = _hasConfiguredLocation;
    if (!locationReady) {
      locationReady = await _handleLocationSetup();
    }
    if (!locationReady) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutoBackupEnabled', true);
    if (!mounted) return false;
    setState(() {
      _isBackupEnabled = true;
    });
    await LocalBackupService.instance.triggerAutomaticBackup();
    _showSnackBar(context.l10n.initialBackupCreated);
    return true;
  }

  Future<void> _runManualBackup({bool showSnackBar = true}) async {
    await _withBusyGuard(() async {
      await LocalBackupService.instance.triggerAutomaticBackup();
      if (showSnackBar) {
        _showSnackBar(context.l10n.initialBackupCreated);
      }
    });
  }

  Future<void> _withBusyGuard(
    Future<void> Function() action, {
    bool showOverlay = true,
  }) async {
    if (_isBusy) {
      return;
    }
    setState(() {
      _isBusy = true;
      _shouldShowBusyOverlay = showOverlay;
    });
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _shouldShowBusyOverlay = true;
        });
      }
    }
  }

  Future<bool> _promptPassword({
    required bool forcePrompt,
    bool disableOnCancel = false,
    bool isUpdateFlow = false,
  }) async {
    if (!forcePrompt) {
      final stored = await _readStoredPassword();
      if (stored != null && stored.isNotEmpty) {
        return true;
      }
    }

    final String? password = await _showCustomPasswordDialog(
      isUpdateFlow: isUpdateFlow,
    );
    if (password == null) {
      if (disableOnCancel && mounted) {
        setState(() {
          _isBackupEnabled = false;
        });
      }
      return false;
    }

    const storage = FlutterSecureStorage();
    await storage.write(key: _passwordKey, value: password);
    return true;
  }

  Future<bool> _hasStoredPassword() async {
    final stored = await _readStoredPassword();
    return stored != null && stored.isNotEmpty;
  }

  Future<String?> _readStoredPassword() async {
    const storage = FlutterSecureStorage();
    try {
      return storage.read(key: _passwordKey);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _showCustomPasswordDialog({
    required bool isUpdateFlow,
  }) async {
    final l10n = context.l10n;
    final textController = TextEditingController();
    bool isPasswordHidden = true;
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isUpdateFlow ? 'Update backup password' : 'Set backup password',
                style: getEnteTextTheme(context).largeBold,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _passwordDialogHint,
                    style: getEnteTextTheme(context).smallFaint,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    obscureText: isPasswordHidden,
                    decoration: InputDecoration(
                      hintText: l10n.enterPassword,
                      hintStyle: getEnteTextTheme(context).mini,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordHidden = !isPasswordHidden;
                          });
                        },
                      ),
                    ),
                    onChanged: (text) {
                      setState(() {
                        if (errorText != null && text.length >= 8) {
                          errorText = null;
                        }
                      });
                    },
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: errorText == null
                        ? const SizedBox.shrink()
                        : Padding(
                            key: ValueKey(errorText),
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              errorText!,
                              style: getEnteTextTheme(context)
                                  .mini
                                  .copyWith(color: Colors.redAccent),
                            ),
                          ),
                  ),
                ],
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
                        onTap: () async {
                          if (textController.text.length < 8) {
                            setState(() {
                              errorText = l10n.passwordTooShort;
                            });
                            return;
                          }
                          Navigator.of(context).pop(textController.text.trim());
                        },
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

  Future<ButtonResult?> _showLocationChoiceDialog({
    required String displayPath,
  }) async {
    final l10n = context.l10n;

    final dialogBody =
        '${l10n.backupLocationChoiceDescription}\n\nCurrent backup folder:\n${_simplifyPath(displayPath)}';

    final result = await showDialogWidget(
      title: l10n.chooseBackupLocation,
      context: context,
      body: dialogBody,
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.primary,
          labelText: l10n.changeLocation,
          isInAlert: true,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.second,
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          labelText: l10n.continueLabel,
          isInAlert: true,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.first,
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
        return _persistLocation(
          currentPath,
          successMessage: context.l10n.initialBackupCreated,
        );
      } else if (result?.action == ButtonAction.second) {
        final newPath = await FilePicker.platform.getDirectoryPath();
        if (newPath != null) {
          currentPath = newPath;
        }
      } else {
        return false;
      }
    }
  }

  Future<String> _getDefaultBackupPath() {
    _defaultPathFuture ??= _computeDefaultBackupPath();
    return _defaultPathFuture!;
  }

  Future<String> _computeDefaultBackupPath() async {
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

  String _simplifyPath(String fullPath) {
    if (Platform.isAndroid) {
      const rootToRemove = '/storage/emulated/0/';
      if (fullPath.startsWith(rootToRemove)) {
        return fullPath.substring(rootToRemove.length);
      }
      return fullPath;
    }

    if (Platform.isIOS) {
      var simplified = fullPath;
      // iOS often prepends /private when surfacing sandboxed locations.
      const privatePrefix = '/private';
      if (simplified.startsWith(privatePrefix)) {
        simplified = simplified.substring(privatePrefix.length);
      }

      const markers = <String>[
        '/File Provider Storage/',
        '/Documents/',
        '/tmp/',
      ];

      for (final marker in markers) {
        final index = simplified.indexOf(marker);
        if (index != -1) {
          return simplified.substring(index + marker.length);
        }
      }

      final segments = simplified
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (segments.length >= 2) {
        return segments.sublist(segments.length - 2).join('/');
      }
      if (segments.isNotEmpty) {
        return segments.last;
      }
      return simplified;
    }

    return fullPath;
  }

  Future<bool> _pickAndSaveBackupLocation({String? successMessage}) async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null) {
      final saved = await _persistLocation(
        directoryPath,
        successMessage:
            successMessage ?? context.l10n.locationUpdatedAndBackupCreated,
      );
      if (saved) {
        await LocalBackupService.instance.triggerAutomaticBackup();
      }
      return saved;
    }
    return false;
  }

  Future<bool> _persistLocation(
    String path, {
    String? successMessage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await Directory(path).create(recursive: true);
      await prefs.setString('autoBackupPath', path);
      await prefs.setBool(_locationConfiguredKey, true);
      if (!mounted) return false;
      setState(() {
        _backupPath = path;
        _hasConfiguredLocation = true;
      });
      if (successMessage != null) {
        _showSnackBar(successMessage);
      }
      return true;
    } catch (_) {
      _showSnackBar(context.l10n.noDefaultBackupFolder);
      return false;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
