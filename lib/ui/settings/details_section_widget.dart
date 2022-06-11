import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/events/user_details_changed_event.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/utils/data_util.dart';

class DetailsSectionWidget extends StatefulWidget {
  DetailsSectionWidget({Key key}) : super(key: key);

  @override
  _DetailsSectionWidgetState createState() => _DetailsSectionWidgetState();
}

class _DetailsSectionWidgetState extends State<DetailsSectionWidget> {
  UserDetails _userDetails;
  StreamSubscription<UserDetailsChangedEvent> _userDetailsChangedEvent;
  StreamSubscription<TabChangedEvent> _tabChangedEventSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _userDetailsChangedEvent =
        Bus.instance.on<UserDetailsChangedEvent>().listen((event) {
      _fetchUserDetails();
    });
    _tabChangedEventSubscription =
        Bus.instance.on<TabChangedEvent>().listen((event) {
      if (event.selectedIndex == 3) {
        _fetchUserDetails();
      }
    });
  }

  void _fetchUserDetails() {
    UserService.instance.getUserDetailsV2(memoryCount: true).then((details) {
      if (mounted) {
        setState(() {
          _userDetails = details;
        });
      }
    });
  }

  @override
  void dispose() {
    _userDetailsChangedEvent.cancel();
    _tabChangedEventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return getSubscriptionPage();
            },
          ),
        );
      },
      child: SizedBox(
        height: 172,
        child: _userDetails == null ? loadWidget : getContainer(),
      ),
    );
  }

  Container getContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          topLeft: Radius.circular(2),
          bottomRight: Radius.circular(2),
        ),
        image: DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage("assets/card_background.png"),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 24, bottom: 24, left: 20, right: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Storage",
              style: Theme.of(context)
                  .textTheme
                  .subtitle1
                  .copyWith(color: Colors.white.withOpacity(0.7)),
            ),
            Padding(padding: EdgeInsets.symmetric(vertical: 3)),
            Text(
              "${convertBytesToReadableFormat(_userDetails.getFreeStorage())} of ${convertBytesToReadableFormat(_userDetails.getTotalStorage())} free",
              style: Theme.of(context)
                  .textTheme
                  .headline5
                  .copyWith(color: Colors.white),
            ),
            // Padding(padding: EdgeInsets.symmetric(vertical: 7)),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 24,
              ),
            ),
            // Padding(padding: EdgeInsets.symmetric(vertical: 8)),
            Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Stack(
                children: <Widget>[
                  Container(
                    color: Colors.white.withOpacity(0.2),
                    width: MediaQuery.of(context).size.width,
                    height: 4,
                  ),
                  Container(
                    color: Colors.white.withOpacity(0.75),
                    width: MediaQuery.of(context).size.width *
                        ((_userDetails.getFamilyOrPersonalUsage()) /
                            _userDetails.getTotalStorage()),
                    height: 4,
                  ),
                  Container(
                    color: Colors.white,
                    width: MediaQuery.of(context).size.width *
                        (_userDetails.usage / _userDetails.getTotalStorage()),
                    height: 4,
                  ),
                ],
              ),
            ),
            Padding(padding: EdgeInsets.symmetric(vertical: 6)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _userDetails.isPartOfFamily()
                    ? Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          Padding(padding: EdgeInsets.only(right: 4)),
                          Text(
                            "You",
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(color: Colors.white),
                          ),
                          Padding(padding: EdgeInsets.only(right: 12)),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                          Padding(padding: EdgeInsets.only(right: 4)),
                          Text(
                            "Family",
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        "${convertBytesToReadableFormat(_userDetails.getFamilyOrPersonalUsage())} used",
                        style: Theme.of(context).textTheme.headline5.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                      ),
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Text(
                    "${NumberFormat().format(_userDetails.fileCount)} Memories",
                    style: Theme.of(context)
                        .textTheme
                        .headline5
                        .copyWith(color: Colors.white, fontSize: 14),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
