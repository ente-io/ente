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
            SafeArea(
              child: Container(
                alignment: Alignment.centerLeft,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: TitleBarTitleWidget(
                    title: "What's new",
                  ),
                ),
              ),
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
                          Navigator.of(context).pop();
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
        "Hide your photos!",
        "On popular demand, "
            "ente now supports photos that are hidden behind a lock.\n\nThis "
            "is in "
            "addition to the existing functionality to archive your photos so "
            "that they do not show in your timeline (but are otherwise visible)"
            ".",
      ),
    );
    items.add(
      ChangeLogEntry(
        '''Add a description to your photos''',
        "You can now add a caption / description to your photos and videos"
            ".These will show up on the photo view.\n\nTo add a description, tap on the info icon to view the photo details and enter your text.",
      ),
    );

    items.add(
      ChangeLogEntry(
        '''And search photos descriptions too''',
        "Yes, it doesn't end there! You can also search your photos using "
            "their descriptions.\n\nThis allows you to, for example, tag your"
            " photos and quickly search for them.",
      ),
    );
    if (Platform.isIOS) {
      items.add(
        ChangeLogEntry(
          '''Save live photos''',
          "There are some small fixes, including an enhancement to download and save live photos.",
          isFeature: false,
        ),
      );
    } else {
      items.add(
        ChangeLogEntry(
          '''Better import of WhatsApp photos''',
          "There are some small fixes, including an enhancement to use the creation time for photos imported from WhatsApp.",
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
          physics: const ClampingScrollPhysics(),
          itemCount: items.length,
          shrinkWrap: true,
        ),
      ),
    );
  }
}
