import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collection_action_sheet.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/empty_state_item_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/utils/share_util.dart";

class NewSharedCollectionsGallery extends StatelessWidget {
  const NewSharedCollectionsGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: restrictedMaxWidth),
        child: const EmptyStateWidget(),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 114),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).privateSharing,
                      style: textTheme.h3Bold,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 24),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyStateItemWidget(
                          S.of(context).shareOnlyWithThePeopleYouWant,
                        ),
                        const SizedBox(height: 12),
                        EmptyStateItemWidget(
                          S.of(context).usePublicLinksForPeopleNotOnEnte,
                        ),
                        const SizedBox(height: 12),
                        EmptyStateItemWidget(
                          S.of(context).allowPeopleToAddPhotos,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconPrimary,
                      labelText: S.of(context).shareAnAlbumNow,
                      icon: Icons.arrow_forward_outlined,
                      onTap: () async {
                        showCollectionActionSheet(
                          context,
                          actionType: CollectionActionType.shareCollection,
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconSecondary,
                      labelText: S.of(context).collectEventPhotos,
                      icon: Icons.add_photo_alternate_outlined,
                      onTap: () async {
                        showCollectionActionSheet(
                          context,
                          actionType: CollectionActionType.collectPhotos,
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconSecondary,
                      labelText: S.of(context).inviteYourFriends,
                      icon: Icons.ios_share_outlined,
                      onTap: () async {
                        shareText(S.of(context).shareTextRecommendUsingEnte);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
