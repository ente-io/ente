import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/file_share_url.dart";
import "package:photos/services/single_file_share_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/captioned_text_widget.dart";
import "package:photos/ui/components/divider_widget.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/separators_util.dart";

class SingleFileDeviceLimitPickerPage extends StatelessWidget {
  final FileShareUrl fileShareUrl;
  final Function(FileShareUrl)? onUpdate;

  const SingleFileDeviceLimitPickerPage({
    super.key,
    required this.fileShareUrl,
    this.onUpdate,
  });

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
                        child: _ItemsWidget(
                          fileShareUrl: fileShareUrl,
                          onUpdate: onUpdate,
                        ),
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

class _ItemsWidget extends StatefulWidget {
  final FileShareUrl fileShareUrl;
  final Function(FileShareUrl)? onUpdate;

  const _ItemsWidget({
    required this.fileShareUrl,
    this.onUpdate,
  });

  @override
  State<_ItemsWidget> createState() => _ItemsWidgetState();
}

class _ItemsWidgetState extends State<_ItemsWidget> {
  late int currentDeviceLimit;
  late int initialDeviceLimit;
  List<Widget> items = [];
  bool isCustomLimit = false;

  @override
  void initState() {
    currentDeviceLimit = widget.fileShareUrl.deviceLimit;
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
          "deviceLimit": deviceLimit,
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
      await SingleFileShareService.instance.updateShareUrl(
        widget.fileShareUrl.fileID,
        prop,
      );
      final updatedUrl = SingleFileShareService.instance
          .getCachedShareUrl(widget.fileShareUrl.fileID);
      if (updatedUrl != null) {
        widget.onUpdate?.call(updatedUrl);
      }
    } catch (e) {
      await showGenericErrorDialog(context: context, error: e);
      rethrow;
    }
  }
}
