import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/album/smart_album_people.dart";
import "package:photos/ui/components/buttons/button_widget_v2.dart";
import "package:photos/ui/tabs/albums/empty_states/albums_empty_state_feature_row.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";

class OnEnteEmptyState extends StatelessWidget {
  const OnEnteEmptyState({super.key});

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
                    strings.organizeYourMemories,
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
                    strings.groupPhotosTheWayYouThinkAboutThem,
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
                    icon: HugeIcons.strokeRoundedLockSync01,
                    label: strings.endToEndEncryptedOnlyYourPeopleCanSeeIt,
                  ),
                  const SizedBox(height: 24),
                  AlbumsEmptyStateFeatureRow(
                    icon: HugeIcons.strokeRoundedCloudSavingDone01,
                    label: strings.backedUpSafelyAcrossDevices,
                  ),
                  const SizedBox(height: 24),
                  AlbumsEmptyStateFeatureRow(
                    icon: HugeIcons.strokeRoundedSparkles,
                    label: strings.smartAlbumsOrganizePhotosForYou,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ButtonWidgetV2(
              buttonType: ButtonTypeV2.primary,
              labelText: strings.createAlbum,
              onTap: () => _createAlbum(context),
              shouldSurfaceExecutionStates: false,
            ),
            const SizedBox(height: 8),
            ButtonWidgetV2(
              buttonType: ButtonTypeV2.secondary,
              labelText: strings.createASmartAlbum,
              onTap: () => _createSmartAlbum(context),
              shouldSurfaceExecutionStates: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<Collection?> _showCreateAlbumDialog(BuildContext context) async {
    Collection? collection;
    final result = await showTextInputDialog(
      context,
      title: AppLocalizations.of(context).newAlbum,
      submitButtonLabel: AppLocalizations.of(context).create,
      hintText: AppLocalizations.of(context).enterAlbumName,
      alwaysShowSuccessState: false,
      initialValue: "",
      textCapitalization: TextCapitalization.words,
      popnavAfterSubmission: true,
      onSubmit: (String text) async {
        final albumName = text.trim();
        if (albumName.isEmpty) {
          return;
        }
        collection = await CollectionsService.instance.createAlbum(albumName);
      },
    );

    if (result is Exception && context.mounted) {
      await showGenericErrorDialog(context: context, error: result);
    }
    return collection;
  }

  Future<void> _createAlbum(BuildContext context) async {
    final collection = await _showCreateAlbumDialog(context);
    if (collection == null || !context.mounted) {
      return;
    }
    await routeToPage(
      context,
      CollectionPage(CollectionWithThumbnail(collection, null)),
    );
  }

  Future<void> _createSmartAlbum(BuildContext context) async {
    final collection = await _showCreateAlbumDialog(context);
    if (collection == null || !context.mounted) {
      return;
    }
    await routeToPage(
      context,
      SmartAlbumPeople(collectionId: collection.id),
    );
  }
}
