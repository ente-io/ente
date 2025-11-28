import "dart:async";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photo_manager/photo_manager.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/permission_granted_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/services/sync/sync_service.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/dialog_util.dart";
import 'package:photos/utils/standalone/debouncer.dart';
import "package:styled_text/styled_text.dart";

class GrantPermissionsWidget extends StatefulWidget {
  const GrantPermissionsWidget({super.key});

  @override
  State<GrantPermissionsWidget> createState() => _GrantPermissionsWidgetState();
}

class _GrantPermissionsWidgetState extends State<GrantPermissionsWidget> {
  final Logger _logger = Logger("_GrantPermissionsWidgetState");
  final bool _showOnlyNewFeature = flagService.enableOnlyBackupFuturePhotos;
  final Debouncer _onlyNewActionDebouncer = Debouncer(
    const Duration(milliseconds: 500),
    leading: true,
  );

  @override
  void dispose() {
    _onlyNewActionDebouncer.cancelDebounceTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final headerText = _getHeaderText(context);
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
      floatingActionButton: _showOnlyNewFeature
          ? _buildNewFeatureActionArea(context)
          : Container(
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
              child: OutlinedButton(
                key: const ValueKey("grantPermissionButton"),
                onPressed: _onTapSelectFolders,
                child: Text(AppLocalizations.of(context).continueLabel),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _onTapOnlyNewPhotos() async {
    try {
      final state = await permissionService.requestPhotoMangerPermissions();
      _logger.info("Permission state: $state");
      if (state == PermissionState.authorized ||
          state == PermissionState.limited) {
        await backupPreferenceService.setOnlyNewSinceSevenDaysAgo();
        await onPermissionGranted(
          state,
          shouldMarkLimitedFolders: false,
        );
        if (mounted) {
          showToast(context, "Backing up last 7 day's photos");
        }
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
    await backupPreferenceService.setOnboardingPermissionSkipped(true);
    SyncService.instance.sync().ignore();
    if (mounted) {
      setState(() {});
    }
    Bus.instance.fire(PermissionGrantedEvent());
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
    await backupPreferenceService.setOnboardingPermissionSkipped(false);
    if (shouldMarkLimitedFolders && state == PermissionState.limited) {
      // when limited permission is granted, by default mark all folders for
      // backup
      await backupPreferenceService.setSelectAllFoldersForBackup(true);
    }
    SyncService.instance.onPermissionGranted().ignore();
    Bus.instance.fire(PermissionGrantedEvent());
  }

  String _getHeaderText(BuildContext context) {
    if (flagService.enableOnlyBackupFuturePhotos) {
      return "<i>Choose how </i>Ente backs up your photos";
    } else {
      return AppLocalizations.of(context).entePhotosPerm;
    }
  }

  Widget _buildNewFeatureActionArea(BuildContext context) {
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
              onPressed: () => _onlyNewActionDebouncer.run(() async {
                await _onTapOnlyNewPhotos();
              }),
              child: const Text("Start with latest backups"),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const ValueKey("selectFoldersButton"),
              onPressed: _onTapSelectFolders,
              child: const Text("Select folders"),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            key: const ValueKey("skipForNowButton"),
            behavior: HitTestBehavior.opaque,
            onTap: _onTapSkip,
            child: Text(
              "Skip",
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
}
