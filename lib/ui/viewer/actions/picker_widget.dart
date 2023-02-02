import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/separators_util.dart';

class PickerWidget extends StatelessWidget {
  final Collection collection;
  const PickerWidget(this.collection, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          const TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: "Device Limit",
            ),
          ),
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
                      const MenuSectionDescriptionWidget(
                        content:
                            "When set to the maximum (50), the device limit will be relaxed"
                            " to allow for temporary spikes of large number of viewers.",
                      )
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
  final Collection collection;
  const ItemsWidget(this.collection, {super.key});

  @override
  State<ItemsWidget> createState() => _ItemsWidgetState();
}

class _ItemsWidgetState extends State<ItemsWidget> {
  late int currentDeviceLimit;
  List<Widget> items = [];
  bool isCustomLimit = false;
  @override
  void initState() {
    currentDeviceLimit = widget.collection.publicURLs!.first!.deviceLimit;
    if (!deviceLimits.contains(currentDeviceLimit)) {
      isCustomLimit = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    items.clear();
    if (isCustomLimit) {
      items.add(
        MenuItemWidget(
          key: ValueKey(currentDeviceLimit),
          menuItemColor: getEnteColorScheme(context).fillFaint,
          captionedTextWidget: CaptionedTextWidget(
            title: "$currentDeviceLimit",
          ),
          trailingIcon: Icons.check,
          alignCaptionedTextToLeft: true,
          isTopBorderRadiusRemoved: true,
          isBottomBorderRadiusRemoved: true,
        ),
      );
      isCustomLimit = false;
    }
    for (int deviceLimit in deviceLimits) {
      items.add(
        MenuItemWidget(
          key: ValueKey(deviceLimit),
          menuItemColor: getEnteColorScheme(context).fillFaint,
          captionedTextWidget: CaptionedTextWidget(
            title: "$deviceLimit",
          ),
          trailingIcon: currentDeviceLimit == deviceLimit ? Icons.check : null,
          alignCaptionedTextToLeft: true,
          isTopBorderRadiusRemoved: true,
          isBottomBorderRadiusRemoved: true,
          showOnlyLoadingState: true,
          onTap: () async {
            await _updateUrlSettings(context, {
              'deviceLimit': deviceLimit,
            }).then(
              (value) => setState(() {
                currentDeviceLimit = deviceLimit;
              }),
            );
          },
        ),
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

  Future<void> _updateUrlSettings(
    BuildContext context,
    Map<String, dynamic> prop,
  ) async {
    try {
      await CollectionsService.instance.updateShareUrl(widget.collection, prop);
    } catch (e) {
      showGenericErrorDialog(context: context);
      rethrow;
    }
  }
}
