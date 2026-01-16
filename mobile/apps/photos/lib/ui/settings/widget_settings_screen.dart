import "package:ente_pure_utils/ente_pure_utils.dart";
import 'package:flutter/material.dart';
import "package:flutter_svg/flutter_svg.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/settings/ml/enable_ml_consent.dart";
import "package:photos/ui/settings/widgets/albums_widget_settings.dart";
import "package:photos/ui/settings/widgets/memories_widget_settings.dart";
import "package:photos/ui/settings/widgets/people_widget_settings.dart";

class WidgetSettingsScreen extends StatelessWidget {
  const WidgetSettingsScreen({super.key});

  void onPeopleTapped(BuildContext context) {
    final bool isMLEnabled = !flagService.hasGrantedMLConsent;
    if (isMLEnabled) {
      routeToPage(
        context,
        const EnableMachineLearningConsent(),
        forceCustomPageRoute: true,
      );
      return;
    }
    routeToPage(
      context,
      const PeopleWidgetSettings(),
    );
  }

  void onAlbumsTapped(BuildContext context) {
    routeToPage(
      context,
      const AlbumsWidgetSettings(),
    );
  }

  void onMemoriesTapped(BuildContext context) {
    routeToPage(
      context,
      const MemoriesWidgetSettings(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final pageBackgroundColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFFAFAFA);

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.strokeBase,
                  size: 24,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).widgets,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).people,
                        leadingIconWidget: SvgPicture.asset(
                          "assets/icons/people-widget-icon.svg",
                          colorFilter: ColorFilter.mode(
                            colorScheme.strokeBase,
                            BlendMode.srcIn,
                          ),
                          width: 20,
                          height: 20,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async => onPeopleTapped(context),
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).albums,
                        leadingIconWidget: SvgPicture.asset(
                          "assets/icons/albums-widget-icon.svg",
                          colorFilter: ColorFilter.mode(
                            colorScheme.strokeBase,
                            BlendMode.srcIn,
                          ),
                          width: 20,
                          height: 20,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async => onAlbumsTapped(context),
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).memories,
                        leadingIconWidget: SvgPicture.asset(
                          "assets/icons/memories-widget-icon.svg",
                          colorFilter: ColorFilter.mode(
                            colorScheme.strokeBase,
                            BlendMode.srcIn,
                          ),
                          width: 20,
                          height: 20,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async => onMemoriesTapped(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
