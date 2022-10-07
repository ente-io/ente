// @dart=2.9

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/events/user_details_changed_event.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/utils/data_util.dart';

class DetailsSectionWidget extends StatefulWidget {
  const DetailsSectionWidget({Key key}) : super(key: key);

  @override
  State<DetailsSectionWidget> createState() => _DetailsSectionWidgetState();
}

class _DetailsSectionWidgetState extends State<DetailsSectionWidget> {
  UserDetails _userDetails;
  StreamSubscription<UserDetailsChangedEvent> _userDetailsChangedEvent;
  StreamSubscription<TabChangedEvent> _tabChangedEventSubscription;
  Image _background;

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
    _background = const Image(
      image: AssetImage("assets/storage_card_background.png"),
      fit: BoxFit.fill,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // precache background image to avoid flicker
    // https://stackoverflow.com/questions/51343735/flutter-image-preload
    precacheImage(_background.image, context);
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
      child: getContainer(),
    );
  }

  Widget getContainer() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 428, maxHeight: 175),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            color: Colors.transparent,
            child: AspectRatio(
              aspectRatio: 2 / 1,
              child: _background,
            ),
          ),
          _userDetails == null
              ? const EnteLoadingWidget()
              : Padding(
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 20,
                    left: 16,
                    right: 16,
                  ),
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Storage",
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2
                                    .copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                              ),
                              Text(
                                "${convertBytesToReadableFormat(_userDetails.getFreeStorage())} of ${convertBytesToReadableFormat(_userDetails.getTotalStorage())} free",
                                style: Theme.of(context)
                                    .textTheme
                                    .headline5
                                    .copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Stack(
                              children: <Widget>[
                                Container(
                                  color: Colors.white.withOpacity(0.2),
                                  width: MediaQuery.of(context).size.width,
                                  height: 4,
                                ),
                                Container(
                                  color: Colors.white.withOpacity(0.75),
                                  width: MediaQuery.of(context).size.width *
                                      ((_userDetails
                                              .getFamilyOrPersonalUsage()) /
                                          _userDetails.getTotalStorage()),
                                  height: 4,
                                ),
                                Container(
                                  color: Colors.white,
                                  width: MediaQuery.of(context).size.width *
                                      (_userDetails.usage /
                                          _userDetails.getTotalStorage()),
                                  height: 4,
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _userDetails.isPartOfFamily()
                                    ? Row(
                                        children: [
                                          Container(
                                            width: 8.71,
                                            height: 8.99,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.only(right: 4),
                                          ),
                                          Text(
                                            "You",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.only(right: 12),
                                          ),
                                          Container(
                                            width: 8.71,
                                            height: 8.99,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white
                                                  .withOpacity(0.75),
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.only(right: 4),
                                          ),
                                          Text(
                                            "Family",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        "${convertBytesToReadableFormat(_userDetails.getFamilyOrPersonalUsage())} used",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .copyWith(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                      ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 16.0),
                                  child: Text(
                                    "${NumberFormat().format(_userDetails.fileCount)} Memories",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
