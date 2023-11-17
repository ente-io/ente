import 'package:flutter/material.dart';
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/services/update_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/ui/components/notification_widget.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/notification/update/change_log_entry.dart';
import "package:photos/utils/black_friday_util.dart";
import "package:url_launcher/url_launcher_string.dart";

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
                    shouldShowBfBanner()
                        ? RepaintBoundary(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: NotificationWidget(
                                isBlackFriday: true,
                                startIcon: Icons.celebration,
                                actionIcon: Icons.arrow_forward_outlined,
                                text: S.of(context).blackFridaySale,
                                subText: S.of(context).upto50OffUntil4thDec,
                                type: NotificationType.goldenBanner,
                                onTap: () async {
                                  launchUrlString(
                                    "https://ente.io/blackfriday",
                                    mode: LaunchMode.platformDefault,
                                  );
                                },
                              ),
                            )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .shimmer(
                                  duration: 1000.ms,
                                  delay: 3200.ms,
                                  size: 0.6,
                                ),
                          )
                        : const SizedBox.shrink(),

                    ButtonWidget(
                      buttonType: ButtonType.trailingIconPrimary,
                      buttonSize: ButtonSize.large,
                      labelText: S.of(context).continueLabel,
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
                    // ButtonWidget(
                    //   buttonType: ButtonType.trailingIconSecondary,
                    //   buttonSize: ButtonSize.large,
                    //   labelText: S.of(context).rateTheApp,
                    //   icon: Icons.favorite_rounded,
                    //   iconColor: enteColorScheme.primary500,
                    //   onTap: () async {
                    //     await UpdateService.instance.launchReviewUrl();
                    //   },
                    // ),

                    shouldShowBfBanner()
                        ? const SizedBox.shrink()
                        : ButtonWidget(
                            buttonType: ButtonType.trailingIconSecondary,
                            buttonSize: ButtonSize.large,
                            labelText: "Join the ente community",
                            icon: Icons.people_alt_rounded,
                            iconColor: enteColorScheme.primary500,
                            onTap: () async {
                              launchUrlString(
                                "https://ente.io/community",
                                mode: LaunchMode.externalApplication,
                              );
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
        "Explore with the new Search Tab ✨",
        'Introducing a dedicated search tab with distinct sections for effortless discovery.\n'
            '\nYou can now discover items that come under different Locations, Moments, Contacts, Photo descriptions, Albums and File types with ease.\n',
      ),
    );
    items.add(
      ChangeLogEntry(
        "Black Friday Sale 🎉",
        "You can now purchase Ente's plans for 3 years at 30% off and 5 years at 50% off!\n"
            '\nThe storage you purchase will be stacked on top of your current plan.\n'
            '\nThis is the lowest our prices will ever be, so do consider upgrading!\n',
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
