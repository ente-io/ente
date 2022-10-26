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
    final backgroundColor =
        MediaQuery.of(context).platformBrightness == Brightness.light
            ? enteColorScheme.backgroundElevated2
            : enteColorScheme.backgroundElevated;
    return AnimatedContainer(
      curve: Curves.ease,
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: expandableController.value ? backgroundColor : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ExpandableNotifier(
        controller: expandableController,
        child: ScrollOnExpand(
          child: ExpandablePanel(
            header: MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: widget.title,
                makeTextBold: true,
              ),
              isExpandable: true,
              leadingIcon: widget.leadingIcon,
              trailingIcon: Icons.expand_more,
              menuItemColor: enteColorScheme.fillFaint,
              expandableController: expandableController,
            ),
            collapsed: const SizedBox.shrink(),
            expanded: widget.selectionOptionsWidget,
            theme: getExpandableTheme(context),
            controller: expandableController,
          ),
        ),
      ),
    );
  }
}
