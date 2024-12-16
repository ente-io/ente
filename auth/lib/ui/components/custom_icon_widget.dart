import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/utils/icon_utils.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:flutter/material.dart';

class CustomIconWidget extends StatelessWidget {
  final String iconData;

  CustomIconWidget({
    super.key,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70, // Fixed width
      height: 70, // Fixed height
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.5,
          color: getEnteColorScheme(context).tagChipSelectedColor,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
      ),
      padding: const EdgeInsets.all(8),
      child: FittedBox(
        fit: BoxFit.contain, // Ensures the icon fits within the box
        child: IconUtils.instance.getIcon(
          context,
          safeDecode(iconData).trim(),
          width: 50,
        ),
      ),
    );
  }
}
