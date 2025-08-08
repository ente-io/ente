import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/web_page.dart";
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/expandable_menu_item_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/settings/app_update_dialog.dart';
import 'package:photos/ui/settings/common_settings.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSectionWidget extends StatelessWidget {
  const AboutSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpandableMenuItemWidget(
      title: S.of(context).about,
      selectionOptionsWidget: _getSectionOptions(context),
      leadingIcon: Icons.info_outline,
    );
  }

  Widget _getSectionOptions(BuildContext context) {
    return Column(
      children: [
        sectionOptionSpacing,
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: S.of(context).weAreOpenSource,
          ),
          pressedColor: getEnteColorScheme(context).fillFaint,
          trailingIcon: Icons.chevron_right_outlined,
          trailingIconIsMuted: true,
          onTap: () async {
            // ignore: unawaited_futures
            launchUrl(Uri.parse("https://github.com/ente-io/ente"));
          },
        ),
        sectionOptionSpacing,
        AboutMenuItemWidget(
          title: S.of(context).privacy,
          url: "https://ente.io/privacy",
        ),
        sectionOptionSpacing,
        AboutMenuItemWidget(
          title: S.of(context).termsOfServicesTitle,
          url: "https://ente.io/terms",
        ),
        sectionOptionSpacing,
        updateService.isIndependent()
            ? Column(
                children: [
                  MenuItemWidget(
                    captionedTextWidget: CaptionedTextWidget(
                      title: S.of(context).checkForUpdates,
                    ),
                    pressedColor: getEnteColorScheme(context).fillFaint,
                    trailingIcon: Icons.chevron_right_outlined,
                    trailingIconIsMuted: true,
                    onTap: () async {
                      final dialog =
                          createProgressDialog(context, S.of(context).checking);
                      await dialog.show();
                      final shouldUpdate = await updateService.shouldUpdate();
                      await dialog.hide();
                      if (shouldUpdate) {
                        // ignore: unawaited_futures
                        showDialog(
                          useRootNavigator: false,
                          context: context,
                          builder: (BuildContext context) {
                            return AppUpdateDialog(
                              updateService.getLatestVersionInfo(),
                            );
                          },
                          barrierColor: Colors.black.withValues(alpha: 0.85),
                        );
                      } else {
                        showShortToast(
                          context,
                          S.of(context).youAreOnTheLatestVersion,
                        );
                      }
                    },
                  ),
                  sectionOptionSpacing,
                ],
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}

class AboutMenuItemWidget extends StatelessWidget {
  final String title;
  final String url;
  final String? webPageTitle;
  const AboutMenuItemWidget({
    required this.title,
    required this.url,
    this.webPageTitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MenuItemWidget(
      captionedTextWidget: CaptionedTextWidget(
        title: title,
      ),
      pressedColor: getEnteColorScheme(context).fillFaint,
      trailingIcon: Icons.chevron_right_outlined,
      trailingIconIsMuted: true,
      onTap: () async {
        // ignore: unawaited_futures
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return WebPage(webPageTitle ?? title, url);
            },
          ),
        );
      },
    );
  }
}
