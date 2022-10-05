import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';

class ExpandableMenuItemWidget extends StatefulWidget {
  final String title;
  final Widget selectionOptionsWidget;
  final IconData leadingIcon;
  const ExpandableMenuItemWidget({
    required this.title,
    required this.selectionOptionsWidget,
    required this.leadingIcon,
    Key? key,
  }) : super(key: key);

  @override
  State<ExpandableMenuItemWidget> createState() =>
      _ExpandableMenuItemWidgetState();
}

class _ExpandableMenuItemWidgetState extends State<ExpandableMenuItemWidget> {
  final expandableController = ExpandableController(initialExpanded: false);

  @override
  void dispose() {
    expandableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpandablePanel(
      header: MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          text: widget.title,
          makeTextBold: true,
        ),
        isHeaderOfExpansion: true,
        leadingIcon: widget.leadingIcon,
        trailingIcon: Icons.expand_more,
        menuItemColor:
            Theme.of(context).colorScheme.enteTheme.colorScheme.fillFaint,
        expandableController: expandableController,
      ),
      collapsed: const SizedBox.shrink(),
      expanded: widget.selectionOptionsWidget,
      theme: getExpandableTheme(context),
      controller: expandableController,
    );
  }
}
