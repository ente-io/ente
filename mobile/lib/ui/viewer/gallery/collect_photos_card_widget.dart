import "package:figma_squircle/figma_squircle.dart";
import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

class CollectPhotosCardWidget extends StatefulWidget {
  const CollectPhotosCardWidget({super.key});

  @override
  State<CollectPhotosCardWidget> createState() =>
      _CollectPhotosCardWidgetState();
}

class _CollectPhotosCardWidgetState extends State<CollectPhotosCardWidget> {
  Future<void> _onTapCreateAlbum() async {
    final String currentDate =
        DateFormat('MMMM d, yyyy').format(DateTime.now());
    final result = await showTextInputDialog(
      context,
      title: "Name the album",
      submitButtonLabel: S.of(context).create,
      hintText: S.of(context).enterAlbumName,
      alwaysShowSuccessState: false,
      initialValue: currentDate,
      textCapitalization: TextCapitalization.words,
      onSubmit: (String text) async {
        // indicates user cancelled the rename request
        if (text.trim() == "") {
          return;
        }

        try {
          final Collection c =
              await CollectionsService.instance.createAlbum(text);
          // ignore: unawaited_futures
          routeToPage(
            context,
            CollectionPage(
              isFromCollectPhotos: true,
              CollectionWithThumbnail(c, null),
            ),
          );
        } catch (e, s) {
          Logger("CollectPhotosCardWidget")
              .severe("Failed to rename album", e, s);
          rethrow;
        }
      },
    );
    if (result is Exception) {
      await showGenericErrorDialog(context: context, error: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorTheme = getEnteColorScheme(context);
    return Stack(
      children: [
        Positioned(
          bottom: 22.5,
          left: 14.5,
          child: Container(
            height: 125,
            width: 125,
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                colors: [
                  colorTheme.primary700.withOpacity(0.9),
                  colorTheme.backdropBase.withOpacity(0.6),
                  colorTheme.backdropBase,
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 12.0,
                  cornerSmoothing: 1.0,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _onTapCreateAlbum(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Container(
              decoration: ShapeDecoration(
                color: colorTheme.backgroundElevated,
                shadows: [
                  BoxShadow(
                    color: colorTheme.textBase.withOpacity(0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 1),
                  ),
                ],
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 10.0,
                    cornerSmoothing: 1.0,
                  ),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Collect photos",
                      style: textTheme.bodyBold,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      "Create a link where your friends can upload photos in original quality.",
                      style: textTheme.smallMuted,
                    ),
                    const SizedBox(
                      height: 34,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ButtonWidget(
                          buttonType: ButtonType.primary,
                          buttonSize: ButtonSize.small,
                          labelText: "Collect",
                          icon: Icons.add_photo_alternate_outlined,
                          shouldShowSuccessConfirmation: false,
                          shouldSurfaceExecutionStates: false,
                          onTap: () => _onTapCreateAlbum(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 16,
          child: Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.only(bottomLeft: Radius.circular(10)),
              gradient: LinearGradient(
                colors: [
                  colorTheme.primary700.withOpacity(0.4),
                  colorTheme.backgroundElevated.withOpacity(0.6),
                  colorTheme.backgroundElevated,
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 25,
          left: 20,
          child: SizedBox(
            child: Image.asset('assets/create_new_album.png'),
          ),
        ),
      ],
    );
  }
}
