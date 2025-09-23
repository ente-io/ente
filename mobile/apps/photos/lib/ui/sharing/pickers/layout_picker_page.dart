import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/web_page.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/separators_util.dart';
import 'package:tuple/tuple.dart';

class LayoutPickerPage extends StatelessWidget {
  final Collection collection;
  const LayoutPickerPage(this.collection, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).albumLayout,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 3.0),
            child: IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () async {
                await _openPublicAlbumPreview(context);
              },
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        child: ItemsWidget(collection),
                      ),
                    ],
                  ),
                );
              },
              childCount: 1,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.symmetric(vertical: 12)),
        ],
      ),
    );
  }

  Future<void> _openPublicAlbumPreview(BuildContext context) async {
    try {
      final String publicUrl =
          CollectionsService.instance.getPublicUrl(collection);
      await routeToPage(
        context,
        WebPage(
          AppLocalizations.of(context).preview,
          publicUrl,
          canOpenInBrowser: false,
        ),
      );
    } catch (e) {
      await showGenericErrorDialog(context: context, error: e);
    }
  }
}

class ItemsWidget extends StatefulWidget {
  final Collection collection;
  const ItemsWidget(this.collection, {super.key});

  @override
  State<ItemsWidget> createState() => _ItemsWidgetState();
}

class _ItemsWidgetState extends State<ItemsWidget> {
  late String currentLayout;
  late final List<Tuple2<String, String>> _layoutOptions = [
    Tuple2(AppLocalizations.of(context).layoutGrouped, "grouped"),
    Tuple2(AppLocalizations.of(context).layoutContinuous, "continuous"),
    Tuple2(AppLocalizations.of(context).layoutTrip, "trip"),
  ];

  @override
  void initState() {
    currentLayout = widget.collection.pubMagicMetadata.layout ?? 'grouped';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    for (Tuple2<String, String> layoutOption in _layoutOptions) {
      items.add(
        _menuItemForPicker(context, layoutOption),
      );
    }
    items = addSeparators(
      items,
      DividerWidget(
        dividerType: DividerType.menuNoIcon,
        bgColor: getEnteColorScheme(context).fillFaint,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }

  Widget _menuItemForPicker(
    BuildContext context,
    Tuple2<String, String> layoutOption,
  ) {
    return MenuItemWidget(
      menuItemColor: getEnteColorScheme(context).fillFaint,
      captionedTextWidget: CaptionedTextWidget(
        title: layoutOption.item1,
      ),
      trailingIcon: currentLayout == layoutOption.item2 ? Icons.check : null,
      trailingIconColor: currentLayout == layoutOption.item2
          ? getEnteColorScheme(context).primary500
          : null,
      alignCaptionedTextToLeft: true,
      isTopBorderRadiusRemoved: true,
      isBottomBorderRadiusRemoved: true,
      alwaysShowSuccessState: true,
      onTap: () async {
        await updateLayout(layoutOption.item2, context);
      },
    );
  }

  Future<void> updateLayout(String newLayout, BuildContext context) async {
    await _updateLayoutSettings(
      context,
      {'layout': newLayout},
    ).then(
      (value) => setState(() {
        currentLayout = newLayout;
      }),
    );
  }

  Future<void> _updateLayoutSettings(
    BuildContext context,
    Map<String, dynamic> prop,
  ) async {
    try {
      await CollectionsService.instance
          .updatePublicMagicMetadata(widget.collection, prop);
    } catch (e) {
      await showGenericErrorDialog(context: context, error: e);
      rethrow;
    }
  }
}
