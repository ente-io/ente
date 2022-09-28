import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

enum LeadingIcon {
  chevronRight,
  check,
}

class MenuItemWidget extends StatelessWidget {
  final Widget leadingWidget;
  final LeadingIcon? trailingIcon;
  final Widget? trailingSwitch;
  final bool trailingIconIsMuted;
  final Function? onTap;
  const MenuItemWidget({
    required this.leadingWidget,
    this.trailingIcon,
    this.trailingSwitch,
    this.trailingIconIsMuted = false,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enteTheme = Theme.of(context).colorScheme.enteTheme;
    return GestureDetector(
      onTap: () {
        onTap;
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            leadingWidget,
            Container(
              child: trailingIcon == LeadingIcon.chevronRight
                  ? Icon(
                      Icons.chevron_right_rounded,
                      color: trailingIconIsMuted
                          ? enteTheme.colorScheme.strokeMuted
                          : null,
                    )
                  : trailingIcon == LeadingIcon.check
                      ? Icon(
                          Icons.check,
                          color: enteTheme.colorScheme.strokeMuted,
                        )
                      : trailingSwitch ?? const SizedBox.shrink(),
            )
          ],
        ),
      ),
    );
  }
}

class LeadingWidget extends StatelessWidget {
  final String text;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final String? subText;
  final TextStyle? textStyle;
  const LeadingWidget({
    required this.text,
    this.leadingIcon,
    this.leadingIconColor,
    this.subText,
    this.textStyle,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enteTheme = Theme.of(context).colorScheme.enteTheme;

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Icon(
                  leadingIcon ?? Icons.add_outlined,
                  color: leadingIconColor ?? enteTheme.colorScheme.strokeBase,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: RichText(
                text: TextSpan(
                  style: textStyle ?? enteTheme.textTheme.bodyBold,
                  children: [
                    TextSpan(
                      text: text,
                    ),
                    subText != null
                        ? TextSpan(
                            text: ' \u2022 ',
                            style: enteTheme.textTheme.small.copyWith(
                              color: enteTheme.colorScheme.textMuted,
                            ),
                          )
                        : const TextSpan(text: ''),
                    subText != null
                        ? TextSpan(
                            text: subText,
                            style: enteTheme.textTheme.small.copyWith(
                              color: enteTheme.colorScheme.textMuted,
                            ),
                          )
                        : const TextSpan(text: ''),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
