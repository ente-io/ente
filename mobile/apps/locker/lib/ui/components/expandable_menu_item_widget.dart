import "package:ente_ui/theme/ente_theme.dart";
import "package:expandable/expandable.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/ui/drawer/common_settings.dart";

class ExpandableChildItem extends StatelessWidget {
  final String title;
  final Color? textColor;
  final IconData? trailingIcon;
  final Color? trailingIconColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpandableChildItem({
    required this.title,
    this.textColor,
    this.trailingIcon,
    this.trailingIconColor,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            const SizedBox(width: 60),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: textTheme.body.copyWith(
                  color: textColor,
                ),
              ),
            ),
            if (trailingIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(
                  trailingIcon,
                  color: trailingIconColor ?? colorScheme.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ExpandableMenuItemWidget extends StatefulWidget {
  final String title;
  final Widget selectionOptionsWidget;
  final dynamic leadingIcon;
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
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isExpanded = expandableController.expanded;

    return AnimatedContainer(
      curve: Curves.ease,
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: colorScheme.backdropBase,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpandableNotifier(
        controller: expandableController,
        child: ScrollOnExpand(
          child: ExpandablePanel(
            header: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => expandableController.toggle(),
              child: Row(
                children: [
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.fillFaint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: HugeIcon(
                          icon: widget.leadingIcon,
                          color: colorScheme.strokeBase,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: textTheme.body,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: AnimatedRotation(
                      turns: isExpanded ? -0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right,
                        color: colorScheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
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
