import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:photos/ente_theme_data.dart';

enum LeadingIcon {
  chevronRight,
  check,
}

class MenuItemWidget extends StatelessWidget {
  final String text;
  final String? subText;
  final TextStyle? textStyle;
  final Color? leadingIconColor;
  final LeadingIcon? leadingIcon;
  final Widget? leadingSwitch;
  const MenuItemWidget({
    required this.text,
    this.subText,
    this.textStyle,
    this.leadingIconColor,
    this.leadingIcon,
    this.leadingSwitch,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enteTheme = Theme.of(context).colorScheme.enteTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.add_outlined,
                  size: 20,
                  color: leadingIconColor ?? enteTheme.colorScheme.strokeBase,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: textStyle ?? enteTheme.textTheme.bodyBold,
                ),
                subText != null
                    ? Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '\u2022',
                              style: enteTheme.textTheme.small.copyWith(
                                color: enteTheme.colorScheme.textMuted,
                              ),
                            ),
                          ),
                          Text(
                            subText!,
                            style: enteTheme.textTheme.small.copyWith(
                                color: enteTheme.colorScheme.textMuted),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          SizedBox(
            height: 24,
            child: leadingIcon == LeadingIcon.chevronRight
                ? Icon(Icons.chevron_right_rounded)
                : leadingIcon == LeadingIcon.check
                    ? Icon(Icons.check)
                    : leadingSwitch != null
                        ? leadingSwitch
                        : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }
}
