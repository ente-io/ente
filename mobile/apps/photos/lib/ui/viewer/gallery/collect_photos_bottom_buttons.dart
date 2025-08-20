import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/gallery/hooks/add_photos_sheet.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/share_util.dart";

class CollectPhotosBottomButtons extends StatefulWidget {
  final Collection c;
  final SelectedFiles? selectedFiles;
  const CollectPhotosBottomButtons(
    this.c, {
    super.key,
    this.selectedFiles,
  });

  @override
  State<CollectPhotosBottomButtons> createState() => _EmptyAlbumStateNewState();
}

class _EmptyAlbumStateNewState extends State<CollectPhotosBottomButtons> {
  final ValueNotifier<bool> _hasSelectedFilesNotifier = ValueNotifier(false);
  final GlobalKey shareLinkAlbumButtonKey = GlobalKey();
  late CollectionActions collectionActions;

  @override
  void initState() {
    super.initState();
    collectionActions = CollectionActions(CollectionsService.instance);
    widget.selectedFiles?.addListener(_selectedFilesListener);
  }

  @override
  void dispose() {
    _hasSelectedFilesNotifier.dispose();
    widget.selectedFiles!.removeListener(_selectedFilesListener);
    super.dispose();
  }

  Future<void> _shareAlbumUrl() async {
    final String url = CollectionsService.instance.getPublicUrl(widget.c);
    await shareAlbumLinkWithPlaceholder(
      context,
      widget.c,
      url,
      shareLinkAlbumButtonKey,
    );
  }

  Future<void> _generateAlbumUrl() async {
    final dialog = createProgressDialog(
      context,
      S.of(context).creatingLink,
      isDismissible: true,
    );
    await dialog.show();
    final bool hasUrl = widget.c.hasLink;
    if (hasUrl) {
      await _shareAlbumUrl();
    } else {
      final bool result = await collectionActions.enableUrl(
        context,
        widget.c,
        enableCollect: true,
      );
      if (result) {
        await _shareAlbumUrl();
      } else {
        await showGenericErrorDialog(context: context, error: result);
      }
    }
    await dialog.hide();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder(
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
            firstChild: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: getEnteColorScheme(context).strokeFaint,
                  ),
                ),
                color: getEnteColorScheme(context).backgroundElevated,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: getEnteColorScheme(context).backgroundElevated2,
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
                    const SizedBox(height: 8),
                    ButtonWidget(
                      buttonType: ButtonType.primary,
                      buttonSize: ButtonSize.large,
                      labelText: S.of(context).share,
                      icon: Icons.adaptive.share,
                      shouldSurfaceExecutionStates: false,
                      onTap: () async {
                        await _generateAlbumUrl();
                      },
                    ),
                  ],
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  _selectedFilesListener() {
    _hasSelectedFilesNotifier.value = widget.selectedFiles!.files.isNotEmpty;
  }
}
