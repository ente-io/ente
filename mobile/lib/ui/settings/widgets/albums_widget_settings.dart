import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/services/album_home_widget_service.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/favorites_service.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/collections/flex_grid_view.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';

class AlbumsWidgetSettings extends StatefulWidget {
  const AlbumsWidgetSettings({super.key});

  @override
  State<AlbumsWidgetSettings> createState() => _AlbumsWidgetSettingsState();
}

class _AlbumsWidgetSettingsState extends State<AlbumsWidgetSettings> {
  final _selectedAlbums = SelectedAlbums();
  bool hasInstalledAny = false;
  Set<Collection> _albums = {};

  @override
  void initState() {
    super.initState();
    _selectedAlbums.addListener(_selectedAlbumsListener);
    checkIfAnyWidgetInstalled();
    selectExisting();
  }

  void _selectedAlbumsListener() {
    _albums = _selectedAlbums.albums;
    setState(() {});
  }

  Future<void> checkIfAnyWidgetInstalled() async {
    final count = await AlbumHomeWidgetService.instance.countHomeWidgets();
    setState(() {
      hasInstalledAny = count > 0;
    });
  }

  Future<void> selectExisting() async {
    final selectedAlbums = AlbumHomeWidgetService.instance.getSelectedAlbums();
    final albums = <Collection>{};

    if (selectedAlbums != null) {
      for (final collectionID in selectedAlbums) {
        final collection =
            CollectionsService.instance.getCollectionByID(collectionID);

        if (collection != null) {
          albums.add(collection);
        }
      }
    }

    if (albums.isEmpty) {
      final favorites =
          await FavoritesService.instance.getFavoritesCollection();

      if (favorites == null) {
        return;
      }

      albums.add(favorites);
    }

    _selectedAlbums.select(albums);
  }

  @override
  void dispose() {
    _selectedAlbums.removeListener(_selectedAlbumsListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      bottomNavigationBar: hasInstalledAny
          ? Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                8 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: ButtonWidget(
                buttonType: ButtonType.primary,
                buttonSize: ButtonSize.large,
                labelText: S.of(context).save,
                shouldSurfaceExecutionStates: false,
                onTap: _albums.isNotEmpty
                    ? () async {
                        final albums =
                            _albums.map((e) => e.id.toString()).toList();
                        await AlbumHomeWidgetService.instance
                            .setSelectedAlbums(albums);
                        // TODO: Run sync
                        // await AlbumHomeWidgetService.instance.updateWidget();
                        Navigator.pop(context);
                      }
                    : null,
                isDisabled: _albums.isEmpty,
              ),
            )
          : null,
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).albums,
            ),
            expandedHeight: 120,
            flexibleSpaceCaption: S.of(context).albumsWidgetDesc,
            actionIcons: [
              IconButtonWidget(
                icon: Icons.close_outlined,
                iconButtonType: IconButtonType.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          if (!hasInstalledAny)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.5 - 300,
                    ),
                    Image.asset(
                      "assets/albums-widget-static.png",
                      height: 160,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Add an album widget to your homescreen and come back here to customize",
                      style: textTheme.largeFaint,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            FutureBuilder<List<Collection>>(
              future:
                  CollectionsService.instance.getCollectionForOnEnteSection(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return CollectionsFlexiGridViewWidget(
                    snapshot.data!,
                    displayLimitCount: snapshot.data!.length,
                    shrinkWrap: true,
                    selectedAlbums: _selectedAlbums,
                    shouldShowCreateAlbum: false,
                    enableSelectionMode: true,
                  );
                } else if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Text(snapshot.error.toString()),
                  );
                } else {
                  return const SliverToBoxAdapter(child: EnteLoadingWidget());
                }
              },
            ),
        ],
      ),
    );
  }
}
