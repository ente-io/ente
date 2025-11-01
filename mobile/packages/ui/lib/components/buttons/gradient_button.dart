import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  final HugeIcon? hugeIcon;
  final double paddingValue;

  const GradientButton({
    super.key,
    this.onTap,
    this.text = '',
    this.hugeIcon,
    this.paddingValue = 6.0,
  });

  static const TextStyle _textStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter-SemiBold',
    fontSize: 18,
  );

  @override
  Widget build(BuildContext context) {
    final Widget textWidget = Text(text, style: _textStyle);

    final Widget content = (hugeIcon != null)
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              hugeIcon!,
              Padding(padding: EdgeInsets.symmetric(horizontal: paddingValue)),
              if (text.isNotEmpty) textWidget,
            ],
          )
        : textWidget;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: getEnteColorScheme(context).primary700,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
