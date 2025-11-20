import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/local_backup_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_lock_screen/local_authentication_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saf_util/saf_util.dart';
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
  String? get backupTreeUri => _state._backupTreeUri;

  Future<void> toggleBackup(bool shouldEnable) =>
      _state._handleToggle(shouldEnable);

  Future<bool> changeLocation({String? successMessage}) =>
      _state._pickAndSaveBackupLocation(successMessage: successMessage);

  Future<bool> openLocationSetup() => _state._handleLocationSetup();

  Future<bool> resetBackupLocation() => _state._resetBackupLocation();

  Future<void> runManualBackup({bool showSnackBar = true}) =>
      _state._runManualBackup(showSnackBar: showSnackBar);

  Future<bool> updatePassword(BuildContext context) =>
      _state._updatePassword(context);

  Future<bool> hasPasswordConfigured() => _state._hasStoredPassword();

  String simplifyPath(String fullPath) => _state._simplifyPath(fullPath);

  void showSnackBar(String message) => _state._showSnackBar(message);

  Future<void> refreshState() => _state._loadSettings();
}

class _LocalBackupExperienceState extends State<LocalBackupExperience> {
  static const _passwordKey = 'autoBackupPassword';
  static const _locationConfiguredKey = 'hasConfiguredBackupLocation';
  static const _treeUriKey = 'autoBackupTreeUri';

  bool _isBackupEnabled = false;
  String? _backupPath;
  String? _backupTreeUri;
  bool _isBusy = false;
  bool _shouldShowBusyOverlay = true;
  bool _hasLoaded = false;

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
    final storedTreeUri = prefs.getString(_treeUriKey);
    if (!mounted) return;
    setState(() {
      _isBackupEnabled = prefs.getBool('isAutoBackupEnabled') ?? false;
      _backupPath = storedPath;
      _backupTreeUri = storedTreeUri;
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
    final hasPassword =
        await _ensurePasswordConfigured(disableOnCancel: true);
    if (!hasPassword) {
      return false;
    }

    final selected = await _handleLocationSetup();
    if (!selected) {
      _showSnackBar('Select a folder to continue');
      return false;
    }
    if (Platform.isAndroid &&
        (_backupTreeUri == null || _backupTreeUri!.isEmpty) &&
        (_backupPath == null || _backupPath!.isEmpty)) {
      _showSnackBar(context.l10n.noDefaultBackupFolder);
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutoBackupEnabled', true);
    if (!mounted) return false;
    setState(() {
      _isBackupEnabled = true;
    });
    await LocalBackupService.instance.triggerAutomaticBackup(isManual: false);
    return true;
  }

  Future<void> _runManualBackup({bool showSnackBar = true}) async {
    await _withBusyGuard(() async {
      final hasPassword =
          await _ensurePasswordConfigured(disableOnCancel: false);
      if (!hasPassword) return;

      final hasLocation = await _ensureBackupLocationSelected();
      if (!hasLocation) return;

      await LocalBackupService.instance.triggerAutomaticBackup(isManual: true);
      if (showSnackBar) {
        _showSnackBar(context.l10n.initialBackupCreated);
      }
    });
  }

  Future<bool> _ensurePasswordConfigured({required bool disableOnCancel}) async {
    if (await _hasStoredPassword()) {
      return true;
    }
    return _promptPassword(
      forcePrompt: true,
      disableOnCancel: disableOnCancel,
      isUpdateFlow: false,
    );
  }

  Future<bool> _ensureBackupLocationSelected() async {
    if (Platform.isAndroid) {
      if ((_backupTreeUri == null || _backupTreeUri!.isEmpty) &&
          (_backupPath == null || _backupPath!.isEmpty)) {
        return _pickAndSaveBackupLocation(
          requireSelection: true,
          shouldTriggerBackup: false,
        );
      }
      return true;
    }

    var resolvedPath = _backupPath;
    if (resolvedPath == null || resolvedPath.isEmpty) {
      final saved = await _pickAndSaveBackupLocation(
        requireSelection: true,
        shouldTriggerBackup: false,
      );
      if (!saved) {
        return false;
      }
      resolvedPath = _backupPath;
    }
    if (resolvedPath != null && resolvedPath.isNotEmpty) {
      await Directory(resolvedPath).create(recursive: true);
    }
    return true;
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

  Future<bool> _updatePassword(BuildContext context) async {
    // Request app lock authentication first
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      'Authenticate to update backup password',
    );

    if (!hasAuthenticated) {
      return false;
    }

    return _promptPassword(
      forcePrompt: true,
      disableOnCancel: false,
      isUpdateFlow: true,
    );
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

  Future<bool> _resetBackupLocation() async {
    if (_isBackupEnabled) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('autoBackupPath');
    await prefs.remove(_treeUriKey);
    await prefs.remove(_locationConfiguredKey);
    if (!mounted) return false;
    setState(() {
      _backupPath = null;
      _backupTreeUri = null;
    });
    return true;
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

  Future<bool> _handleLocationSetup() async {
    if (Platform.isAndroid) {
      return _pickAndPersistAndroidLocation();
    }

    if (Platform.isIOS) {
      final l10n = context.l10n;
      final dialogBody = StringBuffer()
        ..writeln(l10n.backupLocationChoiceDescription)
        ..writeln()
        ..writeln(
          'To enable backups on iOS, choose a folder in Files (for example “On My iPhone”).',
        )
        ..writeln()
        ..writeAll(
          _backupPath != null && _backupPath!.isNotEmpty
              ? [
                  'Current backup folder:',
                  _simplifyPath(_backupPath!),
                ]
              : const [],
          '\n',
        );

      final result = await showDialogWidget(
        title: l10n.chooseBackupLocation,
        context: context,
        body: dialogBody.toString(),
        buttons: const [
          ButtonWidget(
            buttonType: ButtonType.primary,
            labelText: 'Select folder',
            isInAlert: true,
            buttonSize: ButtonSize.large,
            buttonAction: ButtonAction.second,
          ),
          ButtonWidget(
            buttonType: ButtonType.secondary,
            labelText: 'Cancel',
            isInAlert: true,
            buttonSize: ButtonSize.large,
            buttonAction: ButtonAction.first,
          ),
        ],
      );

      if (result?.action == ButtonAction.second) {
        final pickedPath = await FilePicker.platform.getDirectoryPath();
        if (pickedPath != null) {
          return _persistLocation(
            pickedPath,
            successMessage: context.l10n.initialBackupCreated,
          );
        }
      }
      return false;
    }

    final pickedPath = await FilePicker.platform.getDirectoryPath();
    if (pickedPath != null) {
      return _persistLocation(
        pickedPath,
        successMessage: context.l10n.initialBackupCreated,
      );
    }
    return false;
  }

  String _simplifyPath(String fullPath) {
    if (fullPath.isEmpty) {
      return fullPath;
    }

    if (Platform.isAndroid) {
      if (fullPath.startsWith('content://')) {
        final decoded = Uri.decodeComponent(fullPath.split('/').last);
        return decoded.replaceFirst('primary:', '');
      }

      const rootsToRemove = <String>[
        '/storage/emulated/0/',
        '/storage/self/primary/',
      ];

      for (final root in rootsToRemove) {
        if (fullPath.startsWith(root)) {
          return fullPath.substring(root.length);
        }
      }
      return fullPath;
    }

    if (Platform.isIOS) {
      var simplified = fullPath;
      const fileScheme = 'file://';
      if (simplified.startsWith(fileScheme)) {
        simplified = simplified.substring(fileScheme.length);
      }
      // iOS often prepends /private when surfacing sandboxed locations.
      const privatePrefix = '/private';
      if (simplified.startsWith(privatePrefix)) {
        simplified = simplified.substring(privatePrefix.length);
      }

      const icloudMarker = '/Mobile Documents/';
      if (simplified.contains(icloudMarker)) {
        final afterMarker = simplified.split(icloudMarker).last;
        const cloudDocsPrefix = 'com~apple~CloudDocs/';
        if (afterMarker.startsWith(cloudDocsPrefix)) {
          final remaining = afterMarker.substring(cloudDocsPrefix.length);
          return remaining.isNotEmpty ? 'iCloud Drive/$remaining' : 'iCloud Drive';
        }
        if (afterMarker.isNotEmpty) {
          return afterMarker;
        }
      }

      const markers = <String>[
        '/File Provider Storage/',
        '/Documents/',
        '/tmp/',
      ];

      for (final marker in markers) {
        final index = simplified.indexOf(marker);
        if (index != -1) {
          final afterMarker = simplified.substring(index + marker.length);
          if (afterMarker.isNotEmpty) {
            return afterMarker;
          }
          final fallbackSegments =
              marker.split('/').where((segment) => segment.isNotEmpty).toList();
          if (fallbackSegments.isNotEmpty) {
            return fallbackSegments.last;
          }
          return simplified;
        }
      }

      final segments =
          simplified.split('/').where((segment) => segment.isNotEmpty).toList();
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

  Future<bool> _pickAndSaveBackupLocation({
    String? successMessage,
    bool requireSelection = false,
    bool shouldTriggerBackup = true,
  }) async {
    if (Platform.isAndroid) {
      final saved = await _pickAndPersistAndroidLocation();
      if (saved) {
        if (shouldTriggerBackup) {
          await LocalBackupService.instance.triggerAutomaticBackup(
            isManual: true,
          );
        }
      } else if (requireSelection) {
        _showSnackBar('Select a folder to continue');
      }
      return saved;
    } else {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath != null) {
        final saved = await _persistLocation(
          directoryPath,
          successMessage:
              successMessage ?? context.l10n.locationUpdatedAndBackupCreated,
        );
        if (saved) {
          if (shouldTriggerBackup) {
            await LocalBackupService.instance.triggerAutomaticBackup(
              isManual: true,
            );
          }
        }
        return saved;
      }
      if (requireSelection) {
        _showSnackBar('Select a folder to continue');
      }
      return false;
    }
  }

  Future<bool> _persistLocation(
    String path, {
    String? successMessage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    Future<bool> savePath(String target) async {
      try {
        await Directory(target).create(recursive: true);
        await prefs.setString('autoBackupPath', target);
        await prefs.remove(_treeUriKey);
        await prefs.setBool(_locationConfiguredKey, true);
        if (!mounted) return false;
        setState(() {
          _backupPath = target;
          _backupTreeUri = null;
        });
        if (successMessage != null) {
          _showSnackBar(successMessage);
        }
        return true;
      } catch (_) {
        return false;
      }
    }

    if (await savePath(path)) {
      return true;
    }

    if (Platform.isAndroid) {
      final fallbackPath = await _androidPrivateBackupPath();
      if (fallbackPath != null && fallbackPath != path) {
        final savedFallback = await savePath(fallbackPath);
        if (savedFallback) {
          return true;
        }
      }
    }

    _showSnackBar(context.l10n.noDefaultBackupFolder);
    return false;
  }

  Future<String?> _androidPrivateBackupPath() async {
    final androidBasePath = await _androidBackupBasePath();
    return androidBasePath != null ? '$androidBasePath/EnteAuthBackups' : null;
  }

  Future<bool> _pickAndPersistAndroidLocation() async {
    final saf = SafUtil();
    final picked = await saf.pickDirectory();
    final treeUri = picked?.uri;
    if (treeUri == null || treeUri.isEmpty) {
      return false;
    }

    return _persistAndroidLocation(treeUri);
  }

  Future<bool> _persistAndroidLocation(String treeUri) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_treeUriKey, treeUri);
      await prefs.setBool(_locationConfiguredKey, true);
      if (!mounted) return false;
      setState(() {
        _backupTreeUri = treeUri;
        _backupPath = null;
      });
      _showSnackBar(context.l10n.locationUpdatedAndBackupCreated);
      return true;
    } catch (_) {
      _showSnackBar(context.l10n.noDefaultBackupFolder);
      return false;
    }
  }

  Future<String?> _androidBackupBasePath() async {
    Directory directory = Directory('/storage/emulated/0/Download');
    if (await directory.exists()) {
      return directory.path;
    }

    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      return externalDir.path;
    }

    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
