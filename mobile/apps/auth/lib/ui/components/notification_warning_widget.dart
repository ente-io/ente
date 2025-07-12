import "package:ente_auth/ente_theme_data.dart";
import 'package:ente_auth/theme/colors.dart';
import "package:ente_auth/theme/ente_theme.dart";
import 'package:ente_auth/theme/text_style.dart';
import 'package:ente_auth/ui/components/buttons/icon_button_widget.dart';
import 'package:flutter/material.dart';

// CreateNotificationType enum
enum NotificationType {
  warning,
  banner,
  notice,
}

class NotificationWidget extends StatelessWidget {
  final IconData startIcon;
  final IconData actionIcon;
  final String text;
  final String? subText;
  final GestureTapCallback onTap;
  final NotificationType type;

  const NotificationWidget({
    super.key,
    required this.startIcon,
    required this.actionIcon,
    required this.text,
    required this.onTap,
    this.subText,
    this.type = NotificationType.warning,
  });

  @override
  Widget build(BuildContext context) {
    EnteColorScheme colorScheme = getEnteColorScheme(context);
    EnteTextTheme textTheme = getEnteTextTheme(context);
    TextStyle mainTextStyle = darkTextTheme.bodyBold;
    TextStyle subTextStyle = darkTextTheme.miniMuted;
    LinearGradient? backgroundGradient;
    Color? backgroundColor;
    EnteColorScheme strokeColorScheme = darkScheme;
    List<BoxShadow>? boxShadow;
    switch (type) {
      case NotificationType.warning:
        backgroundColor = warning500;
        break;
      case NotificationType.banner:
        colorScheme = getEnteColorScheme(context);
        textTheme = getEnteTextTheme(context);
        backgroundColor = colorScheme.backgroundElevated2;
        mainTextStyle = textTheme.bodyBold;
        subTextStyle = textTheme.miniMuted;
        strokeColorScheme = colorScheme;
        boxShadow = [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 1),
        ];
        break;

      case NotificationType.notice:
        backgroundColor = colorScheme.backgroundElevated2;
        mainTextStyle = textTheme.bodyBold;
        subTextStyle = textTheme.miniMuted;
        strokeColorScheme = colorScheme;
        boxShadow = Theme.of(context).colorScheme.enteTheme.shadowMenu;
        break;
    }
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(8),
            ),
            boxShadow: boxShadow,
            color: backgroundColor,
            gradient: backgroundGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  startIcon,
                  size: 36,
                  color: strokeColorScheme.strokeBase,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: mainTextStyle,
                        textAlign: TextAlign.left,
                      ),
                      subText != null
                          ? Text(
                              subText!,
                              style: subTextStyle,
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButtonWidget(
                  icon: actionIcon,
                  iconButtonType: IconButtonType.rounded,
                  iconColor: strokeColorScheme.strokeBase,
                  defaultColor: strokeColorScheme.fillFaint,
                  pressedColor: strokeColorScheme.fillMuted,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
