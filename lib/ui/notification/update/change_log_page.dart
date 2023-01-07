import 'package:flutter/material.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/notification/update/change_log_entry.dart';

class ChangeLogPage extends StatefulWidget {
  const ChangeLogPage({
    Key? key,
  }) : super(key: key);

  @override
  State<ChangeLogPage> createState() => _ChangeLogPageState();
}

class _ChangeLogPageState extends State<ChangeLogPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    return Scaffold(
      appBar: null,
      body: Container(
        color: enteColorScheme.backgroundElevated,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 36,
            ),
            Container(
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: TitleBarTitleWidget(
                  title: "What's new",
                ),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            Expanded(child: _getChangeLog()),
            const DividerWidget(
              dividerType: DividerType.solid,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16,
                  top: 16,
                  bottom: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconPrimary,
                      buttonSize: ButtonSize.large,
                      labelText: "Continue",
                      icon: Icons.arrow_forward_outlined,
                      onTap: () async {
                        await UpdateService.instance.hideChangeLog();
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ButtonWidget(
                      buttonType: ButtonType.trailingIconSecondary,
                      buttonSize: ButtonSize.large,
                      labelText: "Rate the app",
                      icon: Icons.favorite_rounded,
                      iconColor: enteColorScheme.primary500,
                      onTap: () async {
                        await UpdateService.instance.launchReviewUrl();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getChangeLog() {
    final scrollController = ScrollController();
    final List<ChangeLogEntry> items = [];
    items.add(
      ChangeLogEntry(
        "Quick links!",
        "Select some photos, choose \"Create link\" from the selection "
            "options, and, well, that's it! You'll get a link that you can "
            "share, end-to-end encrypted and secure.\n\nYour quick links will "
            "appear at the bottom of the share tab so that you can remove them "
            "when they're no longer needed, or convert them to regular albums "
            "by renaming them if you want them to stick around.\n\nDepending on the feedback, we\'ll iterate on this (automatically prune quick "
            "links, directly open the photo if only a single photo is shared, "
            "etc). So let us know which direction you wish us to head!",
      ),
    );
    items.add(
      ChangeLogEntry(
        '''Filename search''',
        "You can search for files by their names now.",
      ),
    );

    items.add(
      ChangeLogEntry(
        '''Prune empty albums''',
        "There is now a button on the albums tab to remove all empty albums in one go. This will help customers with many empty albums clear out their clutter, and will be visible if you have more than 3 empty albums.",
      ),
    );
    items.add(
      ChangeLogEntry(
        '''Clear caches''',
        "Under Settings > General > Advanced, you'll now see an option to "
            "view and manage how ente uses temporary storage on your device."
            "\n\nThe list will show a breakdown of cached files - Attaching a "
            "screenshot of this would help if you feel the ente is using more"
            " storage than expected.\n\nThere is also an option to clear all "
            "these temporarily cached files to free up space on your device.",
      ),
    );

    items.add(
      ChangeLogEntry(
        '''Reset ignored files''',
        "We've added help text to clarify when a file in an on-device album "
            "is ignored for backups because it was deleted from ente earlier,"
            " and an option to reset this state.\n\nWe've also fixed a bug "
            "where an on-device album would get unmarked from backups after using the free up space option within it.",
        isFeature: false,
      ),
    );

    return Container(
      padding: const EdgeInsets.only(left: 16),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        thickness: 2.0,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ChangeLogEntryWidget(entry: items[index]),
            );
          },
          itemCount: items.length,
        ),
      ),
    );
  }
}
