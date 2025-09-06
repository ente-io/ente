import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/utils/separators_util.dart';

class PhotoGridSizePickerPage extends StatelessWidget {
  const PhotoGridSizePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).photoGridSize,
            ),
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
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        child: ItemsWidget(),
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
}

class ItemsWidget extends StatefulWidget {
  const ItemsWidget({super.key});

  @override
  State<ItemsWidget> createState() => _ItemsWidgetState();
}

class _ItemsWidgetState extends State<ItemsWidget> {
  late int currentGridSize;
  List<Widget> items = [];
  final List<int> gridSizes = [];
  @override
  void initState() {
    currentGridSize = localSettings.getPhotoGridSize();
    for (int gridSize = photoGridSizeMin;
        gridSize <= photoGridSizeMax;
        gridSize++) {
      gridSizes.add(gridSize);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    items.clear();
    for (int girdSize in gridSizes) {
      items.add(
        _menuItemForPicker(girdSize),
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

  Widget _menuItemForPicker(int gridSize) {
    return MenuItemWidget(
      key: ValueKey(gridSize),
      menuItemColor: getEnteColorScheme(context).fillFaint,
      captionedTextWidget: CaptionedTextWidget(
        title: "$gridSize",
      ),
      trailingIcon: currentGridSize == gridSize ? Icons.check : null,
      alignCaptionedTextToLeft: true,
      isTopBorderRadiusRemoved: true,
      isBottomBorderRadiusRemoved: true,
      showOnlyLoadingState: true,
      onTap: () async {
        await localSettings.setPhotoGridSize(gridSize).then(
              (value) => setState(() {
                currentGridSize = gridSize;
              }),
            );
        Bus.instance.fire(
          ForceReloadHomeGalleryEvent("grid size changed"),
        );
      },
    );
  }
}
