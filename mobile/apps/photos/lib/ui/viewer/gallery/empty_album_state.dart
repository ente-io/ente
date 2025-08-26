import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/album/smart_album_people.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/gallery/hooks/add_photos_sheet.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

class EmptyAlbumState extends StatelessWidget {
  final Collection c;
  final bool isFromCollectPhotos;
  final VoidCallback? onAddPhotos;

  const EmptyAlbumState(
    this.c, {
    super.key,
    this.isFromCollectPhotos = false,
    this.onAddPhotos,
  });

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    return isFromCollectPhotos
        ? Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: 0.5,
                  child: isLightMode
                      ? Image.asset('assets/new_empty_album.png')
                      : Image.asset('assets/new_empty_album_dark.png'),
                ),
              ),
            ],
          )
        : Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/albums-widget-static.png",
                      height: 160,
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        text: AppLocalizations.of(context).addSomePhotosDesc1,
                        children: [
                          TextSpan(
                            text:
                                AppLocalizations.of(context).addSomePhotosDesc2,
                            style: TextStyle(
                              color: getEnteColorScheme(context).primary500,
                            ),
                          ),
                          TextSpan(
                            text:
                                AppLocalizations.of(context).addSomePhotosDesc3,
                          ),
                        ],
                      ),
                      style: getEnteTextTheme(context).smallMuted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ButtonWidget(
                      buttonType: ButtonType.primary,
                      buttonSize: ButtonSize.large,
                      labelText: AppLocalizations.of(context).addPhotos,
                      icon: Icons.add_photo_alternate_outlined,
                      shouldSurfaceExecutionStates: false,
                      onTap: () async {
                        try {
                          await showAddPhotosSheet(context, c);
                        } catch (e) {
                          await showGenericErrorDialog(
                            context: context,
                            error: e,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ButtonWidget(
                      buttonType: ButtonType.neutral,
                      buttonSize: ButtonSize.large,
                      iconWidget: Image.asset(
                        'assets/auto-add-people.png',
                        width: 24,
                        height: 24,
                        color: isLightMode ? Colors.white : Colors.black,
                      ),
                      labelText: AppLocalizations.of(context).autoAddPeople,
                      shouldSurfaceExecutionStates: false,
                      onTap: () async {
                        await routeToPage(
                          context,
                          SmartAlbumPeople(collectionId: c.id),
                        );
                        onAddPhotos?.call();
                      },
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          );
  }
}
