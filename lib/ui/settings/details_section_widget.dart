import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/user_details_changed_event.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/toast_util.dart';

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
    UserService.instance.getUserDetailsV2(memberCount: true).then((details) {
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

  Container getContainer() {
    return Container(
      width: double.infinity,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        image: DecorationImage(
          image: AssetImage("assets/card_background.png"),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 36, horizontal: 20),
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
            Padding(padding: EdgeInsets.symmetric(vertical: 2)),
            Text(
              "${convertBytesToReadableFormat(_userDetails.getFreeStorage())} of ${convertBytesToReadableFormat(_userDetails.getTotalStorage())} free",
              style: Theme.of(context)
                  .textTheme
                  .headline5
                  .copyWith(color: Colors.white),
            ),
            Padding(padding: EdgeInsets.symmetric(vertical: 18)),
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
            Padding(padding: EdgeInsets.symmetric(vertical: 6)),
            GestureDetector(
              onTap: () {
                int totalStorage = _userDetails.isPartOfFamily()
                    ? _userDetails.familyData.storage
                    : _userDetails.subscription.storage;
                String usageText = formatBytes(_userDetails.getFreeStorage()) +
                    " / " +
                    convertBytesToReadableFormat(totalStorage) +
                    " free";
                if (_userDetails.isPartOfFamily()) {
                  usageText +=
                      "\npersonal usage: ${convertBytesToReadableFormat(_userDetails.getPersonalUsage())}\n"
                      "family usage: ${convertBytesToReadableFormat(_userDetails.getFamilyOrPersonalUsage() - _userDetails.getPersonalUsage())}";
                }
                showToast(usageText);
              },
              child: Row(
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
                          style: Theme.of(context)
                              .textTheme
                              .headline5
                              .copyWith(color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
                  Text(
                    "${_userDetails.fileCount.toString()} Memories",
                    style: Theme.of(context)
                        .textTheme
                        .headline5
                        .copyWith(color: Colors.white, fontSize: 14),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
