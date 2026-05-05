import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/permission_granted_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/backup_flow_helper.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/tabs/albums/empty_states/albums_empty_state_feature_row.dart";

class OnDeviceSelectFoldersEmptyState extends StatelessWidget {
  const OnDeviceSelectFoldersEmptyState({super.key});

  static Future<bool> shouldShow() async {
    if (backupPreferenceService.hasSkippedOnboardingPermission) {
      return true;
    }

    final state = await permissionService.getPermissionState();
    final hasAccess =
        state == PermissionState.authorized || state == PermissionState.limited;
    if (hasAccess && !permissionService.hasGrantedPermissions()) {
      await permissionService.onUpdatePermission(state);
      Bus.instance.fire(PermissionGrantedEvent());
    }
    return !hasAccess;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final strings = AppLocalizations.of(context);
    final bottomPadding = 64 + MediaQuery.paddingOf(context).bottom + 32;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 32, 16, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  Text(
                    strings.allowAccessToYourPhotos,
                    textAlign: TextAlign.center,
                    style: textTheme.largeBold.copyWith(
                      fontFamily: "Nunito",
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 28 / 18,
                      color: colorScheme.content,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.enteNeedsPermissionToSeeDeviceAlbums,
                    textAlign: TextAlign.center,
                    style: textTheme.miniMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  AlbumsEmptyStateFeatureRow(
                    icon: HugeIcons.strokeRoundedFolder02,
                    label: strings.allYourDeviceAlbumsInOnePlace,
                  ),
                  const SizedBox(height: 24),
                  AlbumsEmptyStateFeatureRow(
                    icon: HugeIcons.strokeRoundedCloudSavingDone01,
                    label: strings.youPickWhatGetsBackedUp,
                  ),
                  const SizedBox(height: 24),
                  AlbumsEmptyStateFeatureRow(
                    icon: HugeIcons.strokeRoundedLockSync01,
                    label: strings.privateAndEndToEndEncryptedAlways,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ButtonWidgetV2(
              buttonType: ButtonTypeV2.primary,
              labelText: strings.selectFolders,
              onTap: () => _selectFolders(context),
              shouldSurfaceExecutionStates: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFolders(BuildContext context) async {
    await handleFolderSelectionBackupFlow(context);
  }
}
