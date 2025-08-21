import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/tab_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/collections/collection_action_sheet.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/empty_state_item_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/collection_util.dart";
import "package:photos/utils/share_util.dart";

class SharedEmptyStateWidget extends StatelessWidget {
  const SharedEmptyStateWidget({super.key});

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
                      AppLocalizations.of(context).privateSharing,
                      style: textTheme.h3Bold,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 24),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyStateItemWidget(
                          AppLocalizations.of(context)
                              .shareOnlyWithThePeopleYouWant,
                        ),
                        const SizedBox(height: 12),
                        EmptyStateItemWidget(
                          AppLocalizations.of(context)
                              .usePublicLinksForPeopleNotOnEnte,
                        ),
                        const SizedBox(height: 12),
                        EmptyStateItemWidget(
                          AppLocalizations.of(context).allowPeopleToAddPhotos,
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
                      labelText: AppLocalizations.of(context).shareAnAlbumNow,
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
                      labelText:
                          AppLocalizations.of(context).collectEventPhotos,
                      icon: Icons.add_photo_alternate_outlined,
                      onTap: () async {
                        await onTapCollectEventPhotos(context);
                      },
                    ),
                    const SizedBox(height: 6),
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconSecondary,
                      labelText: AppLocalizations.of(context).inviteYourFriends,
                      icon: Icons.ios_share_outlined,
                      onTap: () async {
                        // ignore: unawaited_futures
                        shareText(
                          AppLocalizations.of(context)
                              .shareTextRecommendUsingEnte,
                        );
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

class OutgoingAlbumEmptyState extends StatelessWidget {
  const OutgoingAlbumEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.collections_outlined,
                color: getEnteColorScheme(context).strokeMuted,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).noAlbumsSharedByYouYet,
                style: getEnteTextTheme(context).bodyMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          child: ButtonWidget(
            buttonType: ButtonType.trailingIconPrimary,
            labelText: AppLocalizations.of(context).shareYourFirstAlbum,
            icon: Icons.add,
            onTap: () async {
              showToast(
                context,
                AppLocalizations.of(context).shareAlbumHint,
              );
              Bus.instance.fire(
                TabChangedEvent(1, TabChangedEventSource.collectionsPage),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class IncomingAlbumEmptyState extends StatelessWidget {
  const IncomingAlbumEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.collections_outlined,
                color: getEnteColorScheme(context).strokeMuted,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).nothingSharedWithYouYet,
                style: getEnteTextTheme(context).bodyMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          child: ButtonWidget(
            buttonType: ButtonType.trailingIconPrimary,
            labelText: AppLocalizations.of(context).inviteYourFriends,
            icon: Icons.ios_share_outlined,
            onTap: () async {
              // ignore: unawaited_futures
              shareText(
                AppLocalizations.of(context).shareTextRecommendUsingEnte,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
