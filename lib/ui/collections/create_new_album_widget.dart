import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/tab_changed_event.dart';
import 'package:photos/utils/toast_util.dart';

class CreateNewAlbumWidget extends StatelessWidget {
  const CreateNewAlbumWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        margin: const EdgeInsets.fromLTRB(30, 30, 30, 54),
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 2,
              spreadRadius: 0,
              offset: const Offset(0, 0),
              color: Theme.of(context).iconTheme.color!.withOpacity(0.3),
            )
          ],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.add,
          color: Theme.of(context).iconTheme.color!.withOpacity(0.25),
        ),
      ),
      onTap: () async {
        await showToast(
          context,
          "Long press to select photos and click + to create an album",
          toastLength: Toast.LENGTH_LONG,
        );
        Bus.instance
            .fire(TabChangedEvent(0, TabChangedEventSource.collectionsPage));
      },
    );
  }
}
