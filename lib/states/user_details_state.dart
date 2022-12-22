import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/opened_settings_event.dart';
import 'package:photos/models/user_details.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:photos/services/user_service.dart';

class UserDetailsStateWidget extends StatefulWidget {
  final Widget child;
  const UserDetailsStateWidget({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<UserDetailsStateWidget> createState() => UserDetailsStateWidgetState();
}

class UserDetailsStateWidgetState extends State<UserDetailsStateWidget> {
  late UserDetails? userDetails;
  late StreamSubscription<OpenedSettingsEvent> _openedSettingsEventSubscription;

  @override
  void initState() {
    userDetails = null;
    _openedSettingsEventSubscription =
        Bus.instance.on<OpenedSettingsEvent>().listen((event) {
      Future.delayed(
        const Duration(
          milliseconds: 750,
        ),
        _fetchUserDetails,
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    _openedSettingsEventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InheritedUserDetails(
        userDetailsState: this,
        userDetails: userDetails,
        child: widget.child,
      );

  void _fetchUserDetails() async {
    userDetails =
        await UserService.instance.getUserDetailsV2(memoryCount: true);
    if (mounted) {
      setState(() {});
    }
  }
}

class InheritedUserDetails extends InheritedWidget {
  final UserDetailsStateWidgetState userDetailsState;
  final UserDetails? userDetails;

  const InheritedUserDetails({
    Key? key,
    required Widget child,
    required this.userDetails,
    required this.userDetailsState,
  }) : super(key: key, child: child);

  static InheritedUserDetails? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedUserDetails>();

  @override
  bool updateShouldNotify(covariant InheritedUserDetails oldWidget) {
    return (userDetails?.usage != oldWidget.userDetails?.usage) ||
        (userDetails?.fileCount != oldWidget.userDetails?.fileCount);
  }
}
