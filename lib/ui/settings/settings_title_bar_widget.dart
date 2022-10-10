import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/states/user_details_state.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';

class SettingsTitleBarWidget extends StatefulWidget {
  const SettingsTitleBarWidget({Key? key}) : super(key: key);

  @override
  State<SettingsTitleBarWidget> createState() => _SettingsTitleBarWidgetState();
}

class _SettingsTitleBarWidgetState extends State<SettingsTitleBarWidget> {
  @override
  Widget build(BuildContext context) {
    final logger = Logger((_SettingsTitleBarWidgetState).toString());
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              onPressed: () {},
              icon: const Icon(Icons.keyboard_double_arrow_left_outlined),
            ),
            FutureBuilder(
              future: InheritedUserDetails.of(context)?.userDetails,
              builder: (context, snapshot) {
                if (InheritedUserDetails.of(context) == null) {
                  logger.severe(
                    (InheritedUserDetails).toString() +
                        'not found before ' +
                        (_SettingsTitleBarWidgetState).toString() +
                        ' on tree',
                  );
                  return const SizedBox.shrink();
                }
                if (snapshot.hasData) {
                  final userDetails = snapshot.data as UserDetails;
                  return Text(
                    "${NumberFormat().format(userDetails.fileCount)} Memories",
                    style: getEnteTextTheme(context).largeBold,
                  );
                }
                if (snapshot.hasError) {
                  logger.severe('failed to load user details');
                  return const SizedBox.shrink();
                } else {
                  return const EnteLoadingWidget();
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
