import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/theme/colors.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/theme/text_style.dart';
import 'package:photos/ui/components/buttons/icon_button_widget.dart';

// CreateNotificationType enum
enum NotificationType {
  warning,
  banner,
  goldenBanner,
}

class NotificationWidget extends StatelessWidget {
  final IconData startIcon;
  final IconData actionIcon;
  final String text;
  final String? subText;
  final GestureTapCallback onTap;
  final NotificationType type;

  const NotificationWidget({
    Key? key,
    required this.startIcon,
    required this.actionIcon,
    required this.text,
    required this.onTap,
    this.subText,
    this.type = NotificationType.warning,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    LinearGradient? backgroundGradient;
    Color? backgroundColor;
    switch (type) {
      case NotificationType.warning:
        backgroundColor = warning500;
        break;
      case NotificationType.banner:
        backgroundColor = backgroundElevated2Dark;
        break;
      case NotificationType.goldenBanner:
        backgroundGradient = LinearGradient(
          colors: [colorScheme.golden700, colorScheme.golden500],
          stops: const [0.25, 1],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
    }
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(8),
            ),
            boxShadow: Theme.of(context).colorScheme.enteTheme.shadowMenu,
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
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: darkTextTheme.bodyBold,
                      textAlign: TextAlign.left,
                    ),
                    subText != null
                        ? Text(
                            subText!,
                            style: darkTextTheme.mini
                                .copyWith(color: textMutedDark),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(width: 12),
                IconButtonWidget(
                  icon: actionIcon,
                  iconButtonType: IconButtonType.rounded,
                  iconColor: strokeBaseDark,
                  defaultColor: fillFaintDark,
                  pressedColor: fillMutedDark,
                  onTap: onTap,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
