import 'package:flutter/material.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';

class UserAvatarWidget extends StatelessWidget {
  final User user;
  final double size;
  final int currentUserID;

  const UserAvatarWidget(
    this.user,
    this.currentUserID, {
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final enteTextTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    final displayChar = (user.name == null || user.name!.isEmpty)
        ? user.email.substring(0, 1)
        : user.name!.substring(0, 1);
    final randomColor = colorScheme.avatarColors[
        (user.id ?? 0).remainder(colorScheme.avatarColors.length)];
    final Color decorationColor =
        ((user.id ?? -1) == currentUserID) ? Colors.black : randomColor;
    return Container(
      height: size,
      width: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: decorationColor,
        border: Border.all(
          color: colorScheme.strokeBase,
          width: 1.0,
        ),
      ),
      child: Text(
        displayChar.toUpperCase(),
        style: enteTextTheme.mini.copyWith(color: textBaseLight),
        textAlign: TextAlign.center,
      ),
    );
  }
}
