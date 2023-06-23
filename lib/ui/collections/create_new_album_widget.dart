import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/tab_changed_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import 'package:photos/utils/toast_util.dart';

class CreateNewAlbumIcon extends StatelessWidget {
  const CreateNewAlbumIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButtonWidget(
      icon: Icons.add_rounded,
      iconButtonType: IconButtonType.primary,
      onTap: () async {
        await showToast(
          context,
          S.of(context).createAlbumActionHint,
          toastLength: Toast.LENGTH_LONG,
        );
        Bus.instance.fire(
          TabChangedEvent(
            0,
            TabChangedEventSource.collectionsPage,
          ),
        );
      },
    );
  }
}
