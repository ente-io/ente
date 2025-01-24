import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/models/user_details.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/ui/components/banner_widget.dart';
import 'package:flutter/material.dart';

class NotificationBannerWidget extends StatelessWidget {
  const NotificationBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [];
    const sectionSpacing = SizedBox(height: 14);
    final currentTime = DateTime.now();
    final appInstallTime = PreferenceService.instance.getAppInstalledTime();
    final differenceInDays = currentTime
        .difference(DateTime.fromMillisecondsSinceEpoch(appInstallTime))
        .inMinutes;

    if (Configuration.instance.hasConfiguredAccount()) {
      return FutureBuilder<UserDetails>(
        future: UserService.instance.getUserDetailsV2(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userDetails = snapshot.data;

            if (differenceInDays >= 0 && differenceInDays <= 3) {
              return const SizedBox.shrink();
            } else if (differenceInDays >= 4 && differenceInDays <= 7) {
              contents.clear();
              contents.addAll(
                [
                  const BannerWidget(
                    text: "Tell us what you think",
                    subText: "Drop a review on the App/Play Store",
                    type: BannerType.rateUs,
                  ),
                  sectionSpacing,
                  const BannerWidget(
                    text: "Support <bold-green>ente<bold-green>",
                    subText: "Give us a star on Github",
                    type: BannerType.starUs,
                  ),
                ],
              );
              return buildWidget(context, contents);
            } else if (differenceInDays >= 7 && differenceInDays <= 30) {
              if (userDetails?.usage == 0) {
                contents.clear();
                contents.addAll(
                  [
                    const BannerWidget(
                      text: "5GB free on <bold-green>ente<bold-green> Photos",
                      subText: "Login with your Auth account",
                      type: BannerType.freeStorage,
                    ),
                  ],
                );
              } else if (userDetails!.usage < 5 * 1024 * 1024 * 1024 ||
                  userDetails.subscription.productID == 'free') {
                contents.addAll(
                  [
                    const BannerWidget(
                      text: "10% off on <bold-green>ente<bold-green> photos",
                      subText: "Use code “AUTH” to get 10% off first year",
                      type: BannerType.discount,
                    ),
                  ],
                );
              }
              return buildWidget(context, contents);
            }
          }
          return const SizedBox.shrink();
        },
      );
    } else {
      if (differenceInDays >= 4 && differenceInDays <= 7) {
        contents.clear();
        contents.addAll(
          [
            const BannerWidget(
              text: "Tell us what you think",
              subText: "Drop a review on the App/Play Store",
              type: BannerType.rateUs,
            ),
            sectionSpacing,
            const BannerWidget(
              text: "Support ente",
              subText: "Give us a star on Github",
              type: BannerType.starUs,
            ),
          ],
        );
      }
      return buildWidget(context, contents);
    }
  }

  Widget buildWidget(
    BuildContext context,
    List<Widget> contents,
  ) {
    return Column(
      children: contents,
    );
  }
}
