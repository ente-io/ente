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

enum AvatarType { xl, lg, md, sm, xs }

class UserAvatarWidget extends StatefulWidget {
  final User user;
  final AvatarType type;
  final int currentUserID;
  final bool thumbnailView;
  final bool addStroke;

  const UserAvatarWidget(
    this.user, {
    super.key,
    this.currentUserID = -1,
    this.type = AvatarType.md,
    this.thumbnailView = false,
    this.addStroke = true,
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
            padding:
                widget.addStroke ? const EdgeInsets.all(0.5) : EdgeInsets.zero,
            decoration: widget.addStroke
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.thumbnailView
                          ? strokeMutedDark
                          : getEnteColorScheme(context).strokeMuted,
                      width: UserAvatarWidget.strokeWidth,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  )
                : null,
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
                              addStroke: widget.addStroke,
                            ),
                    );
                  } else if (snapshot.hasError) {
                    _logger.severe("Error loading personID", snapshot.error);
                    return _FirstLetterCircularAvatar(
                      user: widget.user,
                      currentUserID: widget.currentUserID,
                      thumbnailView: widget.thumbnailView,
                      type: widget.type,
                      addStroke: widget.addStroke,
                    );
                  } else if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data == null) {
                    return _FirstLetterCircularAvatar(
                      user: widget.user,
                      currentUserID: widget.currentUserID,
                      thumbnailView: widget.thumbnailView,
                      type: widget.type,
                      addStroke: widget.addStroke,
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
            addStroke: widget.addStroke,
          );
  }
}

class _FirstLetterCircularAvatar extends StatefulWidget {
  final User user;
  final int currentUserID;
  final bool thumbnailView;
  final AvatarType type;
  final bool addStroke;
  const _FirstLetterCircularAvatar({
    required this.user,
    required this.currentUserID,
    required this.thumbnailView,
    required this.type,
    required this.addStroke,
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
      padding: widget.addStroke ? const EdgeInsets.all(0.5) : EdgeInsets.zero,
      decoration: widget.addStroke
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.thumbnailView
                    ? strokeMutedDark
                    : getEnteColorScheme(context).strokeMuted,
                width: UserAvatarWidget.strokeWidth,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            )
          : null,
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
      case AvatarType.xl:
        return Tuple2(32.0, enteTextTheme.small);
      case AvatarType.lg:
        return Tuple2(28.0, enteTextTheme.mini);
      case AvatarType.md:
        return Tuple2(24.0, enteTextTheme.mini);
      case AvatarType.sm:
        return Tuple2(18.0, enteTextTheme.tiny);
      case AvatarType.xs:
        return Tuple2(18.0, enteTextTheme.tiny);
    }
  }
}

double getAvatarSize(
  AvatarType type,
) {
  switch (type) {
    case AvatarType.xl:
      return 32.0;
    case AvatarType.lg:
      return 28.0;
    case AvatarType.md:
      return 24.0;
    case AvatarType.sm:
      return 18.0;
    case AvatarType.xs:
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
