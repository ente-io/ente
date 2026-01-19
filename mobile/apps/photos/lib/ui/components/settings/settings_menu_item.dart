import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";

/// A settings menu item with a 40x40 icon container.
/// Used in the redesigned settings page.
class SettingsMenuItem extends StatelessWidget {
  final String title;
  final List<List<dynamic>> icon;
  final Color? iconColor;
  final FutureVoidCallback? onTap;
  final Widget? trailingWidget;
  final bool showChevron;
  final Color? titleColor;

  const SettingsMenuItem({
    required this.title,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.trailingWidget,
    this.showChevron = true,
    this.titleColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Icon container background: Light #F5F5F5, Dark #2C2C2C
    final iconContainerColor =
        isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);

    return MenuItemWidgetNew(
      title: title,
      leadingIconWidget: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconContainerColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: HugeIcon(
            icon: icon,
            color: iconColor ?? colorScheme.strokeBase,
            size: 20,
          ),
        ),
      ),
      leadingIconSize: 40,
      trailingWidget: trailingWidget,
      trailingIcon: showChevron && trailingWidget == null
          ? Icons.chevron_right_outlined
          : null,
      trailingIconIsMuted: true,
      onTap: onTap,
    );
  }
}
