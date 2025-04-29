import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/ui/settings/inherited_settings_state.dart';

class ExpandableMenuItemWidget extends StatefulWidget {
  final String title;
  final Widget selectionOptionsWidget;
  final IconData leadingIcon;
  // Expand callback that takes bool as argument
  final void Function(bool)? onExpand;

  const ExpandableMenuItemWidget({
    required this.title,
    required this.selectionOptionsWidget,
    required this.leadingIcon,
    this.onExpand,
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
    expandableController.addListener(_expandableControllerListener);
    super.initState();
  }

  @override
  void dispose() {
    expandableController.removeListener(_expandableControllerListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAnySectionExpanded =
        InheritedSettingsState.maybeOf(context)?.isAnySectionExpanded ?? false;
    final isCurrentSectionExpanded = expandableController.expanded;
    final isSuppressed = isAnySectionExpanded && !isCurrentSectionExpanded;

    final enteColorScheme = Theme.of(context).colorScheme.enteTheme.colorScheme;
    final backgroundColor = Theme.of(context).brightness == Brightness.light
        ? enteColorScheme.backgroundElevated2
        : enteColorScheme.backgroundElevated;
    return Padding(
      padding: EdgeInsets.only(bottom: expandableController.value ? 8 : 0),
      child: AnimatedContainer(
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
                  textColor: isSuppressed
                      ? enteColorScheme.textMuted
                      : enteColorScheme.textBase,
                ),
                isExpandable: true,
                leadingIcon: widget.leadingIcon,
                leadingIconColor: isSuppressed
                    ? enteColorScheme.strokeMuted
                    : enteColorScheme.strokeBase,
                trailingIcon: Icons.expand_more,
                trailingIconColor: isSuppressed
                    ? enteColorScheme.strokeMuted
                    : enteColorScheme.strokeBase,
                menuItemColor: enteColorScheme.fillFaint,
                expandableController: expandableController,
              ),
              collapsed: const SizedBox.shrink(),
              expanded: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: widget.selectionOptionsWidget,
              ),
              theme: getExpandableTheme(),
              controller: expandableController,
            ),
          ),
        ),
      ),
    );
  }

  void _expandableControllerListener() {
    setState(() {
      if (expandableController.expanded) {
        InheritedSettingsState.maybeOf(context)?.increment();
      } else {
        InheritedSettingsState.maybeOf(context)?.decrement();
      }
    });
    if (widget.onExpand != null) {
      widget.onExpand!(expandableController.expanded);
    }
  }
}
