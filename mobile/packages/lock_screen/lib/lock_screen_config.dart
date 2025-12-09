import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/theme_config.dart";
import "package:flutter/material.dart";

/// Configuration for lock screen UI
class LockScreenConfig {
  final Widget titleWidget;
  final Widget Function(BuildContext, TextEditingController?) iconBuilder;
  final double pinBoxHeight;
  final double pinBoxWidth;
  final EdgeInsets? pinBoxPadding;
  final double pinBoxBorderRadius;
  final Color? pinBoxBorderColor;
  final Color? pinBoxBackgroundColor;
  final bool useDynamicColors;

  const LockScreenConfig({
    required this.titleWidget,
    required this.iconBuilder,
    required this.pinBoxHeight,
    required this.pinBoxWidth,
    this.pinBoxPadding,
    required this.pinBoxBorderRadius,
    this.pinBoxBorderColor,
    this.pinBoxBackgroundColor,
    this.useDynamicColors = false,
  });

  /// Default configuration for Auth app
  static const LockScreenConfig auth = LockScreenConfig(
    titleWidget: SizedBox.shrink(),
    iconBuilder: _buildAuthIcon,
    pinBoxHeight: 48,
    pinBoxWidth: 48,
    pinBoxPadding: EdgeInsets.only(top: 6.0),
    pinBoxBorderRadius: 15.0,
    pinBoxBorderColor: Color.fromRGBO(45, 194, 98, 1.0),
    pinBoxBackgroundColor: null,
    useDynamicColors: false,
  );

  /// Configuration for Locker app
  static LockScreenConfig locker = LockScreenConfig(
    titleWidget: _buildLockerTitle(),
    iconBuilder: _buildLockerIcon,
    pinBoxHeight: 48,
    pinBoxWidth: 48,
    pinBoxPadding: const EdgeInsets.only(top: 6.0),
    pinBoxBorderRadius: 15.0,
    pinBoxBorderColor: null,
    pinBoxBackgroundColor: null,
    useDynamicColors: true,
  );

  /// Get current configuration based on AppThemeConfig
  static LockScreenConfig get current {
    switch (AppThemeConfig.currentApp) {
      case EnteApp.locker:
        return locker;
      case EnteApp.auth:
        return auth;
    }
  }

  /// Check if title should be shown (not a SizedBox.shrink)
  bool get showTitle => titleWidget is! SizedBox;

  /// Get border color based on config and theme
  Color getBorderColor(EnteColorScheme colorTheme) {
    if (useDynamicColors) {
      return colorTheme.fillMuted;
    }
    return pinBoxBorderColor ?? colorTheme.fillMuted;
  }

  /// Get background color based on config and theme
  Color? getBackgroundColor(EnteColorScheme colorTheme) {
    if (useDynamicColors) {
      return colorTheme.backgroundBase;
    }
    return pinBoxBackgroundColor;
  }

  // Helper methods for building title
  static Widget _buildLockerTitle() {
    return Image.asset(
      'assets/locker-logo-blue.png',
      height: 24,
    );
  }

  // Helper methods for building icons
  static Widget _buildAuthIcon(
    BuildContext context,
    TextEditingController? controller,
  ) {
    final colorTheme = getEnteColorScheme(context);
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade500.withValues(alpha: 0.2),
                  Colors.grey.shade50.withValues(alpha: 0.1),
                  Colors.grey.shade400.withValues(alpha: 0.2),
                  Colors.grey.shade300.withValues(alpha: 0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorTheme.backgroundBase,
                ),
              ),
            ),
          ),
          if (controller != null)
            SizedBox(
              height: 75,
              width: 75,
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, child) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: controller.text.length / 4,
                    ),
                    curve: Curves.ease,
                    duration: const Duration(milliseconds: 250),
                    builder: (context, value, _) => CircularProgressIndicator(
                      backgroundColor: colorTheme.fillFaintPressed,
                      value: value,
                      color: colorTheme.primary400,
                      strokeWidth: 1.5,
                    ),
                  );
                },
              ),
            ),
          Icon(
            Icons.lock,
            color: colorTheme.textBase,
            size: 30,
          ),
        ],
      ),
    );
  }

  static Widget _buildLockerIcon(
    BuildContext context,
    TextEditingController? controller,
  ) {
    return Image.asset(
      'packages/ente_lock_screen/assets/locker_pin.png',
      width: 129,
      height: 95,
    );
  }
}
