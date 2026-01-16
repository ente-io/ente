import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/backup_flow_helper.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/settings/backup/backup_settings_screen.dart";
import "package:photos/ui/settings/backup/backup_status_screen.dart";

class BackupSettingsPage extends StatelessWidget {
  const BackupSettingsPage({super.key});

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
                AppLocalizations.of(context).backup,
                style: textTheme.h3Bold,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).backedUpFolders,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedFolder01,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await handleFolderSelectionBackupFlow(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).backupStatus,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedCloudSavingDone01,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await routeToPage(
                            context,
                            const BackupStatusScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      MenuItemWidgetNew(
                        title: AppLocalizations.of(context).backupSettings,
                        leadingIconWidget: _buildIconWidget(
                          context,
                          HugeIcons.strokeRoundedSettings01,
                        ),
                        trailingIcon: Icons.chevron_right_outlined,
                        trailingIconIsMuted: true,
                        onTap: () async {
                          await routeToPage(
                            context,
                            const BackupSettingsScreen(),
                          );
                        },
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

  Widget _buildIconWidget(BuildContext context, List<List<dynamic>> icon) {
    final colorScheme = getEnteColorScheme(context);
    return HugeIcon(
      icon: icon,
      color: colorScheme.strokeBase,
      size: 20,
    );
  }
}
