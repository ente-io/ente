import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/text_style.dart';
import 'package:photos/ui/components/icon_button_widget.dart';

class NotificationWarningWidget extends StatelessWidget {
  final IconData warningIcon;
  final IconData actionIcon;
  final String text;
  final GestureTapCallback onTap;

  const NotificationWarningWidget({
    Key? key,
    required this.warningIcon,
    required this.actionIcon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(8),
              ),
              boxShadow: Theme.of(context).colorScheme.enteTheme.shadowMenu,
              color: warning500,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    warningIcon,
                    size: 36,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      text,
                      style: darkTextTheme.bodyBold,
                      textAlign: TextAlign.left,
                    ),
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
      ),
    );
  }
}
