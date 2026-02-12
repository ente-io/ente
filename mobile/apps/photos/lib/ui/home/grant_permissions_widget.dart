import "dart:async";

import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
import "package:logging/logging.dart";
import 'package:photo_manager/photo_manager.dart';
import "package:photos/app_mode.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/events/permission_granted_event.dart";
import "package:photos/generated/intl/app_localizations.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/ml_service.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import 'package:photos/services/sync/sync_service.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/gradient_button.dart";
import "package:photos/ui/components/alert_bottom_sheet.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/dialog_util.dart";
import "package:styled_text/styled_text.dart";

class GrantPermissionsWidget extends StatefulWidget {
  const GrantPermissionsWidget({
    super.key,
    this.startWithoutAccount = false,
  });

  final bool startWithoutAccount;

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
    if (widget.startWithoutAccount) {
      return _buildOfflinePermissionScreen(context);
    }

    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final headerText = _getHeaderText(context);

    if (_showOnlyNewFeature) {
      return Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 44),
                sliver: SliverToBoxAdapter(
                  child: _buildHeaderContent(context, isLightMode, headerText),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 36, bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildNewFeatureActionArea(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 120),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildHeaderContent(context, isLightMode, headerText),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
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

  Widget _buildHeaderContent(
    BuildContext context,
    bool isLightMode,
    String headerText,
  ) {
    return Column(
      children: [
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
          showToast(context, context.l10n.backingUpLastSevenDaysPhotos);
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

  Future<void> _onTapOfflineGrantPermission() async {
    try {
      final state = await permissionService.requestPhotoMangerPermissions();
      _logger.info("Offline permission state: $state");
      if (state == PermissionState.authorized ||
          state == PermissionState.limited) {
        await localSettings.setAppMode(AppMode.offline);
        await permissionService.onUpdatePermission(state);
        Bus.instance.fire(PermissionGrantedEvent());
        try {
          await setMLConsent(true);
          await MLService.instance.init();
          await SemanticSearchService.instance.init();
          unawaited(MLService.instance.runAllML(force: true));
        } catch (e) {
          _logger.severe("Failed to initialize ML after permission grant", e);
        }
      } else {
        await _showPermissionDeniedDialog();
      }
    } catch (e) {
      _logger.severe(
        "Failed to request permission: ${e.toString()}",
        e,
      );
    }
  }

  Future<void> _onTapSkip() async {
    await backupPreferenceService.setOnboardingPermissionSkipped(true);
    final state = await permissionService.getPermissionState();
    if (state == PermissionState.authorized ||
        state == PermissionState.limited) {
      await permissionService.onUpdatePermission(state);
    }
    SyncService.instance.sync().ignore();
    if (mounted) {
      setState(() {});
    }
    Bus.instance.fire(PermissionGrantedEvent());
  }

  Future<void> _showPermissionDeniedDialog() async {
    await showAlertBottomSheet(
      context,
      title: context.l10n.allowPermTitle,
      message: context.l10n.allowPermBody,
      assetPath: 'assets/ducky_smart_feature.png',
      buttons: [
        ButtonWidgetV2(
          buttonType: ButtonTypeV2.primary,
          labelText: context.l10n.openSettings,
          onTap: () async {
            await PhotoManager.openSetting();
          },
        ),
      ],
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
      return context.l10n.chooseBackupModeHeader;
    } else {
      return AppLocalizations.of(context).entePhotosPerm;
    }
  }

  Widget _buildNewFeatureActionArea(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientButton(
            key: const ValueKey("selectFoldersButton"),
            onTap: _onTapSelectFolders,
            text: context.l10n.selectFolders,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey("onlyNewPhotosButton"),
              style: Theme.of(context).colorScheme.optionalActionButtonStyle,
              onPressed: () => _onlyNewActionDebouncer.run(() async {
                await _onTapOnlyNewPhotos();
              }),
              child: Text(
                context.l10n.startWithLatestPhotos,
                style: const TextStyle(
                  color: Colors.black, // same for both themes
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            key: const ValueKey("skipForNowButton"),
            behavior: HitTestBehavior.opaque,
            onTap: _onTapSkip,
            child: Text(
              context.l10n.skip,
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

  Widget _buildOfflinePermissionScreen(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildSkeletonGallery(context),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.contentReverse.withValues(alpha: 0.4),
                    colorScheme.contentReverse,
                  ],
                  stops: const [0.0, 0.55],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedMenu01,
                          size: 24,
                          color: colorScheme.strokeBase,
                        ),
                        Text(
                          "ente",
                          style: textTheme.h3Bold.copyWith(
                            fontFamily: "Montserrat",
                          ),
                        ),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedUpload01,
                          size: 24,
                          color: colorScheme.strokeBase,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.asset(
                          "assets/ducky_permission.png",
                          height: 164,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(height: 164);
                          },
                        ),
                        const SizedBox(height: 22),
                        Text(
                          AppLocalizations.of(context).welcome,
                          style: TextStyle(
                            fontFamily: "Nunito",
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                            letterSpacing: -1.4,
                            color: colorScheme.textBase,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context)
                              .grantGalleryPermissionDesc,
                          textAlign: TextAlign.center,
                          style: textTheme.body.copyWith(
                            color: colorScheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ButtonWidgetV2(
                          buttonType: ButtonTypeV2.neutral,
                          labelText:
                              AppLocalizations.of(context).grantPermission,
                          onTap: _onTapOfflineGrantPermission,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonGallery(BuildContext context) {
    const skeletonColor = Color.fromRGBO(217, 217, 217, 0.4);
    const memoryAspectRatio = 0.75;
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: topPadding + 56, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 * memoryAspectRatio,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                childAspectRatio: memoryAspectRatio,
              ),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 72,
            height: 20,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
