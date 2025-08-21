import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/separators_util.dart';

class DeviceLimitPickerPage extends StatelessWidget {
  final Collection collection;
  const DeviceLimitPickerPage(this.collection, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).linkDeviceLimit,
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
  late int initialDeviceLimit;
  List<Widget> items = [];
  bool isCustomLimit = false;
  @override
  void initState() {
    currentDeviceLimit = widget.collection.publicURLs.first.deviceLimit;
    initialDeviceLimit = currentDeviceLimit;
    if (!publicLinkDeviceLimits.contains(currentDeviceLimit)) {
      isCustomLimit = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    items.clear();
    if (isCustomLimit) {
      items.add(
        _menuItemForPicker(initialDeviceLimit),
      );
    }
    for (int deviceLimit in publicLinkDeviceLimits) {
      items.add(
        _menuItemForPicker(deviceLimit),
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

  Widget _menuItemForPicker(int deviceLimit) {
    return MenuItemWidget(
      key: ValueKey(deviceLimit),
      menuItemColor: getEnteColorScheme(context).fillFaint,
      captionedTextWidget: CaptionedTextWidget(
        title: deviceLimit == 0
            ? AppLocalizations.of(context).noDeviceLimit
            : "$deviceLimit",
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
    );
  }

  Future<void> _updateUrlSettings(
    BuildContext context,
    Map<String, dynamic> prop,
  ) async {
    try {
      await CollectionsService.instance.updateShareUrl(widget.collection, prop);
    } catch (e) {
      await showGenericErrorDialog(context: context, error: e);
      rethrow;
    }
  }
}
