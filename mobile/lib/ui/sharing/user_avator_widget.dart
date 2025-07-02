import "dart:async";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/extensions/user_extension.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/colors.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/viewer/people/person_face_widget.dart";
import "package:photos/utils/standalone/debouncer.dart";
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
  Future<String?>? _personID;
  bool _canUsePersonFaceWidget = false;
  int lastSyncTimeForKey = 0;
  final _logger = Logger("_UserAvatarWidgetState");
  late final StreamSubscription<PeopleChangedEvent> _peopleChangedSubscription;
  final _debouncer = Debouncer(
    const Duration(milliseconds: 250),
    executionInterval: const Duration(seconds: 20),
    leading: true,
  );

  @override
  void initState() {
    super.initState();
    _reload();
    _peopleChangedSubscription =
        Bus.instance.on<PeopleChangedEvent>().listen((event) {
      if (event.type == PeopleEventType.saveOrEditPerson ||
          event.type == PeopleEventType.syncDone) {
        _reload();
      }
    });
  }

  @override
  void dispose() {
    _peopleChangedSubscription.cancel();
    _debouncer.cancelDebounceTimer();
    super.dispose();
  }

  Future<void> _reload() async {
    _debouncer.run(() async {
      if (!mounted) return;
      setState(() {
        final data = PersonService
            .instance.emailToPartialPersonDataMapCache[widget.user.email];
        if (data != null && data.containsKey(PersonService.kPersonIDKey)) {
          _canUsePersonFaceWidget = true;
          _personID = Future.value(data[PersonService.kPersonIDKey]);
          lastSyncTimeForKey = PersonService.instance.lastRemoteSyncTime();
        } else {
          _canUsePersonFaceWidget = false;
          _personID = Future.value(null);
        }
      });
    });
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
                width: UserAvatarWidget.strokeWidth,
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
                      child: _canUsePersonFaceWidget
                          ? PersonFaceWidget(
                              key: ValueKey('$personID-$lastSyncTimeForKey'),
                              personId: personID,
                              onErrorCallback: () {
                                if (mounted) {
                                  setState(() {
                                    _personID = null;
                                    _canUsePersonFaceWidget = false;
                                  });
                                }
                              },
                            )
                          : _FirstLetterCircularAvatar(
                              user: widget.user,
                              currentUserID: widget.currentUserID,
                              thumbnailView: widget.thumbnailView,
                              type: widget.type,
                            ),
                    );
                  } else if (snapshot.hasError) {
                    _logger.severe("Error loading personID", snapshot.error);
                    return _FirstLetterCircularAvatar(
                      user: widget.user,
                      currentUserID: widget.currentUserID,
                      thumbnailView: widget.thumbnailView,
                      type: widget.type,
                    );
                  } else if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data == null) {
                    return _FirstLetterCircularAvatar(
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
        : _FirstLetterCircularAvatar(
            user: widget.user,
            currentUserID: widget.currentUserID,
            thumbnailView: widget.thumbnailView,
            type: widget.type,
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
        (widget.user.displayName == null || widget.user.displayName!.isEmpty)
            ? ((widget.user.email.isEmpty)
                ? " "
                : widget.user.email.substring(0, 1))
            : widget.user.displayName!.substring(0, 1);
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
    final displayChar = (user.displayName == null || user.displayName!.isEmpty)
        ? ((user.email.isEmpty) ? " " : user.email.substring(0, 1))
        : user.displayName!.substring(0, 1);
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
