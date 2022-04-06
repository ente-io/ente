import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/user_details_changed_event.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/settings/usage_details_widget.dart';

class DetailsSectionWidget extends StatefulWidget {
  DetailsSectionWidget({Key key}) : super(key: key);

  @override
  _DetailsSectionWidgetState createState() => _DetailsSectionWidgetState();
}

class _DetailsSectionWidgetState extends State<DetailsSectionWidget> {
  UserDetails _userDetails;
  StreamSubscription<UserDetailsChangedEvent> _userDetailsChangedEvent;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _userDetailsChangedEvent =
        Bus.instance.on<UserDetailsChangedEvent>().listen((event) {
      _fetchUserDetails();
    });
  }

  void _fetchUserDetails() {
    UserService.instance.getUserDetails().then((details) {
      setState(() {
        _userDetails = details;
      });
    });
  }

  @override
  void dispose() {
    _userDetailsChangedEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: _userDetails == null ? loadWidget : getContainer(),
    );
  }

  Widget getContainer() {
    return UsageDetailsWidget(_userDetails);
  }
}
