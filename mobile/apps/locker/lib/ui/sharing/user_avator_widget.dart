
import "package:ente_sharing/models/user.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import 'package:flutter/material.dart'; 
import "package:locker/services/configuration.dart";
import 'package:tuple/tuple.dart';

enum AvatarType { small, mini, tiny, extra }

class UserAvatarWidget extends StatefulWidget {
  final User user;
  final AvatarType type;
  final int currentUserID;
  final bool thumbnailView;

  const UserAvatarWidget(
    this.user, {
    super.key,
    this.currentUserID = -1,
    this.type = AvatarType.mini,
    this.thumbnailView = false,
  });

  @override
  State<UserAvatarWidget> createState() => _UserAvatarWidgetState();
  static const strokeWidth = 1.0;
}

class _UserAvatarWidgetState extends State<UserAvatarWidget> {
  @override
  Widget build(BuildContext context) {
    final double size = getAvatarSize(widget.type);
    return Container(
      padding: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.thumbnailView
              ? strokeMutedDark
              : getEnteColorScheme(context).strokeMuted,
          width: UserAvatarWidget.strokeWidth,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: SizedBox(
        height: size,
        width: size,
        child: _FirstLetterCircularAvatar(
          user: widget.user,
          currentUserID: widget.currentUserID,
          thumbnailView: widget.thumbnailView,
          type: widget.type,
        ),
      ),
    );
  }
}

class _FirstLetterCircularAvatar extends StatefulWidget {
  final User user;
  final int currentUserID;
  final bool thumbnailView;
  final AvatarType type;
  const _FirstLetterCircularAvatar({
    required this.user,
    required this.currentUserID,
    required this.thumbnailView,
    required this.type,
  });

  @override
  State<_FirstLetterCircularAvatar> createState() =>
      _FirstLetterCircularAvatarState();
}

class _FirstLetterCircularAvatarState
    extends State<_FirstLetterCircularAvatar> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final displayChar =
        (widget.user.name == null || widget.user.name!.isEmpty)
            ? ((widget.user.email.isEmpty)
                ? " "
                : widget.user.email.substring(0, 1))
            : widget.user.name!.substring(0, 1);
    Color decorationColor;
    if ((widget.user.id != null && widget.user.id! < 0) ||
        widget.user.email == Configuration.instance.getEmail()) {
      decorationColor = Colors.black;
    } else {
      decorationColor = colorScheme.avatarColors[(widget.user.email.length)
          .remainder(colorScheme.avatarColors.length)];
    }

    final avatarStyle = getAvatarStyle(context, widget.type);
    final double size = avatarStyle.item1;
    final TextStyle textStyle = avatarStyle.item2;
    return Container(
      padding: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.thumbnailView
              ? strokeMutedDark
              : getEnteColorScheme(context).strokeMuted,
          width: UserAvatarWidget.strokeWidth,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: SizedBox(
        height: size,
        width: size,
        child: CircleAvatar(
          backgroundColor: decorationColor,
          child: Text(
            displayChar.toUpperCase(),
            // fixed color
            style: textStyle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Tuple2<double, TextStyle> getAvatarStyle(
    BuildContext context,
    AvatarType type,
  ) {
    final enteTextTheme = getEnteTextTheme(context);
    switch (type) {
      case AvatarType.small:
        return Tuple2(32.0, enteTextTheme.small);
      case AvatarType.mini:
        return Tuple2(24.0, enteTextTheme.mini);
      case AvatarType.tiny:
        return Tuple2(18.0, enteTextTheme.tiny);
      case AvatarType.extra:
        return Tuple2(18.0, enteTextTheme.tiny);
    }
  }
}

double getAvatarSize(
  AvatarType type,
) {
  switch (type) {
    case AvatarType.small:
      return 32.0;
    case AvatarType.mini:
      return 24.0;
    case AvatarType.tiny:
      return 18.0;
    case AvatarType.extra:
      return 18.0;
  }
}

class FirstLetterUserAvatar extends StatefulWidget {
  final User user;
  const FirstLetterUserAvatar(this.user, {super.key});

  @override
  State<FirstLetterUserAvatar> createState() => _FirstLetterUserAvatarState();
}

class _FirstLetterUserAvatarState extends State<FirstLetterUserAvatar> {
  final currentUserEmail = Configuration.instance.getEmail();
  late User user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  void didUpdateWidget(covariant FirstLetterUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      setState(() {
        user = widget.user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final displayChar = (user.name == null || user.name!.isEmpty)
        ? ((user.email.isEmpty) ? " " : user.email.substring(0, 1))
        : user.name!.substring(0, 1);
    Color decorationColor;
    if ((widget.user.id != null && widget.user.id! < 0) ||
        user.email == currentUserEmail) {
      decorationColor = Colors.black;
    } else {
      decorationColor = colorScheme.avatarColors[
          (user.email.length).remainder(colorScheme.avatarColors.length)];
    }
    return Container(
      color: decorationColor,
      child: Center(
        child: Text(
          displayChar.toUpperCase(),
          style: getEnteTextTheme(context).small.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
