import "package:flutter/material.dart";
import "package:photo_manager/photo_manager.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/sync/local_sync_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/empty_state_item_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/home/loading_photos_widget.dart";
import "package:photos/ui/settings/backup/backup_folder_selection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

class SearchTabEmptyState extends StatelessWidget {
  const SearchTabEmptyState({super.key});

  Future<void> _handleAddPhotos(BuildContext context) async {
    final state = await permissionService.requestPhotoMangerPermissions();
    if (state == PermissionState.authorized ||
        state == PermissionState.limited) {
      await permissionService.onUpdatePermission(state);
      if (context.mounted) {
        // If first import hasn't completed, show LoadingPhotosWidget
        // which will wait for sync and then navigate to BackupFolderSelectionPage
        if (!LocalSyncService.instance.hasCompletedFirstImport()) {
          await routeToPage(
            context,
            const LoadingPhotosWidget(),
          );
        } else {
          await routeToPage(
            context,
            const BackupFolderSelectionPage(
              isFirstBackup: false,
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        await showChoiceDialog(
          context,
          title: context.l10n.allowPermTitle,
          body: context.l10n.allowPermBody,
          firstButtonLabel: context.l10n.openSettings,
          firstButtonOnTap: () async {
            await PhotoManager.openSetting();
          },
        );
        // Re-check permissions after dialog is dismissed
        if (context.mounted) {
          await _handleAddPhotos(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = getEnteTextTheme(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).searchHint1,
              style: textStyle.h3Bold,
            ),
            const SizedBox(height: 24),
            EmptyStateItemWidget(AppLocalizations.of(context).searchHint2),
            const SizedBox(height: 12),
            EmptyStateItemWidget(AppLocalizations.of(context).searchHint3),
            const SizedBox(height: 12),
            EmptyStateItemWidget(AppLocalizations.of(context).searchHint4),
            const SizedBox(height: 12),
            EmptyStateItemWidget(AppLocalizations.of(context).searchHint5),
            const SizedBox(height: 32),
            ButtonWidget(
              buttonType: ButtonType.trailingIconPrimary,
              labelText: AppLocalizations.of(context).addYourPhotosNow,
              icon: Icons.arrow_forward_outlined,
              onTap: () async {
                await _handleAddPhotos(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
