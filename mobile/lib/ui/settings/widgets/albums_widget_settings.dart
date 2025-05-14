import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/services/collections_service.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/collections/flex_grid_view.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';

class AlbumsWidgetSettings extends StatelessWidget {
  const AlbumsWidgetSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return Scaffold(
      bottomNavigationBar: Padding(
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
          onTap: () async {
            // await _generateAlbumUrl();
          },
        ),
      ),
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
          if (1 != 1)
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
                    displayLimitCount: 1000000,
                    shrinkWrap: true,
                    shouldShowCreateAlbum: true,
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
