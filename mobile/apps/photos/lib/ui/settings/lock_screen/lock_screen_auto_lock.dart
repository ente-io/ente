import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/utils/lock_screen_settings.dart";
import "package:photos/utils/separators_util.dart";

class LockScreenAutoLock extends StatefulWidget {
  const LockScreenAutoLock({super.key});

  @override
  State<LockScreenAutoLock> createState() => _LockScreenAutoLockState();
}

class _LockScreenAutoLockState extends State<LockScreenAutoLock> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: AppLocalizations.of(context).autoLock,
            ),
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
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            child: AutoLockItems(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class AutoLockItems extends StatefulWidget {
  const AutoLockItems({super.key});

  @override
  State<AutoLockItems> createState() => _AutoLockItemsState();
}

class _AutoLockItemsState extends State<AutoLockItems> {
  final autoLockDurations = LockScreenSettings.autoLockDurations;
  final autoLockTimeInMilliseconds =
      LockScreenSettings.instance.getAutoLockTime();
  List<Widget> items = [];
  late Duration currentAutoLockTime;
  @override
  void initState() {
    super.initState();
    for (Duration autoLockDuration in autoLockDurations) {
      if (autoLockDuration.inMilliseconds == autoLockTimeInMilliseconds) {
        currentAutoLockTime = autoLockDuration;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    items.clear();
    for (Duration autoLockDuration in autoLockDurations) {
      items.add(
        _menuItemForPicker(autoLockDuration),
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

  Widget _menuItemForPicker(Duration autoLockTime) {
    return MenuItemWidget(
      key: ValueKey(autoLockTime),
      menuItemColor: getEnteColorScheme(context).fillFaint,
      captionedTextWidget: CaptionedTextWidget(
        title: _formatTime(autoLockTime),
      ),
      trailingIcon: currentAutoLockTime == autoLockTime ? Icons.check : null,
      alignCaptionedTextToLeft: true,
      isTopBorderRadiusRemoved: true,
      isBottomBorderRadiusRemoved: true,
      showOnlyLoadingState: true,
      onTap: () async {
        await LockScreenSettings.instance.setAutoLockTime(autoLockTime).then(
              (value) => {
                setState(() {
                  currentAutoLockTime = autoLockTime;
                }),
              },
            );
      },
    );
  }

  String _formatTime(Duration duration) {
    if (duration.inHours != 0) {
      return "${duration.inHours}hr";
    } else if (duration.inMinutes != 0) {
      return "${duration.inMinutes}m";
    } else if (duration.inSeconds != 0) {
      return "${duration.inSeconds}s";
    } else {
      return "Immediately";
    }
  }
}
