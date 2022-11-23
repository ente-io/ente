import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/common/web_page.dart';
import 'package:photos/ui/components/divider_widget.dart';
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
    final enteTextTheme = getEnteTextTheme(context);
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
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onTap: () async {
                          await UpdateService.instance.hideChangeLog();
                          if (mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        text: "Let's go",
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        top: 12,
                        right: 12,
                        bottom: 6,
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "If you like ente, ",
                            ),
                            TextSpan(
                              text: "let others know",
                              style: enteTextTheme.small.copyWith(
                                color: enteColorScheme.primary700,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Single tapped.
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) {
                                        return const WebPage(
                                          "Spread the word",
                                          "https://ente.io/share/",
                                        );
                                      },
                                    ),
                                  );
                                },
                            ),
                          ],
                          style: enteTextTheme.small,
                        ),
                      ),
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
        "Select all photos in a day",
        "After you select a photo, you'll now see an option next to the date to select all photos from that day.",
      ),
    );
    items.add(
      ChangeLogEntry(
        '''Easier access to favorites''',
        "Your favorites now have a special heart icon, and will appear first in the list of albums. Archived albums also get a new indicator.",
      ),
    );

    items.add(
      ChangeLogEntry(
        '''Export photo descriptions''',
        "When you export data out of ente using the desktop app, any photo captions and descriptions that you added will also be exported.",
      ),
    );
    items.add(
      ChangeLogEntry(
        '''Initial support for empty albums''',
        "Any empty albums that you already have will now show up in ente. You can choose to delete them, or add more photos to them. In the future we'll support more workflows with empty albums.",
        isFeature: false,
      ),
    );
    if (Platform.isIOS) {
      items.add(
        ChangeLogEntry(
          '''Tweak video uploads''',
          "ente will now keep videos temporarily cached until they get successfully uploaded. This will make video uploads work better as long as the app is not force killed.",
          isFeature: false,
        ),
      );
    } else {
      items.add(
        ChangeLogEntry(
          '''Better timestamps for screenshots''',
          "Added more cases when deducing photo dates from their file names. ente will also automatically apply these rules to fix photos that have already been imported without a valid date.",
          isFeature: false,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 16),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        thickness: 2.0,
        child: ListView.builder(
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
