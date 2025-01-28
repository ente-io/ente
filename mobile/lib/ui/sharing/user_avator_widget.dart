import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/colors.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/viewer/search/result/person_face_widget.dart";
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
}

class _UserAvatarWidgetState extends State<UserAvatarWidget> {
  Future<String?>? _personID;
  EnteFile? _faceThumbnail;
  final _logger = Logger("_UserAvatarWidgetState");

  @override
  void initState() {
    super.initState();
    if (PersonService.instance.emailToNameMapCache[widget.user.email] != null) {
      _personID = PersonService.instance.getPersons().then((people) async {
        final person = people.firstWhereOrNull(
          (person) => person.data.email == widget.user.email,
        );
        if (person != null) {
          _faceThumbnail =
              await PersonService.instance.getRecentFileOfPerson(person);
        }
        return person?.remoteID;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = getAvatarSize(widget.type);

    return _personID != null
        ? Container(
            padding: const EdgeInsets.all(0.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.thumbnailView
                    ? strokeMutedDark
                    : getEnteColorScheme(context).strokeMuted,
                width: 1,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: SizedBox(
              height: size,
              width: size,
              child: FutureBuilder(
                future: _personID,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final personID = snapshot.data as String;
                    return ClipOval(
                      child: PersonFaceWidget(
                        _faceThumbnail!,
                        personId: personID,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    _logger.severe("Error loading personID", snapshot.error);
                    return _FirstLetterAvatar(
                      user: widget.user,
                      currentUserID: widget.currentUserID,
                      thumbnailView: widget.thumbnailView,
                      type: widget.type,
                    );
                  } else if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data == null) {
                    return _FirstLetterAvatar(
                      user: widget.user,
                      currentUserID: widget.currentUserID,
                      thumbnailView: widget.thumbnailView,
                      type: widget.type,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          )
        : _FirstLetterAvatar(
            user: widget.user,
            currentUserID: widget.currentUserID,
            thumbnailView: widget.thumbnailView,
            type: widget.type,
          );
  }

  double getAvatarSize(
    AvatarType type,
  ) {
    switch (type) {
      case AvatarType.small:
        return 36.0;
      case AvatarType.mini:
        return 24.0;
      case AvatarType.tiny:
        return 18.0;
      case AvatarType.extra:
        return 18.0;
    }
  }
}

class _FirstLetterAvatar extends StatefulWidget {
  final User user;
  final int currentUserID;
  final bool thumbnailView;
  final AvatarType type;
  const _FirstLetterAvatar({
    required this.user,
    required this.currentUserID,
    required this.thumbnailView,
    required this.type,
  });

  @override
  State<_FirstLetterAvatar> createState() => _FirstLetterAvatarState();
}

class _FirstLetterAvatarState extends State<_FirstLetterAvatar> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final displayChar =
        (widget.user.displayName == null || widget.user.displayName!.isEmpty)
            ? ((widget.user.email.isEmpty)
                ? " "
                : widget.user.email.substring(0, 1))
            : widget.user.displayName!.substring(0, 1);
    Color decorationColor;
    if (widget.user.id == null ||
        widget.user.id! <= 0 ||
        widget.user.id == widget.currentUserID) {
      decorationColor = Colors.black;
    } else {
      decorationColor = colorScheme.avatarColors[
          (widget.user.id!).remainder(colorScheme.avatarColors.length)];
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
          width: 1.0,
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
        return Tuple2(36.0, enteTextTheme.small);
      case AvatarType.mini:
        return Tuple2(24.0, enteTextTheme.mini);
      case AvatarType.tiny:
        return Tuple2(18.0, enteTextTheme.tiny);
      case AvatarType.extra:
        return Tuple2(18.0, enteTextTheme.tiny);
    }
  }
}
