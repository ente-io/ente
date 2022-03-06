import 'package:flutter/material.dart';
import 'package:photos/utils/email_util.dart';

PopupMenuButton<dynamic> reportBugPopupMenu(BuildContext context) {
  return PopupMenuButton(
    itemBuilder: (context) {
      final List<PopupMenuItem> items = [];
      items.add(
        PopupMenuItem(
          value: 1,
          child: Row(
            children: const [
              Text("contact support"),
            ],
          ),
        ),
      );
      return items;
    },
    onSelected: (value) async {
      if (value == 1) {
        await sendLogs(context, "contact support", "support@ente.io",
            postShare: () {});
      }
    },
  );
}
