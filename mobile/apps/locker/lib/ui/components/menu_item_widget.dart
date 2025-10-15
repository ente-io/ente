import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

class MenuItemWidget extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isFirst;
  final bool isLast;
  final bool isDelete;
  final bool isWarning;

  const MenuItemWidget({
    super.key,
    required this.icon,
    required this.label,
    this.isFirst = false,
    this.isLast = false,
    this.isDelete = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(15) : Radius.zero,
            topRight: isFirst ? const Radius.circular(15) : Radius.zero,
            bottomLeft: isLast ? const Radius.circular(15) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(15) : Radius.zero,
          ),
          child: InkWell(
            borderRadius: BorderRadius.only(
              topLeft: isFirst ? const Radius.circular(15) : Radius.zero,
              topRight: isFirst ? const Radius.circular(15) : Radius.zero,
              bottomLeft: isLast ? const Radius.circular(15) : Radius.zero,
              bottomRight: isLast ? const Radius.circular(15) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: (isDelete || isWarning)
                          ? textTheme.body
                              .copyWith(color: colorScheme.warning500)
                          : textTheme.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.strokeFaint,
          ),
      ],
    );
  }
}
