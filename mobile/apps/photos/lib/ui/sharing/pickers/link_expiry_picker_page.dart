import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/viewer/date/date_time_picker.dart";
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/separators_util.dart';
import 'package:tuple/tuple.dart';

class LinkExpiryPickerPage extends StatelessWidget {
  final Collection collection;
  const LinkExpiryPickerPage(this.collection, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: S.of(context).linkExpiry,
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
  // index, title, milliseconds in future post which link should expire (when >0)
  late final List<Tuple2<String, int>> _expiryOptions = [
    Tuple2(S.of(context).never, 0),
    Tuple2(S.of(context).after1Hour, const Duration(hours: 1).inMicroseconds),
    Tuple2(S.of(context).after1Day, const Duration(days: 1).inMicroseconds),
    Tuple2(S.of(context).after1Week, const Duration(days: 7).inMicroseconds),
    // todo: make this time calculation perfect
    Tuple2(S.of(context).after1Month, const Duration(days: 30).inMicroseconds),
    Tuple2(S.of(context).after1Year, const Duration(days: 365).inMicroseconds),
    Tuple2(S.of(context).custom, -1),
  ];

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    for (Tuple2<String, int> expiryOpiton in _expiryOptions) {
      items.add(
        _menuItemForPicker(context, expiryOpiton),
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
    Tuple2<String, int> expiryOpiton,
  ) {
    return MenuItemWidget(
      menuItemColor: getEnteColorScheme(context).fillFaint,
      captionedTextWidget: CaptionedTextWidget(
        title: expiryOpiton.item1,
      ),
      alignCaptionedTextToLeft: true,
      isTopBorderRadiusRemoved: true,
      isBottomBorderRadiusRemoved: true,
      alwaysShowSuccessState: true,
      surfaceExecutionStates: expiryOpiton.item2 == -1 ? false : true,
      onTap: () async {
        int newValidTill = -1;
        final int expireAfterInMicroseconds = expiryOpiton.item2;
        // need to manually select time
        if (expireAfterInMicroseconds < 0) {
          final now = DateTime.now();
          final DateTime? picked = await showDatePickerSheet(
            context,
            initialDate: now,
            minDate: now,
          );
          final timeInMicrosecondsFromEpoch = picked?.microsecondsSinceEpoch;
          if (timeInMicrosecondsFromEpoch != null) {
            newValidTill = timeInMicrosecondsFromEpoch;
          }
        } else if (expireAfterInMicroseconds == 0) {
          // no expiry
          newValidTill = 0;
        } else {
          newValidTill =
              DateTime.now().microsecondsSinceEpoch + expireAfterInMicroseconds;
        }
        if (newValidTill >= 0) {
          debugPrint(
            "Setting expire date to  ${DateTime.fromMicrosecondsSinceEpoch(newValidTill)}",
          );
          await updateTime(newValidTill, context);
        }
      },
    );
  }

  Future<void> updateTime(int newValidTill, BuildContext context) async {
    await _updateUrlSettings(
      context,
      {'validTill': newValidTill},
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
