import "package:fast_base58/fast_base58.dart";
import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/public_url.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/gallery/hooks/add_photos_sheet.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/share_util.dart";

class EmptyAlbumStateNew extends StatefulWidget {
  final Collection c;
  final SelectedFiles? selectedFiles;
  const EmptyAlbumStateNew(
    this.c, {
    super.key,
    this.selectedFiles,
  });

  @override
  State<EmptyAlbumStateNew> createState() => _EmptyAlbumStateNewState();
}

class _EmptyAlbumStateNewState extends State<EmptyAlbumStateNew> {
  final ValueNotifier<bool> _hasSelectedFilesNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    widget.selectedFiles?.addListener(_selectedFilesListener);
  }

  @override
  void dispose() {
    _hasSelectedFilesNotifier.dispose();
    widget.selectedFiles!.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey shareLinkAlbumButtonKey = GlobalKey();

    Future<String> getAlbumShareUrl() async {
      final PublicURL url = widget.c.publicURLs!.firstOrNull!;
      final String collectionKey = Base58Encode(
        CollectionsService.instance.getCollectionKey(widget.c.id),
      );
      return "${url.url}#$collectionKey";
    }

    return ValueListenableBuilder(
      valueListenable: _hasSelectedFilesNotifier,
      builder: (context, value, child) {
        return AnimatedCrossFade(
          firstCurve: Curves.easeInOutExpo,
          secondCurve: Curves.easeInOutExpo,
          sizeCurve: Curves.easeInOutExpo,
          duration: const Duration(milliseconds: 300),
          crossFadeState: !_hasSelectedFilesNotifier.value
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: getEnteColorScheme(context).backdropBase,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                        ),
                        child: ButtonWidget(
                          buttonType: ButtonType.secondary,
                          buttonSize: ButtonSize.large,
                          labelText: S.of(context).addPhotos,
                          icon: Icons.add_photo_alternate_outlined,
                          shouldSurfaceExecutionStates: false,
                          onTap: () async {
                            try {
                              await showAddPhotosSheet(context, widget.c);
                            } catch (e) {
                              await showGenericErrorDialog(
                                context: context,
                                error: e,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      ButtonWidget(
                        buttonType: ButtonType.primary,
                        buttonSize: ButtonSize.large,
                        labelText: S.of(context).share,
                        icon: Icons.adaptive.share,
                        shouldSurfaceExecutionStates: false,
                        onTap: () async {
                          final String shareUrl = await getAlbumShareUrl();
                          await shareAlbumLinkWithPlaceholder(
                            context,
                            widget.c,
                            shareUrl,
                            shareLinkAlbumButtonKey,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        );
      },
    );
  }

  _selectedFilesListener() {
    _hasSelectedFilesNotifier.value = widget.selectedFiles!.files.isNotEmpty;
  }
}
