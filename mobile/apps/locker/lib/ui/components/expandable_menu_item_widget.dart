import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/theme/ente_theme_data.dart";
import "package:expandable/expandable.dart";
import 'package:flutter/material.dart';
import "package:locker/ui/drawer/common_settings.dart";

class ExpandableMenuItemWidget extends StatefulWidget {
  final String title;
  final Widget selectionOptionsWidget;
  final IconData leadingIcon;
  const ExpandableMenuItemWidget({
    required this.title,
    required this.selectionOptionsWidget,
    required this.leadingIcon,
    super.key,
  });

  @override
  State<ExpandableMenuItemWidget> createState() =>
      _ExpandableMenuItemWidgetState();
}

class _ExpandableMenuItemWidgetState extends State<ExpandableMenuItemWidget> {
  final expandableController = ExpandableController(initialExpanded: false);
  @override
  void initState() {
    expandableController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    expandableController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = Theme.of(context).colorScheme.enteTheme.colorScheme;

    return AnimatedContainer(
      curve: Curves.ease,
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: enteColorScheme.backdropBase,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpandableNotifier(
        controller: expandableController,
        child: ScrollOnExpand(
          child: ExpandablePanel(
            header: MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: widget.title,
              ),
              isExpandable: true,
              leadingIcon: widget.leadingIcon,
              menuItemColor: enteColorScheme.backdropBase,
              expandableController: expandableController,
              singleBorderRadius: 12,
            ),
            collapsed: const SizedBox.shrink(),
            expanded: widget.selectionOptionsWidget,
            theme: getExpandableTheme(),
            controller: expandableController,
          ),
        ),
      ),
    );
  }
}
