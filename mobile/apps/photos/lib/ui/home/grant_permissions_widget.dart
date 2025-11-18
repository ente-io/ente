import "dart:async";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photo_manager/photo_manager.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/permission_granted_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/backup_preference_service.dart';
import 'package:photos/services/sync/local_sync_service.dart';
import 'package:photos/services/sync/sync_service.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/dialog_util.dart";
import 'package:photos/utils/local_settings.dart';
import "package:styled_text/styled_text.dart";

class GrantPermissionsWidget extends StatefulWidget {
  const GrantPermissionsWidget({super.key});

  @override
  State<GrantPermissionsWidget> createState() => _GrantPermissionsWidgetState();
}

class _GrantPermissionsWidgetState extends State<GrantPermissionsWidget> {
  final Logger _logger = Logger("_GrantPermissionsWidgetState");
  bool _showOnlyNewFeature = flagService.enableOnlyBackupFuturePhotos;
  final LocalSettings _localSettings = localSettings;

  @override
  void initState() {
    super.initState();
    _ensureFlagsLoaded();
  }

  @override
  void dispose() {
    _flagRefresh?.cancel();
    super.dispose();
  }

  StreamSubscription<void>? _flagRefresh;

  void _ensureFlagsLoaded() {
    if (_showOnlyNewFeature) {
      return;
    }
    _flagRefresh =
        Stream<void>.fromFuture(flagService.refreshFlags()).listen((_) {
      final bool updated = flagService.enableOnlyBackupFuturePhotos;
      if (updated != _showOnlyNewFeature && mounted) {
        setState(() {
          _showOnlyNewFeature = updated;
        });
      }
    })
          ..onError((Object error, StackTrace stackTrace) {
            _logger.warning("Failed to refresh flags", error, stackTrace);
          });
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final headerText = _showOnlyNewFeature
        ? context.l10n.chooseHowEnteBacksUp
        : AppLocalizations.of(context).entePhotosPerm;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 120),
          child: Column(
            children: [
              const SizedBox(
                height: 24,
              ),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    isLightMode
                        ? Image.asset(
                            'assets/loading_photos_background.png',
                            color: Colors.white.withValues(alpha: 0.4),
                            colorBlendMode: BlendMode.modulate,
                          )
                        : Image.asset(
                            'assets/loading_photos_background_dark.png',
                          ),
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 42),
                          Image.asset(
                            "assets/gallery_locked.png",
                            height: 160,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                child: StyledText(
                  text: headerText,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontWeight: FontWeight.w700),
                  tags: {
                    'i': StyledTextTag(
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.w400),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildActionArea(
        context,
        _showOnlyNewFeature,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    bool showOnlyNewFeature,
  ) {
    if (!showOnlyNewFeature) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: getEnteColorScheme(context).backgroundBase,
              spreadRadius: 190,
              blurRadius: 30,
              offset: const Offset(0, 170),
            ),
          ],
        ),
        width: double.infinity,
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const ValueKey("grantPermissionButton"),
            onPressed: _onTapLegacyContinue,
            child: Text(AppLocalizations.of(context).continueLabel),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: getEnteColorScheme(context).backgroundBase,
            spreadRadius: 190,
            blurRadius: 30,
            offset: const Offset(0, 170),
          ),
        ],
      ),
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const ValueKey("onlyNewPhotosButton"),
              onPressed: _onTapOnlyNewPhotos,
              child: Text(context.l10n.backupOnlyNewPhotos),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const ValueKey("selectFoldersButton"),
              onPressed: _onTapSelectFolders,
              child: Text(context.l10n.selectFoldersToBackup),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            key: const ValueKey("skipForNowButton"),
            behavior: HitTestBehavior.opaque,
            onTap: _onTapSkip,
            child: Text(
              context.l10n.skipForNow,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTapOnlyNewPhotos() async {
    try {
      final state = await permissionService.requestPhotoMangerPermissions();
      _logger.info("Permission state: $state");
      if (state == PermissionState.authorized ||
          state == PermissionState.limited) {
        await _setOnlyNewSinceNow();
        await BackupPreferenceService.instance.autoSelectAllFoldersIfEligible();
        unawaited(LocalSyncService.instance.sync());
        await onPermissionGranted(
          state,
          shouldMarkLimitedFolders: false,
        );
      } else {
        await _showPermissionDeniedDialog();
      }
    } catch (e) {
      _logger.severe(
        "Failed to request permission: ${e.toString()}",
        e,
      );
      showGenericErrorDialog(context: context, error: e).ignore();
    }
  }

  Future<void> _onTapSelectFolders() async {
    try {
      final state = await permissionService.requestPhotoMangerPermissions();
      _logger.info("Permission state: $state");
      if (state == PermissionState.authorized ||
          state == PermissionState.limited) {
        await onPermissionGranted(state);
      } else {
        await _showPermissionDeniedDialog();
      }
    } catch (e) {
      _logger.severe(
        "Failed to request permission: ${e.toString()}",
        e,
      );
      showGenericErrorDialog(context: context, error: e).ignore();
    }
  }

  Future<void> _onTapSkip() async {
    await _localSettings.setOnboardingPermissionSkipped(true);
    if (mounted) {
      setState(() {});
    }
    Bus.instance.fire(PermissionGrantedEvent());
  }

  Future<void> _onTapLegacyContinue() async {
    try {
      final state = await permissionService.requestPhotoMangerPermissions();
      _logger.info("Permission state: $state");
      if (state == PermissionState.authorized ||
          state == PermissionState.limited) {
        await onPermissionGranted(state);
      } else {
        await _showPermissionDeniedDialog();
      }
    } catch (e) {
      _logger.severe(
        "Failed to request permission: ${e.toString()}",
        e,
      );
      showGenericErrorDialog(context: context, error: e).ignore();
    }
  }

  Future<void> _showPermissionDeniedDialog() async {
    await showChoiceDialog(
      context,
      title: context.l10n.allowPermTitle,
      body: context.l10n.allowPermBody,
      firstButtonLabel: context.l10n.openSettings,
      firstButtonOnTap: () async {
        await PhotoManager.openSetting();
      },
    );
  }

  Future<void> onPermissionGranted(
    PermissionState state, {
    bool shouldMarkLimitedFolders = true,
  }) async {
    _logger.info("Permission granted " + state.toString());
    await permissionService.onUpdatePermission(state);
    await _localSettings.setOnboardingPermissionSkipped(false);
    if (shouldMarkLimitedFolders && state == PermissionState.limited) {
      // when limited permission is granted, by default mark all folders for
      // backup
      await _localSettings.setSelectAllFoldersForBackup(true);
    }
    SyncService.instance.onPermissionGranted().ignore();
    Bus.instance.fire(PermissionGrantedEvent());
  }

  Future<void> _setOnlyNewSinceNow() async {
    final now = DateTime.now().microsecondsSinceEpoch;
    if (now <= 0) {
      _logger.severe("Invalid timestamp for only-new backup: $now");
      return;
    }
    _logger.info("Setting only-new backup threshold to $now");
    await _localSettings.setOnlyNewSinceEpoch(now);
  }
}
