// @dart=2.9

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/trash_db.dart';
import 'package:photos/events/trash_updated_event.dart';
import 'package:photos/ui/viewer/gallery/trash_page.dart';
import 'package:photos/utils/navigation_util.dart';

class TrashButtonWidget extends StatefulWidget {
  const TrashButtonWidget(
    this.textStyle, {
    Key key,
  }) : super(key: key);

  final TextStyle textStyle;

  @override
  State<TrashButtonWidget> createState() => _TrashButtonWidgetState();
}

class _TrashButtonWidgetState extends State<TrashButtonWidget> {
  StreamSubscription<TrashUpdatedEvent> _trashUpdatedEventSubscription;

  @override
  void initState() {
    super.initState();
    _trashUpdatedEventSubscription =
        Bus.instance.on<TrashUpdatedEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _trashUpdatedEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Theme.of(context).backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(0),
        side: BorderSide(
          width: 0.5,
          color: Theme.of(context).iconTheme.color.withOpacity(0.24),
        ),
      ),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const Padding(padding: EdgeInsets.all(6)),
                  FutureBuilder<int>(
                    future: TrashDB.instance.count(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data > 0) {
                        return RichText(
                          text: TextSpan(
                            style: widget.textStyle,
                            children: [
                              TextSpan(
                                text: "Trash",
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              const TextSpan(text: "  \u2022  "),
                              TextSpan(
                                text: snapshot.data.toString(),
                              ),
                              //need to query in db and bring this value
                            ],
                          ),
                        );
                      } else {
                        return RichText(
                          text: TextSpan(
                            style: widget.textStyle,
                            children: [
                              TextSpan(
                                text: "Trash",
                                style: Theme.of(context).textTheme.subtitle1,
                              ),
                              //need to query in db and bring this value
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).iconTheme.color,
              ),
            ],
          ),
        ),
      ),
      onPressed: () {
        routeToPage(
          context,
          TrashPage(),
        );
      },
    );
  }
}
